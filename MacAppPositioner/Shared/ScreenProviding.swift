import Foundation
import AppKit

/**
 * Screen Access Seam
 *
 * `CocoaCoordinateManager` used to read `NSScreen.screens` directly, which made
 * every monitor-dependent behaviour (profile detection, workspace resolution,
 * coordinate conversion) testable only on the machine that happened to have the
 * right displays attached. That is why the original test scripts hardcoded the
 * author's 1329pt display.
 *
 * This protocol is the injection point: production uses `SystemScreenProvider`,
 * tests use `FixtureScreenProvider`.
 */

/// The subset of `NSScreen` that monitor detection actually consumes.
/// `frame` is in **Cocoa** coordinates (bottom-left origin) exactly as NSScreen
/// reports it; conversion to the internal top-left system happens downstream in
/// `CocoaMonitorInfo`.
struct ScreenSnapshot {
    let frame: CGRect
    let visibleFrame: CGRect
    let localizedName: String
    let backingScaleFactor: CGFloat

    init(frame: CGRect,
         visibleFrame: CGRect,
         localizedName: String,
         backingScaleFactor: CGFloat = 2.0) {
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.localizedName = localizedName
        self.backingScaleFactor = backingScaleFactor
    }

    init(_ screen: NSScreen) {
        self.frame = screen.frame
        self.visibleFrame = screen.visibleFrame
        self.localizedName = screen.localizedName
        self.backingScaleFactor = screen.backingScaleFactor
    }

    /// Resolution string in the `"WIDTHxHEIGHT"` form used throughout config matching.
    var resolution: String { "\(frame.width)x\(frame.height)" }
}

protocol ScreenProviding {
    /// All attached screens.
    ///
    /// Order matters: element 0 must be the menu bar screen (Cocoa origin 0,0),
    /// which is the reference height for Cocoa→internal conversion. This mirrors
    /// the documented `NSScreen.screens` contract. Do **not** substitute
    /// `NSScreen.main`, which differs between CLI and GUI processes.
    var screens: [ScreenSnapshot] { get }
}

/// Production provider, backed by AppKit.
struct SystemScreenProvider: ScreenProviding {
    var screens: [ScreenSnapshot] { NSScreen.screens.map(ScreenSnapshot.init) }
}

/// Test provider returning a fixed arrangement.
struct FixtureScreenProvider: ScreenProviding {
    let screens: [ScreenSnapshot]

    init(_ screens: [ScreenSnapshot]) {
        self.screens = screens
    }
}
