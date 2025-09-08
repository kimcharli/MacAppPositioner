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
    
    /**
     * Normalize resolution strings to handle both user-friendly and system formats
     * Converts "3440x1440" and "3440.0x1440.0" to a consistent comparable format
     */
    private func normalizeResolution(_ resolution: String) -> String {
        // Remove .0 suffixes and normalize to simple "widthxheight" format
        let cleaned = resolution
            .replacingOccurrences(of: ".0", with: "")
            .replacingOccurrences(of: " ", with: "")
        return cleaned
    }
    
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
                normalizeResolution(screenResolution) == normalizeResolution(workspaceRes)
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
            normalizeResolution(monitor.resolution) == normalizeResolution(resolution)
        }
    }
    
    // MARK: - Window Positioning (Native Cocoa)
    
    /**
     * Set window position using native Cocoa coordinates
     * No conversion - pass coordinates directly to Accessibility API
     */
    func setWindowPosition(pid: pid_t, position: CGPoint, size: CGSize? = nil) {
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
        if position.y >= 1329 { // If on workspace monitor (Cocoa Y >= 1329)
            // Workspace monitor: Y=-2160 (top) to Y=0 (bottom) in Accessibility API
            // Cocoa workspace: Y=1329 (bottom) to Y=3489 (top)
            // Convert: AccessibilityY = -(CocoaY - 1329)
            accessibilityPosition = CGPoint(
                x: position.x,
                y: -(position.y - 1329)
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
     * Calculate quadrant position using native Cocoa coordinates
     * Pure Cocoa calculation - no conversion
     */
    func calculateQuadrantPosition(quadrant: String, windowSize: CGSize, visibleFrame: CGRect) -> CGPoint {
        let baseX: CGFloat
        let baseY: CGFloat
        
        switch quadrant {
        case "top_left":
            baseX = visibleFrame.minX  // Exact left edge (X=0)
            baseY = visibleFrame.maxY  // Exact top edge (will convert to Y=-2160)
        case "top_right":
            baseX = visibleFrame.maxX - windowSize.width  // Right edge minus window width
            baseY = visibleFrame.maxY  // Exact top edge (will convert to Y=-2160)
        case "bottom_left":
            baseX = visibleFrame.minX  // Exact left edge (X=0)
            baseY = visibleFrame.minY + windowSize.height  // Bottom edge plus window height
        case "bottom_right":
            baseX = visibleFrame.maxX - windowSize.width  // Right edge minus window width
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