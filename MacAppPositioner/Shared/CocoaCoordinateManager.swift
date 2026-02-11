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
    let isMain: Bool
    let isBuiltIn: Bool
    let isWorkspace: Bool
    
    init(from nsScreen: NSScreen, isWorkspace: Bool = false, mainScreenHeight: CGFloat) {
        self.frame = CocoaCoordinateManager.shared.convertCocoaToInternal(cocoaRect: nsScreen.frame, mainScreenHeight: mainScreenHeight)
        self.visibleFrame = CocoaCoordinateManager.shared.convertCocoaToInternal(cocoaRect: nsScreen.visibleFrame, mainScreenHeight: mainScreenHeight)
        self.resolution = "\(nsScreen.frame.width)x\(nsScreen.frame.height)"
        self.scale = nsScreen.backingScaleFactor
        self.isMain = nsScreen == NSScreen.main
        self.isBuiltIn = nsScreen.localizedName.contains("Built-in") || nsScreen.localizedName.contains("Liquid")
        self.isWorkspace = isWorkspace
    }
}

class CocoaCoordinateManager {
    static let shared = CocoaCoordinateManager()
    
    private init() {}
    
    // MARK: - Coordinate Conversion
    
    func convertCocoaToInternal(cocoaRect: CGRect, mainScreenHeight: CGFloat) -> CGRect {
        let internalY = mainScreenHeight - cocoaRect.maxY
        return CGRect(x: cocoaRect.origin.x, y: internalY, width: cocoaRect.width, height: cocoaRect.height)
    }

    // MARK: - Monitor Detection
    
    func getAllMonitors(for profileName: String? = nil) -> [CocoaMonitorInfo] {
        let configManager = ConfigManager.shared
        let config = configManager.loadConfig()
        // NSScreen.screens.first is always the menu bar screen (Cocoa origin 0,0).
        // Do NOT use NSScreen.main here — it returns different screens in CLI vs GUI contexts.
        let mainScreenHeight = NSScreen.screens.first?.frame.height ?? 0
        
        var workspaceMonitorResolution: String?
        if let profileName = profileName, let profile = config?.profiles[profileName] {
            workspaceMonitorResolution = profile.monitors.first(where: { $0.position == "workspace" })?.resolution
        }
        
        return NSScreen.screens.map { screen in
            let screenResolution = "\(screen.frame.width)x\(screen.frame.height)"
            let isWorkspace = workspaceMonitorResolution.map { AppUtils.normalizeResolution(screenResolution) == AppUtils.normalizeResolution($0) } ?? false
            return CocoaMonitorInfo(from: screen, isWorkspace: isWorkspace, mainScreenHeight: mainScreenHeight)
        }
    }
    
    func findWorkspaceMonitor(resolution: String) -> CocoaMonitorInfo? {
        return getAllMonitors().first { monitor in
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
        var window: AnyObject?
        
        let result = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &window)

        if result == .success, let window = window {
            var positionRef: AnyObject?
            var sizeRef: AnyObject?
            
            let positionResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, &positionRef)
            let sizeResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXSizeAttribute as CFString, &sizeRef)

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
        }
        
        return nil
    }
    
    func setWindowPosition(pid: pid_t, position: CGPoint, size: CGSize? = nil) {
        let app = AXUIElementCreateApplication(pid)
        
        // Attempt to activate the application to bring it to the front and give it focus
        if let runningApp = NSRunningApplication(processIdentifier: pid) {
            runningApp.activate(options: .activateIgnoringOtherApps)
        }
        
        var windows: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows) == .success, 
              let windowArray = windows as? [AXUIElement],
              let window = windowArray.first else {
            let error = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows)
            print("❌ Failed to get windows for PID \(pid). Error: \(accessibilityErrorDescription(error))")
            return
        }
        
        var mutablePosition = position
        var positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &mutablePosition)!)
        
        // If initial positioning fails or is not successful, try again after a short delay
        if positionResult != .success {
            Thread.sleep(forTimeInterval: 0.1) // Small delay
            positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &mutablePosition)!)
        }
        if let size = size {
            var mutableSize = size
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &mutableSize)!)
        }
        
        print("  🎯 Position result: \(positionResult == .success ? "SUCCESS" : "FAILED")")
        print("  📍 Final position: \(position)")
        
        // Verify the position after setting it
        if let actualFrame = getWindowFrame(pid: pid) {
            let tolerance: CGFloat = 1.0 // Allow for minor discrepancies
            if abs(actualFrame.position.x - position.x) > tolerance || abs(actualFrame.position.y - position.y) > tolerance {
                print("❌ Window did not move to the exact calculated position. Actual: \(actualFrame.position)")
            } else {
                print("✅ Window moved to the calculated position.")
            }
        } else {
            print("⚠️ Could not retrieve actual window position after setting.")
        }
    }
    
    func calculateQuadrantPosition(quadrant: String, windowSize: CGSize, visibleFrame: CGRect) -> CGPoint {
        let baseX: CGFloat
        let baseY: CGFloat
        
        switch quadrant {
        case "top_left":
            baseX = visibleFrame.minX
            baseY = visibleFrame.minY
        case "top_right":
            baseX = visibleFrame.maxX - windowSize.width
            baseY = visibleFrame.minY
        case "bottom_left":
            baseX = visibleFrame.minX
            baseY = visibleFrame.maxY - windowSize.height
        case "bottom_right":
            baseX = visibleFrame.maxX - windowSize.width
            baseY = visibleFrame.maxY - windowSize.height
        default:
            baseX = visibleFrame.minX
            baseY = visibleFrame.minY
        }
        
        return CGPoint(x: baseX, y: baseY)
    }
    
    func getBuiltinScreen() -> NSScreen {
        if let builtinScreen = NSScreen.screens.first(where: { $0.localizedName.contains("Built-in") || $0.localizedName.contains("Liquid") }) {
            return builtinScreen
        }
        if let originScreen = NSScreen.screens.first(where: { $0.frame.origin == .zero }) {
            return originScreen
        }
        if let smallestScreen = NSScreen.screens.min(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) {
            return smallestScreen
        }
        return NSScreen.screens.first!
    }
    
    // MARK: - Debug Utilities
    
    func debugDescription(rect: CGRect, label: String, system: String = "Global") -> String {
        return "\(label): (\(rect.origin.x), \(rect.origin.y), \(rect.width), \(rect.height)) [\(system)]"
    }
    
    /**
     * Provides human-readable descriptions for Accessibility API error codes.
     *
     * @param error: AXError code from Accessibility API
     * @return: String description of the error
     */
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
            return "Unknown error (\\(error.rawValue))"
        }
    }
}