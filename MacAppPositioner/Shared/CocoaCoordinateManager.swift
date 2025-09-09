import Foundation
import AppKit

/**
 * Native Cocoa Coordinate System Manager
 * 
 * ARCHITECTURE PRINCIPLE: 
 * - Uses ONLY native Cocoa coordinates (NSScreen.frame)
 * - Bottom-left origin, Y increases upward (native macOS behavior)
 * - NO coordinate conversions or custom systems
 * - Direct NSScreen API usage throughout
 * 
 * REFERENCE: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html
 * 
 * NATIVE COCOA SYSTEM: 
 * - NSScreen.frame provides native Cocoa coordinates
 * - Contiguous coordinate space across all monitors
 * - Y-axis increases upward (bottom-left origin)
 * - Use directly without any conversion
 */

/**
 * Monitor information using native Cocoa coordinates
 * Direct from NSScreen with no modifications
 */
struct CocoaMonitorInfo {
    let frame: CGRect           // Native Cocoa coordinates from NSScreen.frame
    let visibleFrame: CGRect    // Native Cocoa coordinates from NSScreen.visibleFrame
    let resolution: String
    let scale: CGFloat
    let isMain: Bool            // True if this is NSScreen.main
    let isBuiltIn: Bool
    let isWorkspace: Bool       // True if this is the config-defined workspace monitor
    
    init(from nsScreen: NSScreen, isWorkspace: Bool = false) {
        // Use native Cocoa coordinates directly - no conversion
        self.frame = nsScreen.frame
        self.visibleFrame = nsScreen.visibleFrame
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
    
    // MARK: - Helper Functions
    
    // MARK: - Monitor Detection (Native Cocoa)
    
    /**
     * Get all monitors using native Cocoa coordinates
     * Uses NSScreen.screens directly - no conversion
     */
    func getAllMonitors(for profileName: String? = nil) -> [CocoaMonitorInfo] {
        let configManager = ConfigManager()
        let config = configManager.loadConfig()
        
        // Find workspace monitor resolution from the specified profile or detect current profile
        var workspaceMonitorResolution: String?
        
        if let profileName = profileName,
           let profile = config?.profiles[profileName] {
            // Use specified profile
            workspaceMonitorResolution = profile.monitors.first(where: { $0.position == "workspace" })?.resolution
            print("🔍 Using workspace monitor from profile '\(profileName)': \(workspaceMonitorResolution ?? "nil")")
        } else {
            // Fallback: no workspace detection for auto-detect calls to avoid circular dependency
            print("🔍 No profile specified, workspace detection disabled")
        }
        
        return NSScreen.screens.map { screen in
            let screenResolution = "\(screen.frame.width)x\(screen.frame.height)"
            let isWorkspace = if let workspaceRes = workspaceMonitorResolution {
                AppUtils.normalizeResolution(screenResolution) == AppUtils.normalizeResolution(workspaceRes)
            } else {
                false
            }
            
            print("🔍 Screen \(screenResolution): isWorkspace=\(isWorkspace), isMain=\(screen == NSScreen.main)")
            
            return CocoaMonitorInfo(from: screen, isWorkspace: isWorkspace)
        }
    }
    
    /**
     * Find workspace monitor using native Cocoa coordinates
     */
    func findWorkspaceMonitor(resolution: String) -> CocoaMonitorInfo? {
        return getAllMonitors().first { monitor in
            AppUtils.normalizeResolution(monitor.resolution) == AppUtils.normalizeResolution(resolution)
        }
    }
    
    // MARK: - Window Positioning (Native Cocoa)
    
    /**
     * Set window position using native Cocoa coordinates
     * No conversion - pass coordinates directly to Accessibility API
     */
    func setWindowPosition(pid: pid_t, position: CGPoint, size: CGSize? = nil, mainScreen: NSScreen?) {
        let app = AXUIElementCreateApplication(pid)
        
        var windows: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows)
        
        guard result == .success,
              let windowArray = windows as? [AXUIElement],
              let window = windowArray.first else {
            print("❌ Failed to get windows for PID \(pid)")
            return
        }
        
        // Convert from Cocoa coordinates to Accessibility API coordinates
        // Workspace monitor is above builtin, so it uses negative Y values in Accessibility API
        let accessibilityPosition: CGPoint
        let mainScreenHeight = mainScreen?.frame.height ?? 0
        
        if position.y >= mainScreenHeight { // If on workspace monitor
            // Convert: AccessibilityY = -(CocoaY - mainScreenHeight)
            accessibilityPosition = CGPoint(
                x: position.x,
                y: -(position.y - mainScreenHeight)
            )
        } else { // If on builtin monitor
            accessibilityPosition = position
        }
        
        var accessPos = accessibilityPosition
        let positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &accessPos)!)
        
        if let size = size {
            var cocoaSize = size
            let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &cocoaSize)!)
            print("  📏 Size result: \(sizeResult == .success ? "SUCCESS" : "FAILED")")
        }
        
        print("  🎯 Position result: \(positionResult == .success ? "SUCCESS" : "FAILED")")
        print("  📍 Native Cocoa position: \(position)")
    }
    
    /**
     * Calculate the target position for a window within a specific quadrant of a monitor.
     * All calculations are performed in the native Cocoa coordinate system.
     * 
     * @param quadrant The target quadrant (e.g., "top_left", "bottom_right").
     * @param windowSize The size of the window to be positioned.
     * @param visibleFrame The visible frame of the target monitor in Cocoa coordinates.
     * @return The calculated top-left point of the window in Cocoa coordinates.
     */
    func calculateQuadrantPosition(quadrant: String, windowSize: CGSize, visibleFrame: CGRect) -> CGPoint {
        let baseX: CGFloat
        let baseY: CGFloat
        
        switch quadrant {
        case "top_left":
            // Position at the top-left corner of the visible frame.
            baseX = visibleFrame.minX
            baseY = visibleFrame.maxY
        case "top_right":
            // Position at the top-right corner, accounting for the window's width.
            baseX = visibleFrame.maxX - windowSize.width
            baseY = visibleFrame.maxY
        case "bottom_left":
            // Position at the bottom-left corner, accounting for the window's height.
            baseX = visibleFrame.minX
            baseY = visibleFrame.minY + windowSize.height
        case "bottom_right":
            // Position at the bottom-right corner, accounting for both width and height.
            baseX = visibleFrame.maxX - windowSize.width
            baseY = visibleFrame.minY + windowSize.height
        default:
            // Default to the top-left corner if the quadrant is unknown.
            baseX = visibleFrame.minX
            baseY = visibleFrame.maxY
        }
        
        return CGPoint(x: baseX, y: baseY)
    }
    
    // MARK: - Debug Utilities
    
    func debugDescription(rect: CGRect, label: String) -> String {
        return "\(label): (\(rect.origin.x), \(rect.origin.y), \(rect.width), \(rect.height)) [Native Cocoa]"
    }
}seX = visibleFrame.maxX - windowSize.width  // Right edge minus window width
            baseY = visibleFrame.minY + windowSize.height  // Bottom edge plus window height
        default:
            baseX = visibleFrame.minX
            baseY = visibleFrame.minY
        }
        
        return CGPoint(x: baseX, y: baseY)
    }
    
    // MARK: - Debug Utilities
    
    func debugDescription(rect: CGRect, label: String) -> String {
        return "\(label): (\(rect.origin.x), \(rect.origin.y), \(rect.width), \(rect.height)) [Native Cocoa]"
    }
}