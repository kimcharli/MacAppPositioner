//
// Profile detection and plan generation, tested against fixtures.
//
// Everything here previously required the operator's physical displays and
// running applications. The ScreenProviding and WindowControlling seams let it
// run anywhere, which is what makes the hardware-dependent scripts retirable.
//
// Compiled by Scripts/test_all.sh against MacAppPositioner/Shared/*.swift.

import Foundation

// MARK: - Fixtures

/// A three-monitor arrangement in Cocoa coordinates, mirroring the shape of a
/// real setup: built-in laptop display at the origin (the menu bar screen),
/// one display to the left, one below.
private enum Screens {
    static let builtin = ScreenSnapshot(
        frame: CGRect(x: 0, y: 0, width: 2056, height: 1329),
        visibleFrame: CGRect(x: 0, y: 0, width: 2056, height: 1290),
        localizedName: "Built-in Liquid Retina XDR Display"
    )
    static let left = ScreenSnapshot(
        frame: CGRect(x: -2560, y: 0, width: 2560, height: 1440),
        visibleFrame: CGRect(x: -2560, y: 0, width: 2560, height: 1440),
        localizedName: "DELL U2718Q"
    )
    static let below = ScreenSnapshot(
        frame: CGRect(x: 0, y: -2160, width: 3840, height: 2160),
        visibleFrame: CGRect(x: 0, y: -2160, width: 3840, height: 2070),
        localizedName: "LG UltraFine"
    )

    static let all = [builtin, left, below]
}

/// In-memory config, so tests never touch the operator's config.json.
private final class StubConfigManager: ConfigManaging {
    var config: Config?
    private(set) var saved: [Config] = []

    init(json: String) {
        self.config = try? JSONDecoder().decode(Config.self, from: Data(json.utf8))
    }

    func loadConfig() -> Config? { config }

    @discardableResult
    func saveConfig(_ config: Config) -> Bool {
        saved.append(config)
        self.config = config
        return true
    }

    func invalidateCache() {}
}

private let configJSON = """
{
  "profiles": {
    "office": {
      "monitors": [
        { "resolution": "2560x1440", "position": "workspace" },
        { "resolution": "3840x2160", "position": "secondary" },
        { "resolution": "macbook", "position": "builtin" }
      ]
    },
    "laptop-only": {
      "monitors": [
        { "resolution": "builtin", "position": "workspace" }
      ]
    }
  },
  "layout": {
    "workspace": {
      "com.example.Corner": { "position": "top_right" },
      "com.example.Centred": { "position": "center" },
      "com.example.Pinned": { "position": "keep" },
      "com.example.Absent": { "position": "bottom_left" }
    },
    "builtin": {
      "com.example.Notes": { "position": "center" }
    }
  }
}
"""

private func makeManager(screens: [ScreenSnapshot] = Screens.all,
                         apps: [FixtureWindowController.FakeApp])
    -> (CocoaProfileManager, FixtureWindowController) {

    let windows = FixtureWindowController(apps: apps, frontmost: "com.example.Frontmost")
    let manager = CocoaProfileManager(
        configManager: StubConfigManager(json: configJSON),
        coordinateManager: CocoaCoordinateManager(screenProvider: FixtureScreenProvider(screens)),
        windowController: windows
    )
    return (manager, windows)
}

/// Workspace-section apps are parked on the built-in display and the
/// builtin-section app is parked on the workspace display, so every app starts
/// on the *wrong* screen. Nothing is accidentally already at its target, and a
/// `center` app cannot trip the `keepOnTargetScreen` short-circuit — which is
/// asserted separately in section [5].
private let defaultApps: [FixtureWindowController.FakeApp] = [
    .init(bundleID: "com.example.Corner",  name: "Corner",  pid: 101, frame: CGRect(x: 10, y: 10, width: 800, height: 600)),
    .init(bundleID: "com.example.Centred", name: "Centred", pid: 102, frame: CGRect(x: 20, y: 20, width: 900, height: 700)),
    .init(bundleID: "com.example.Pinned",  name: "Pinned",  pid: 103, frame: CGRect(x: 30, y: 30, width: 500, height: 400)),
    .init(bundleID: "com.example.Notes",   name: "Notes",   pid: 104, frame: CGRect(x: -2000, y: 100, width: 600, height: 500))
    // com.example.Absent is deliberately not running.
]

private func action(_ plan: ExecutionPlan?, _ bundleID: String) -> AppAction? {
    plan?.actions.first(where: { $0.bundleID == bundleID })
}

// MARK: - Tests

