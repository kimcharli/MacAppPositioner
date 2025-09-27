
import Foundation

struct AppAction {
    let bundleID: String
    let appName: String
    let currentPosition: CGRect?
    let targetPosition: CGRect
    let action: ActionType
}

enum ActionType: String {
    case move = "MOVE"
    case keep = "KEEP"
}

struct ExecutionPlan {
    let profileName: String
    let monitors: [CocoaMonitorInfo]
    let actions: [AppAction]
}
