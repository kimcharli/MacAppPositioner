
import Foundation

/// One application's entry in an execution plan.
///
/// `targetPosition` is optional: `nil` means there is nothing to move to
/// (a configured `keep`, or a window already on its target screen).
struct AppAction {
    let bundleID: String
    let appName: String
    let currentPosition: CGRect?
    let targetPosition: CGRect?
    let action: ActionType
    /// Human-readable rationale, supplied by `LayoutEngine.Decision`.
    let reason: String
}

enum ActionType: String {
    case move = "MOVE"
    case keep = "KEEP"
    case unavailable = "UNAVAILABLE"
}

struct ExecutionPlan {
    let profileName: String
    let monitors: [CocoaMonitorInfo]
    let actions: [AppAction]
}