@main
struct ProfileLogicTests {
    static func main() {
        let t = TestRunner("Profile Logic")

        // ------------------------------------------------------------------
        t.section("[1] Cocoa → internal conversion for a multi-monitor layout")
        // Reference height is the menu bar screen (1329). A screen whose Cocoa
        // maxY equals that height converts to internal y == 0.
        let coords = CocoaCoordinateManager(screenProvider: FixtureScreenProvider(Screens.all))
        let monitors = coords.getAllMonitors()

        t.checkEqual(monitors.count, 3, "all three screens detected")
        t.checkEqual(monitors[0].frame, CGRect(x: 0, y: 0, width: 2056, height: 1329),
                     "built-in converts to the internal origin")
        t.checkEqual(monitors[1].frame, CGRect(x: -2560, y: -111, width: 2560, height: 1440),
                     "left screen keeps negative x and shifts by the height difference")
        t.checkEqual(monitors[2].frame, CGRect(x: 0, y: 1329, width: 3840, height: 2160),
                     "screen below the origin lands at positive internal y")
        t.check(monitors[0].isBuiltIn, "built-in identified by name")
        t.check(!monitors[1].isBuiltIn && !monitors[2].isBuiltIn, "externals not marked built-in")

        // ------------------------------------------------------------------
        t.section("[2] getBuiltinScreen tolerates an empty screen list")
        let noScreens = CocoaCoordinateManager(screenProvider: FixtureScreenProvider([]))
        t.check(noScreens.getBuiltinScreen() == nil, "returns nil rather than trapping")
        t.checkEqual(noScreens.getAllMonitors().count, 0, "no monitors reported")

        // ------------------------------------------------------------------
        t.section("[3] profile detection matches on the resolution set")
        let (manager, _) = makeManager(apps: defaultApps)
        t.checkEqual(manager.detectProfile(), "office", "three-monitor setup matches 'office'")

        // The 'macbook' alias must resolve to the built-in display's real
        // resolution — this guards the Phase 0 fix.
        let (laptopManager, _) = makeManager(screens: [Screens.builtin], apps: defaultApps)
        t.checkEqual(laptopManager.detectProfile(), "laptop-only",
                     "'builtin' alias resolves to the built-in display")

        // ------------------------------------------------------------------
        t.section("[4] plan targets the correct monitor per layout section")
        let plan = manager.generatePlan(for: "office")
        t.check(plan != nil, "plan generated")

        // Workspace monitor is the 2560x1440 screen: internal x -2560..0, y -111..1329.
        let corner = action(plan, "com.example.Corner")
        t.checkEqual(corner?.action, ActionType.move, "top_right app is a MOVE")
        t.checkEqual(corner?.targetPosition?.origin, CGPoint(x: -800, y: -111),
                     "top_right anchors to the workspace monitor's top-right")

        // Built-in section targets the built-in monitor, not the workspace one.
        // Notes starts on the workspace display, so a wrong monitor choice here
        // would surface as a target inside the workspace monitor's bounds.
        // Built-in visibleFrame converts to internal (0, 39, 2056, 1290);
        // centring a 600x500 window gives (1028 - 300, 684 - 250).
        let notes = action(plan, "com.example.Notes")
        t.checkEqual(notes?.action, ActionType.move, "builtin-section app is a MOVE")
        t.checkEqual(notes?.targetPosition?.origin, CGPoint(x: 728, y: 434),
                     "builtin-section app centres on the built-in display")
        t.check((notes?.targetPosition?.origin.x ?? -1) > 0,
                "builtin target is not on the workspace monitor (negative x)")

        // ------------------------------------------------------------------
        t.section("[5] plan reports non-moves honestly (the D1 regression)")
        let centred = action(plan, "com.example.Centred")
        t.checkEqual(centred?.action, ActionType.move, "center app is a MOVE")
        t.checkEqual(centred?.targetPosition?.origin, CGPoint(x: -1730, y: 259),
                     "center resolves to the workspace centre, not its corner")
        t.check(centred?.targetPosition?.origin != CGPoint(x: -2560, y: -111),
                "center is not the workspace monitor's top-left corner")

        let pinned = action(plan, "com.example.Pinned")
        t.checkEqual(pinned?.action, ActionType.keep, "keep app is KEEP")
        t.check(pinned?.targetPosition == nil, "keep app has no target")

        let absent = action(plan, "com.example.Absent")
        t.checkEqual(absent?.action, ActionType.unavailable, "non-running app is UNAVAILABLE")
        t.check(absent?.currentPosition == nil, "non-running app has no current position")

        // A `center` window whose centre already lies on the target monitor is
        // left alone, so re-applying a profile does not nudge a window the user
        // has arranged. Same Notes app, parked on the built-in this time.
        var settledApps = defaultApps
        settledApps[3].frame = CGRect(x: 40, y: 40, width: 600, height: 500)
        let (settledManager, _) = makeManager(apps: settledApps)
        let settledNotes = action(settledManager.generatePlan(for: "office"), "com.example.Notes")
        t.checkEqual(settledNotes?.action, ActionType.keep,
                     "centred app already on its target screen is KEEP")
        t.check(settledNotes?.targetPosition == nil,
                "a window left alone advertises no target")

        // ------------------------------------------------------------------
        t.section("[6] a process without an AX window is skipped, not chosen")
        // Models Chrome: a headless instance with a higher PID plus a real window.
        let (chromeManager, chromeWindows) = makeManager(apps: [
            .init(bundleID: "com.example.Corner", name: "Corner", pid: 900, frame: nil),
            .init(bundleID: "com.example.Corner", name: "Corner", pid: 100,
                  frame: CGRect(x: 10, y: 10, width: 800, height: 600))
        ])
        chromeManager.applyProfile("office")
        t.checkEqual(chromeWindows.moves.map(\.pid), [100],
                     "moved the PID with a window, not the higher headless PID")

        // ------------------------------------------------------------------
        t.section("[7] apply executes exactly what plan described")
        let (applyManager, applyWindows) = makeManager(apps: defaultApps)
        let previewed = applyManager.generatePlan(for: "office")
        applyManager.applyProfile("office")

        let expectedMoves = previewed?.actions
            .filter { $0.action == .move }
            .compactMap { $0.targetPosition?.origin } ?? []
        t.checkEqual(applyWindows.moves.map(\.position), expectedMoves,
                     "moves match the plan's targets, in order")
        t.check(!applyWindows.moves.isEmpty, "at least one window was moved")
        t.checkEqual(applyWindows.activations, ["com.example.Frontmost"],
                     "focus returned to the previously frontmost app")

        // Re-applying is a no-op: everything is now already placed.
        applyWindows.resetRecording()
        applyManager.applyProfile("office")
        t.check(applyWindows.moves.isEmpty, "re-applying moves nothing")

        t.finish()
    }
}
