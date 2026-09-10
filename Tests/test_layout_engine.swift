//
// LayoutEngine regression tests.
//
// Compiled by Scripts/test_all.sh against the real Shared/LayoutEngine.swift
// (plus the types it references) rather than re-implementing the logic, so
// these assertions exercise shipping code.
//
// Locks in the D1 fix: `center` and `keep` must NOT resolve to the top-left
// corner. The previous calculateQuadrantPosition folded them into the
// `.topLeft` branch, so `plan` advertised a top-left move while `apply`
// centred the window.

import Foundation

// A 2000x1000 monitor at the internal origin, with a 40pt menu bar.
private let monitor = MonitorGeometry(
    frame: CGRect(x: 0, y: 0, width: 2000, height: 1000),
    visibleFrame: CGRect(x: 0, y: 40, width: 2000, height: 960)
)

private let windowSize = CGSize(width: 400, height: 200)

// Park the window well away from the monitor so nothing trips the
// "already placed" or "already on target screen" short-circuits.
private let elsewhere = CGRect(origin: CGPoint(x: 9000, y: 9000), size: windowSize)

private func resolve(_ position: WindowPosition, current: CGRect? = elsewhere) -> LayoutEngine.Placement {
    LayoutEngine.resolve(position: position,
                         sizing: "keep",
                         appSizingOverride: nil,
                         currentFrame: current,
                         monitor: monitor)
}

// Compiled alongside the Shared sources, so this cannot be a `main.swift`-style
// script: statements live inside `main()` and only declarations sit at file scope.
@main
struct LayoutEngineTests {
    static func main() {
        let t = TestRunner("LayoutEngine")

        t.section("[1] center resolves to the centre, not the top-left corner")
        let centre = resolve(.center)
        let expectedCentre = CGPoint(x: 1000 - 200, y: 520 - 100) // visibleFrame mid minus half the window
        t.check(centre.targetFrame?.origin == expectedCentre,
                "center origin is \(expectedCentre)",
                "got \(String(describing: centre.targetFrame?.origin))")
        t.check(centre.targetFrame?.origin != CGPoint(x: 0, y: 40),
                "center is not the visibleFrame origin (the historical bug)")
        t.check(centre.decision == .move, "center is a MOVE")

        t.section("[2] keep yields no target at all")
        let kept = resolve(.keep)
        t.check(kept.targetFrame == nil, "keep target is nil",
                "got \(String(describing: kept.targetFrame))")
        t.check(kept.decision == .keepConfigured, "keep decision is keepConfigured")
        t.check(kept.decision.actionType == .keep, "keep reports KEEP")

        t.section("[3] quadrants anchor to the visible frame corners")
        t.check(resolve(.topLeft).targetFrame?.origin == CGPoint(x: 0, y: 40), "top_left")
        t.check(resolve(.topRight).targetFrame?.origin == CGPoint(x: 1600, y: 40), "top_right")
        t.check(resolve(.bottomLeft).targetFrame?.origin == CGPoint(x: 0, y: 800), "bottom_left")
        t.check(resolve(.bottomRight).targetFrame?.origin == CGPoint(x: 1600, y: 800), "bottom_right")

        t.section("[4] a window already at its target is KEEP, not MOVE")
        let already = LayoutEngine.resolve(position: .topLeft,
                                           sizing: "keep",
                                           appSizingOverride: nil,
                                           currentFrame: CGRect(x: 0, y: 40, width: 400, height: 200),
                                           monitor: monitor)
        t.check(already.decision == .keepAlreadyPlaced, "already-placed window is KEEP")
        t.check(already.shouldMove == false, "already-placed window is not moved")

        t.section("[5] a centred window already on the monitor is left alone")
        let onScreen = LayoutEngine.resolve(position: .center,
                                            sizing: "keep",
                                            appSizingOverride: nil,
                                            currentFrame: CGRect(x: 100, y: 100, width: 400, height: 200),
                                            monitor: monitor)
        t.check(onScreen.decision == .keepOnTargetScreen, "centred window on target screen is KEEP")
        t.check(onScreen.targetFrame == nil, "and reports no target")

        t.section("[6] a non-running app is UNAVAILABLE, not MOVE")
        let missing = resolve(.topLeft, current: nil)
        t.check(missing.decision == .appUnavailable, "no current frame means UNAVAILABLE")
        t.check(missing.decision.actionType == .unavailable, "reports UNAVAILABLE")
        t.check(missing.targetFrame?.size == AppConstants.defaultWindowSize,
                "still reports a would-be target at the default size")

        t.section("[7] sizing controls the resolved window size")
        t.check(LayoutEngine.resolveWindowSize(currentSize: windowSize, sizing: "keep", appSizingOverride: nil) == windowSize,
                "sizing 'keep' preserves the current size")
        t.check(LayoutEngine.resolveWindowSize(currentSize: windowSize, sizing: nil, appSizingOverride: "keep") == windowSize,
                "application override 'keep' preserves the current size")
        t.check(LayoutEngine.resolveWindowSize(currentSize: windowSize, sizing: nil, appSizingOverride: nil) == AppConstants.defaultWindowSize,
                "no sizing hint falls back to the default size")

        t.finish()
    }
}
