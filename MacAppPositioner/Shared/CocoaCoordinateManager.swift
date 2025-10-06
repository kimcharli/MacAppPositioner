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
        let configManager = ConfigManager()
        let config = configManager.loadConfig()
        let mainScreenHeight = NSScreen.main?.frame.height ?? 0
        
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
    
    func setWindowPosition(pid: pid_t, position: CGPoint, size: CGSize? = nil) {
        let app = AXUIElementCreateApplication(pid)
        var windows: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows) == .success,
              let windowArray = windows as? [AXUIElement],
              let window = windowArray.first else {
            print("❌ Failed to get windows for PID \(pid)")
            return
        }
        
        var mutablePosition = position
        let positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, AXValueCreate(.cgPoint, &mutablePosition)!)
        
        if let size = size {
            var mutableSize = size
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, AXValueCreate(.cgSize, &mutableSize)!)
        }
        
        print("  🎯 Position result: \(positionResult == .success ? "SUCCESS" : "FAILED")")
        print("  📍 Final position: \(position)")
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
}