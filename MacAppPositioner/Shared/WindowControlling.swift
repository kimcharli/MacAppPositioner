import Foundation
import AppKit

/**
 * Window Access Seam
 *
 * `CocoaProfileManager` reached straight into `NSWorkspace` for process lookup
 * and into `CocoaCoordinateManager`'s Accessibility calls for window frames.
 * That made plan generation untestable: producing a plan required the target
 * applications to actually be running with real windows on real displays.
 *
 * This protocol is the injection point. Production uses
 * `SystemWindowController`; tests use `FixtureWindowController`, which serves
 * canned frames and *records* the moves it was asked to perform, so a test can
 * assert what an apply would do without moving anything.
 */
protocol WindowControlling: AnyObject {
    /// PIDs of running processes for a bundle ID, most recently launched first.
    func runningPIDs(bundleID: String) -> [pid_t]

    /// User-facing application name, or `nil` when not running.
    func localizedName(bundleID: String) -> String?

    /// Whether this process exposes a window the Accessibility API can move.
    /// Must not activate the application.
    func hasMovableWindow(pid: pid_t) -> Bool

    /// Current window frame in internal top-left coordinates.
    func windowFrame(pid: pid_t) -> CGRect?

    /// Move (and optionally resize) the process's best window.
    func setWindowPosition(pid: pid_t, position: CGPoint, size: CGSize?)

    /// Bundle ID of the frontmost application, captured before positioning so
    /// focus can be handed back afterwards.
    func frontmostBundleID() -> String?

    /// Return focus to an application.
    func activate(bundleID: String)
}

extension WindowControlling {
    /// First PID for this bundle ID that exposes a moveable window.
    ///
    /// Multiple processes can share a bundle ID — e.g. a visible Chrome
    /// alongside a headless debug instance. `hasMovableWindow` checks without
    /// activating, so skipped processes don't flicker.
    func addressablePID(bundleID: String) -> pid_t? {
        runningPIDs(bundleID: bundleID).first(where: { hasMovableWindow(pid: $0) })
    }

    /// Current frame of the addressable window for a bundle ID, or `nil` when the
    /// app isn't running or exposes no moveable window.
    func currentWindowFrame(bundleID: String) -> CGRect? {
        addressablePID(bundleID: bundleID).flatMap { windowFrame(pid: $0) }
    }
}

/// Production controller, backed by NSWorkspace and the Accessibility API.
final class SystemWindowController: WindowControlling {
    private let coordinateManager: CocoaCoordinateManager

    init(coordinateManager: CocoaCoordinateManager = .shared) {
        self.coordinateManager = coordinateManager
    }

    func runningPIDs(bundleID: String) -> [pid_t] {
        NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier == bundleID }
            .sorted { $0.processIdentifier > $1.processIdentifier } // higher PID = more recent
            .map { $0.processIdentifier }
    }

    func localizedName(bundleID: String) -> String? {
        NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == bundleID })?.localizedName
    }

    func hasMovableWindow(pid: pid_t) -> Bool {
        coordinateManager.hasMovableWindow(pid: pid)
    }

    func windowFrame(pid: pid_t) -> CGRect? {
        coordinateManager.getWindowRect(pid: pid)
    }

    func setWindowPosition(pid: pid_t, position: CGPoint, size: CGSize?) {
        coordinateManager.setWindowPosition(pid: pid, position: position, size: size)
    }

    func frontmostBundleID() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    func activate(bundleID: String) {
        guard let app = NSWorkspace.shared.runningApplications
                .first(where: { $0.bundleIdentifier == bundleID }) else { return }

        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
}

/// Test controller over a canned set of applications.
final class FixtureWindowController: WindowControlling {

    /// One simulated running application.
    struct FakeApp {
        let bundleID: String
        let name: String
        let pid: pid_t
        /// `nil` models a process with no AX-addressable window (e.g. headless Chrome).
        var frame: CGRect?

        init(bundleID: String, name: String, pid: pid_t, frame: CGRect?) {
            self.bundleID = bundleID
            self.name = name
            self.pid = pid
            self.frame = frame
        }
    }

    /// A move the controller was asked to perform.
    struct RecordedMove: Equatable {
        let pid: pid_t
        let position: CGPoint
        let size: CGSize?
    }

    private(set) var apps: [FakeApp]
    private(set) var moves: [RecordedMove] = []
    private(set) var activations: [String] = []

    /// What `frontmostBundleID()` reports.
    var frontmost: String?

    init(apps: [FakeApp], frontmost: String? = nil) {
        self.apps = apps
        self.frontmost = frontmost
    }

    func runningPIDs(bundleID: String) -> [pid_t] {
        apps.filter { $0.bundleID == bundleID }
            .sorted { $0.pid > $1.pid }
            .map { $0.pid }
    }

    func localizedName(bundleID: String) -> String? {
        apps.first(where: { $0.bundleID == bundleID })?.name
    }

    func hasMovableWindow(pid: pid_t) -> Bool {
        apps.first(where: { $0.pid == pid })?.frame != nil
    }

    func windowFrame(pid: pid_t) -> CGRect? {
        apps.first(where: { $0.pid == pid })?.frame
    }

    func setWindowPosition(pid: pid_t, position: CGPoint, size: CGSize?) {
        moves.append(RecordedMove(pid: pid, position: position, size: size))
        if let index = apps.firstIndex(where: { $0.pid == pid }), let existing = apps[index].frame {
            apps[index].frame = CGRect(origin: position, size: size ?? existing.size)
        }
    }

    func frontmostBundleID() -> String? { frontmost }

    func activate(bundleID: String) { activations.append(bundleID) }
}
