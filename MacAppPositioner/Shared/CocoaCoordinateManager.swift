import Foundation
import AppKit

/**
 * Coordinate System Manager
 * 
 * ARCHITECTURE PRINCIPLE: 
 * - Uses a consistent internal coordinate system (top-left origin, Y-down).
 * - Converts from Cocoa coordinates at the API boundary.
 * - All internal calculations are performed in this consistent system.
 */

struct CocoaMonitorInfo {
    let frame: CGRect           // Internal (top-left origin)
    let visibleFrame: CGRect    // Internal (top-left origin)
    let resolution: String
    let scale: CGFloat
    let isBuiltIn: Bool
    let isWorkspace: Bool
    
    init(from screen: ScreenSnapshot, isWorkspace: Bool = false, mainScreenHeight: CGFloat) {
        self.frame = CocoaCoordinateManager.convertCocoaToInternal(cocoaRect: screen.frame, mainScreenHeight: mainScreenHeight)
        self.visibleFrame = CocoaCoordinateManager.convertCocoaToInternal(cocoaRect: screen.visibleFrame, mainScreenHeight: mainScreenHeight)
        self.resolution = screen.resolution
        self.scale = screen.backingScaleFactor
        self.isBuiltIn = CocoaCoordinateManager.isBuiltInScreen(screen)
        self.isWorkspace = isWorkspace
    }
}

class CocoaCoordinateManager {
    static let shared = CocoaCoordinateManager()

    private let screenProvider: ScreenProviding

    /// Injectable for tests; production callers use `shared`, which reads AppKit.
    init(screenProvider: ScreenProviding = SystemScreenProvider()) {
        self.screenProvider = screenProvider
    }
    
    // MARK: - Coordinate Conversion
    
    /// Converts a Cocoa rect (bottom-left origin, Y up) to the internal top-left
    /// system (Y down) that matches the Accessibility API.
    ///
    /// `mainScreenHeight` must be the height of the menu bar screen. Static because
    /// it depends on nothing but its arguments.
    static func convertCocoaToInternal(cocoaRect: CGRect, mainScreenHeight: CGFloat) -> CGRect {
        let internalY = mainScreenHeight - cocoaRect.maxY
        return CGRect(x: cocoaRect.origin.x, y: internalY, width: cocoaRect.width, height: cocoaRect.height)
    }

    func convertCocoaToInternal(cocoaRect: CGRect, mainScreenHeight: CGFloat) -> CGRect {
        Self.convertCocoaToInternal(cocoaRect: cocoaRect, mainScreenHeight: mainScreenHeight)
    }

    // MARK: - Monitor Detection
    
    func getAllMonitors(for profileName: String? = nil) -> [CocoaMonitorInfo] {
        let config = ConfigManager.shared.loadConfig()
        let screens = screenProvider.screens
        // screens.first is always the menu bar screen (Cocoa origin 0,0).
        // Do NOT use NSScreen.main here — it returns different screens in CLI vs GUI contexts.
        let mainScreenHeight = screens.first?.frame.height ?? 0
        
        var workspaceMonitorResolution: String?
        if let profileName = profileName, let profile = config?.profiles[profileName] {
            workspaceMonitorResolution = profile.monitors.first(where: { $0.position == .workspace })?.resolution
        }
        
        return screens.map { screen in
            let isWorkspace = workspaceMonitorResolution.map { configured in
                Self.isBuiltInAlias(configured)
                    ? Self.isBuiltInScreen(screen)
                    : AppUtils.normalizeResolution(screen.resolution) == AppUtils.normalizeResolution(configured)
            } ?? false
            return CocoaMonitorInfo(from: screen, isWorkspace: isWorkspace, mainScreenHeight: mainScreenHeight)
        }
    }
    
    /// Resolves a configured workspace resolution to a detected monitor.
    /// Honours the built-in aliases (`"builtin"` / `"macbook"`) that `detectProfile()`
    /// accepts, so a profile naming the built-in display as its workspace monitor can
    /// actually be applied and not merely detected.
    func findWorkspaceMonitor(resolution: String, from monitors: [CocoaMonitorInfo]? = nil) -> CocoaMonitorInfo? {
        let candidates = monitors ?? getAllMonitors()

        if Self.isBuiltInAlias(resolution) {
            return candidates.first { $0.isBuiltIn }
        }

        return candidates.first { monitor in
            AppUtils.normalizeResolution(monitor.resolution) == AppUtils.normalizeResolution(resolution)
        }
    }
    
