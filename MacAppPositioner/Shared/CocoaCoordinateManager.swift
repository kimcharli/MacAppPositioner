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

    /// Describes every attached screen in the internal coordinate system.
    ///
    /// - Parameter workspaceResolution: The configured resolution of the profile's
    ///   workspace monitor, used to set `isWorkspace`. Pass `nil` when no profile
    ///   is in play; no monitor is then flagged.
    ///
    /// This deliberately takes a resolution rather than a profile name. It used to
    /// take a name and load `ConfigManager.shared` itself, which meant a caller
    /// holding an injected config got a monitor list derived from a *different*
    /// config. Config access belongs to the caller; this type does geometry.
    func getAllMonitors(workspaceResolution: String? = nil) -> [CocoaMonitorInfo] {
        let screens = screenProvider.screens
        // screens.first is always the menu bar screen (Cocoa origin 0,0).
        // Do NOT use NSScreen.main here — it returns different screens in CLI vs GUI contexts.
        let mainScreenHeight = screens.first?.frame.height ?? 0

        return screens.map { screen in
            let isWorkspace = workspaceResolution.map { configured in
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

    /// Builds the `monitors` array to persist for a profile, **keeping the
    /// workspace role**.
    ///
    /// `positionLabel(for:)` alone cannot do this. It reads `monitor.isWorkspace`,
    /// which `getAllMonitors` only sets when told which resolution is the
    /// workspace one. Callers that omitted that argument got `false` for every
    /// screen and therefore a profile with no workspace monitor at all, which
    /// makes `generatePlan` silently drop every `layout.workspace` app.
    ///
    /// Pass the workspace resolution of the profile being updated so the
    /// operator's choice survives the round trip. Pass `nil` when creating a
    /// profile: the first non-builtin display is chosen, the same heuristic
    /// `generateConfigForCurrentSetup` uses, so all three writers agree.
    ///
    /// Resolutions are normalised on the way out (`2056.0x1329.0` -> `2056x1329`)
    /// to match what `generate-config` writes.
    ///
    /// A machine with only a built-in display yields no workspace monitor. That
    /// is intentional: the built-in role wins, and such a setup positions apps
    /// through `layout.builtin`.
    func profileMonitors(preservingWorkspace workspaceResolution: String?) -> [Monitor] {
        let monitors = getAllMonitors(workspaceResolution: workspaceResolution)

        // False when creating a profile, or when the display that used to be the
        // workspace is no longer attached. Either way, fall back to the first
        // non-builtin screen rather than leaving the profile without one.
        var workspaceAssigned = monitors.contains { $0.isWorkspace }

        return monitors.map { monitor in
            let role: MonitorRole
            if monitor.isBuiltIn {
                role = .builtin
            } else if monitor.isWorkspace {
                role = .workspace
            } else if !workspaceAssigned {
                role = .workspace
                workspaceAssigned = true
            } else {
                role = .secondary
            }
            return Monitor(resolution: AppUtils.normalizeResolution(monitor.resolution),
                           position: role)
        }
    }
    
    /// Shared predicate for built-in screen detection.
    static func isBuiltInScreen(_ screen: ScreenSnapshot) -> Bool {
        screen.localizedName.contains("Built-in") || screen.localizedName.contains("Liquid")
    }

    static func isBuiltInScreen(_ screen: NSScreen) -> Bool {
        isBuiltInScreen(ScreenSnapshot(screen))
    }

    /// Config `resolution` values that name the built-in display rather than a literal
    /// Single source of truth for `detectProfile()`, `getAllMonitors(workspaceResolution:)`
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
    
    /// Formats a rect for diagnostic output.
    ///
    /// `label` is optional: callers that already print their own prefix pass an
    /// empty string, and the leading separator is dropped rather than rendering
    /// as a doubled colon (`Current: : (0.0, …)`).
    func debugDescription(rect: CGRect, label: String = "", system: String = "Global") -> String {
        let geometry = "(\(rect.origin.x), \(rect.origin.y), \(rect.width), \(rect.height)) [\(system)]"
        return label.isEmpty ? geometry : "\(label): \(geometry)"
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