    // MARK: - Window Positioning
    
    /**
     * Retrieves the current frame (position and size) of an application's main window.
     *
     * This method uses the Accessibility API to query window attributes from a running application.
     * The position returned is in the system's default coordinate system (top-left origin).
     *
     * @param pid: Process ID of the target application
     * @return: Tuple containing (position: CGPoint, size: CGSize) if successful, nil if failed
     */
    func getWindowFrame(pid: pid_t) -> (position: CGPoint, size: CGSize)? {
        let app = AXUIElementCreateApplication(pid)
        
        guard let window = getBestWindow(app: app) else {
            return nil
        }
        
        var positionRef: AnyObject?
        var sizeRef: AnyObject?
        
        let positionResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)

        if positionResult == .success && sizeResult == .success,
           let positionRef = positionRef, let sizeRef = sizeRef {
            
            var position = CGPoint.zero
            var size = CGSize.zero
            
            let positionSuccess = AXValueGetValue(positionRef as! AXValue, AXValueType.cgPoint, &position)
            let sizeSuccess = AXValueGetValue(sizeRef as! AXValue, AXValueType.cgSize, &size)
            
            if positionSuccess && sizeSuccess {
                return (position, size)
            }
        }
        
        return nil
    }
    
    func getWindowRect(pid: pid_t) -> CGRect? {
        guard let frame = getWindowFrame(pid: pid) else { return nil }
        return CGRect(origin: frame.position, size: frame.size)
    }

    /// Returns true if the process has a moveable window accessible via the AX API,
    /// without activating the app. Used to distinguish visible instances from
    /// headless/debug processes that share the same bundle ID.
    func hasMovableWindow(pid: pid_t) -> Bool {
        let app = AXUIElementCreateApplication(pid)
        return getBestWindow(app: app) != nil
    }

    func setWindowPosition(pid: pid_t, position: CGPoint, size: CGSize? = nil) {
        let app = AXUIElementCreateApplication(pid)
        
        // Attempt to activate the application to bring it to the front and give it focus.
        // On macOS 14+ activate() always forces activation (the old option has no effect).
        // On older versions we need .activateIgnoringOtherApps to force-switch from our GUI.
        if let runningApp = NSRunningApplication(processIdentifier: pid) {
            if #available(macOS 14.0, *) {
                runningApp.activate()
            } else {
                runningApp.activate(options: [.activateIgnoringOtherApps])
            }
        }
        
        // Some apps (e.g. Chrome) need time after activation before AX windows are accessible.
        // Use RunLoop.run(until:) instead of Thread.sleep so the main thread's run loop
        // keeps processing events (including the activation event) during the wait.
        var window: AXUIElement?
        for attempt in 0..<5 {
            window = getBestWindow(app: app)
            if window != nil { break }
            let delay = 0.1 * Double(attempt + 1)  // 0.1, 0.2, 0.3, 0.4s
            RunLoop.current.run(until: Date(timeIntervalSinceNow: delay))
        }
        
        guard let window = window else {
            print("❌ Failed to find a suitable window for PID \(pid).")
            return
        }
        
        var mutablePosition = position
        var positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &mutablePosition)!)
        
        // If initial positioning fails or is not successful, try again after a short delay
        if positionResult != .success {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &mutablePosition)!)
        }
        if let size = size {
            var mutableSize = size
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &mutableSize)!)
        }
        
        print("  🎯 Position result: \(accessibilityErrorDescription(positionResult))")
        print("  📍 Final position: \(position)")
        
        // Verify the position after setting it
        if let actualRect = getWindowRect(pid: pid) {
            let tolerance: CGFloat = 1.0 // Allow for minor discrepancies
            if abs(actualRect.origin.x - position.x) > tolerance || abs(actualRect.origin.y - position.y) > tolerance {
                print("❌ Window did not move to the exact calculated position. Actual: \(actualRect.origin)")
            } else {
                print("✅ Window moved to the calculated position.")
            }
        } else {
            print("⚠️ Could not retrieve actual window position after setting.")
        }
    }

    /**
     * Identifies the best window to move for an application.
     * Prioritizes the Main Window, then falls back to the first standard window found.
     */
    private func getBestWindow(app: AXUIElement) -> AXUIElement? {
        // 1. Try to get the Main Window attribute directly
        var mainWindow: CFTypeRef?
        if AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &mainWindow) == .success {
            return (mainWindow as! AXUIElement)
        }
        
        // 2. Fallback: Query all windows and filter for standard windows
        var windows: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows) == .success,
              let windowArray = windows as? [AXUIElement] else {
            return nil
        }
        
        // Filter for standard windows that have a title
        for window in windowArray {
            var role: CFTypeRef?
            var subrole: CFTypeRef?
            var title: CFTypeRef?
            
            AXUIElementCopyAttributeValue(window, kAXRoleAttribute as CFString, &role)
            AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subrole)
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)
            
            let roleString = role as? String ?? ""
            let subroleString = subrole as? String ?? ""
            let titleString = title as? String ?? ""
            
            // Prioritize standard windows with titles (avoiding toolbars, drawers, etc.)
            if roleString == kAXWindowRole && subroleString == kAXStandardWindowSubrole && !titleString.isEmpty {
                // Special check for Outlook: avoid "Reminders" window if possible
                if titleString.contains("Reminders") && windowArray.count > 1 {
                    continue
                }
                return window
            }
        }
        
        // 3. Last resort: return the first window if any exist
        return windowArray.first
    }
    
    /// Returns the `MonitorRole` for a detected monitor based on its characteristics.
    /// Use this wherever a position label must be written into a `Monitor` config record.
    static func positionLabel(for monitor: CocoaMonitorInfo) -> MonitorRole {
        if monitor.isBuiltIn  { return .builtin }
        if monitor.isWorkspace { return .workspace }
        return .secondary
    }
    
    /// Shared predicate for built-in screen detection.
    static func isBuiltInScreen(_ screen: ScreenSnapshot) -> Bool {
        screen.localizedName.contains("Built-in") || screen.localizedName.contains("Liquid")
    }

    static func isBuiltInScreen(_ screen: NSScreen) -> Bool {
        isBuiltInScreen(ScreenSnapshot(screen))
    }

    /// Config `resolution` values that name the built-in display rather than a literal
    /// pixel size. Single source of truth for `detectProfile()`, `getAllMonitors(for:)`
    /// and `findWorkspaceMonitor(resolution:from:)`.
    static func isBuiltInAlias(_ resolution: String) -> Bool {
        let normalized = resolution.lowercased()
        return normalized == "builtin" || normalized == "macbook"
    }

    /// Best guess at the built-in display, in order: an explicitly named built-in
    /// screen, the screen at the Cocoa origin, then the smallest by area.
    ///
    /// Returns `nil` only when no screens are attached. Routed through the
    /// screen provider so it is testable and so the class holds no direct
    /// `NSScreen` dependency.
    func getBuiltinScreen() -> ScreenSnapshot? {
        let screens = screenProvider.screens

        if let builtinScreen = screens.first(where: { Self.isBuiltInScreen($0) }) {
            return builtinScreen
        }
        if let originScreen = screens.first(where: { $0.frame.origin == .zero }) {
            return originScreen
        }
        return screens.min(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })
    }
    
    // MARK: - Debug Utilities
    
    func debugDescription(rect: CGRect, label: String, system: String = "Global") -> String {
        return "\(label): (\(rect.origin.x), \(rect.origin.y), \(rect.width), \(rect.height)) [\(system)]"
    }
    
    private func accessibilityErrorDescription(_ error: AXError) -> String {
        switch error {
        case .success:
            return "Success"
        case .failure:
            return "Generic failure"
        case .illegalArgument:
            return "Illegal argument"
        case .invalidUIElement:
            return "Invalid UI element"
        case .invalidUIElementObserver:
            return "Invalid UI element observer"
        case .cannotComplete:
            return "Cannot complete operation"
        case .attributeUnsupported:
            return "Attribute unsupported"
        case .actionUnsupported:
            return "Action unsupported"
        case .notificationUnsupported:
            return "Notification unsupported"
        case .notImplemented:
            return "Not implemented"
        case .notificationAlreadyRegistered:
            return "Notification already registered"
        case .notificationNotRegistered:
            return "Notification not registered"
        case .apiDisabled:
            return "Accessibility API disabled"
        case .noValue:
            return "No value"
        case .parameterizedAttributeUnsupported:
            return "Parameterized attribute unsupported"
        case .notEnoughPrecision:
            return "Not enough precision"
        @unknown default:
            return "Unknown error (\(error.rawValue))"
        }
    }
}

// MARK: - Identifiable

extension CocoaMonitorInfo: Identifiable {
    /// Stable identity: resolution + origin, unique per physical display.
    var id: String { "\(resolution)@\(Int(frame.origin.x)),\(Int(frame.origin.y))" }
}