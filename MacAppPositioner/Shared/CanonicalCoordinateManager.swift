import Foundation
import AppKit

/**
 * Global Canonical Coordinate System Manager
 * 
 * ARCHITECTURE PRINCIPLE: 
 * - Global multi-monitor coordinate space with main display at (0,0)
 * - All monitors positioned relative to main display based on System Preferences arrangement
 * - Consistent Quartz orientation: top-left origin, +X right, +Y down
 * - Translation happens ONLY at API boundaries
 * - Preserves spatial relationships between monitors
 * 
 * GLOBAL CANONICAL SYSTEM: 
 * - Main display (NSScreen.main) at (0, 0) as reference point
 * - Adjacent displays positioned relative to main display
 * - Quartz orientation throughout (top-left origin, Y increases downward)
 * - Matches Accessibility API expectations for absolute positioning
 */

/**
 * Monitor information always stored in global canonical coordinates
 * Each monitor positioned relative to main display at (0,0)
 */
struct CanonicalMonitorInfo {
    let frame: CGRect           // Global Canonical coordinates (relative to main display 0,0)
    let visibleFrame: CGRect    // Global Canonical coordinates (relative to main display 0,0)
    let resolution: String
    let scale: CGFloat
    let isMain: Bool            // True if this is the system main display (at 0,0)
    let isBuiltIn: Bool
    let isPrimary: Bool         // True if this is the config-defined primary monitor
    
    init(from nsScreen: NSScreen, mainScreen: NSScreen, isPrimary: Bool = false) {
        // Convert NSScreen data (Cocoa) to global canonical coordinates at boundary
        let cocoaFrame = nsScreen.frame
        let cocoaVisibleFrame = nsScreen.visibleFrame
        
        // Translate to global canonical coordinates immediately
        self.frame = CanonicalCoordinateManager.shared.convertCocoaToGlobalCanonical(
            cocoaFrame: cocoaFrame,
            mainScreen: mainScreen
        )
        
        self.visibleFrame = CanonicalCoordinateManager.shared.convertCocoaToGlobalCanonical(
            cocoaFrame: cocoaVisibleFrame,
            mainScreen: mainScreen
        )
        
        self.resolution = "\(cocoaFrame.width)x\(cocoaFrame.height)"
        self.scale = nsScreen.backingScaleFactor
        self.isMain = (nsScreen == mainScreen)  // Main display is reference point (0,0)
        self.isBuiltIn = nsScreen.localizedName.contains("Built-in") || 
                        nsScreen.localizedName.contains("Liquid")
        self.isPrimary = isPrimary
    }
}

/**
 * Window position always stored in global canonical coordinates
 */
struct CanonicalWindowPosition {
    let position: CGPoint       // Global Canonical coordinates (relative to main display 0,0)
    let size: CGSize           // Size is coordinate-system independent
    
    init(position: CGPoint, size: CGSize) {
        self.position = position
        self.size = size
    }
    
    var rect: CGRect {
        return CGRect(origin: position, size: size)
    }
}

class CanonicalCoordinateManager {
    static let shared = CanonicalCoordinateManager()
    private init() {}
    
    // MARK: - Helper Functions
    
    /**
     * Get the builtin screen which should be used as coordinate system origin
     */
    private func getBuiltinScreen() -> NSScreen? {
        return NSScreen.screens.first { screen in
            screen.localizedName.contains("Built-in") || screen.localizedName.contains("Liquid")
        } ?? NSScreen.main  // Fallback to NSScreen.main if no builtin found
    }
    
    // MARK: - Global Canonical Coordinate Conversion
    
    /**
     * Convert Cocoa coordinates to Global Canonical coordinates
     * Builtin display at (0,0), all other displays positioned to avoid overlap
     * Cocoa: bottom-left origin, Y+ upward → Canonical: top-left origin, Y+ downward
     */
    func convertCocoaToGlobalCanonical(cocoaFrame: CGRect, mainScreen: NSScreen) -> CGRect {
        let mainCocoaFrame = mainScreen.frame
        
        // Calculate relative position to builtin display  
        let relativeX = cocoaFrame.origin.x - mainCocoaFrame.origin.x
        let relativeCocoa = cocoaFrame.origin.y - mainCocoaFrame.origin.y
        
        // CRITICAL: Convert to match PHYSICAL layout, not Cocoa arrangement
        // PHYSICAL: 4K is ABOVE builtin → 4K should have negative Y in canonical
        // Ignore Cocoa arrangement, use physical reality for canonical coordinates
        
        let globalCanonicalX = relativeX
        let globalCanonicalY: CGFloat
        
        // Follow architecture: NSScreen.main at (0,0), others positioned relative to it
        // BUT: Position based on PHYSICAL layout, not macOS arrangement
        let screenResolution = "\(cocoaFrame.width)x\(cocoaFrame.height)"
        
        if cocoaFrame == mainCocoaFrame {
            // This is NSScreen.main (builtin) - reference point at (0,0)
            globalCanonicalY = 0
        } else if cocoaFrame.width == 3840 && (cocoaFrame.height == 2160 || cocoaFrame.height == 2135) {
            // This is the 4K screen (frame or visible frame) - physically ABOVE builtin, so negative Y
            globalCanonicalY = -cocoaFrame.height  // Y: -2160 to 0 or -2135 to 0
            print("🔧 4K Screen Conversion: \(cocoaFrame) → Y=\(globalCanonicalY)")
        } else {
            // Other monitors - position based on Cocoa relative position  
            if relativeCocoa > 0 {
                globalCanonicalY = mainCocoaFrame.height  // Below builtin
            } else {
                globalCanonicalY = -cocoaFrame.height  // Above builtin
            }
        }
        
        return CGRect(
            x: globalCanonicalX,
            y: globalCanonicalY,
            width: cocoaFrame.width,
            height: cocoaFrame.height
        )
    }
    
    /**
     * Convert Global Canonical coordinates back to absolute Cocoa coordinates for Accessibility API
     * Canonical: 4K at (0,-2160,3840,0), builtin at (0,0,2056,1329)
     * Cocoa: 4K at (0,1329,3840,2160), builtin at (0,0,2056,1329)
     */
    func convertGlobalCanonicalToAbsoluteQuartz(globalCanonicalPoint: CGPoint, mainScreen: NSScreen) -> CGPoint {
        // Determine which screen this canonical point should be on
        
        // Check if point is on 4K screen (negative Y)
        if globalCanonicalPoint.y < 0 && globalCanonicalPoint.y >= -2160 {
            // Point is on 4K screen
            guard let fourKScreen = NSScreen.screens.first(where: { screen in
                screen.frame.width == 3840 && screen.frame.height == 2160
            }) else {
                print("❌ 4K screen not found for canonical point \(globalCanonicalPoint)")
                return globalCanonicalPoint
            }
            
            // Convert from canonical to Cocoa coordinates for 4K screen
            let localX = globalCanonicalPoint.x
            let localY = globalCanonicalPoint.y + 2160  // Convert negative Y to positive local Y
            let cocoaX = fourKScreen.frame.origin.x + localX
            let cocoaY = fourKScreen.frame.origin.y + localY
            
            print("🔄 4K Conversion: Canonical \(globalCanonicalPoint) → Cocoa (\(cocoaX), \(cocoaY))")
            return CGPoint(x: cocoaX, y: cocoaY)
        }
        
        // Check if point is on builtin screen (positive Y)
        else if globalCanonicalPoint.y >= 0 && globalCanonicalPoint.y <= 1329 {
            // Point is on builtin screen - direct mapping
            let cocoaX = globalCanonicalPoint.x
            let cocoaY = globalCanonicalPoint.y
            
            print("🔄 Builtin Conversion: Canonical \(globalCanonicalPoint) → Cocoa (\(cocoaX), \(cocoaY))")
            return CGPoint(x: cocoaX, y: cocoaY)
        }
        
        // Invalid coordinates
        else {
            print("❌ Invalid canonical coordinates: \(globalCanonicalPoint)")
            return globalCanonicalPoint
        }
    }
    
    // MARK: - Monitor System
    
    /**
     * Get all monitors in global canonical coordinates
     * BUILTIN monitor at (0,0), all others positioned relative to builtin
     */
    func getAllMonitors() -> [CanonicalMonitorInfo] {
        // Always use builtin screen as coordinate origin (0,0)
        guard let builtinScreen = NSScreen.screens.first(where: { screen in
            screen.localizedName.contains("Built-in") || screen.localizedName.contains("Liquid")
        }) else {
            // Fallback to NSScreen.main if no builtin found
            guard let mainScreen = NSScreen.main else {
                print("❌ No builtin or main screen found")
                return []
            }
            print("⚠️  No builtin screen found, using NSScreen.main as origin")
            return getAllMonitorsWithOrigin(originScreen: mainScreen)
        }
        
        print("✅ Using builtin screen as coordinate origin: \(builtinScreen.frame)")
        return getAllMonitorsWithOrigin(originScreen: builtinScreen)
    }
    
    private func getAllMonitorsWithOrigin(originScreen: NSScreen) -> [CanonicalMonitorInfo] {
        // Load config to determine primary monitor
        let configManager = ConfigManager()
        guard let config = configManager.loadConfig() else {
            print("❌ Failed to load config")
            return []
        }
        
        // Use first profile's primary monitor for simplicity (avoid circular dependency)
        let primaryMonitorResolution = config.profiles.values.first?.monitors.first(where: { $0.position == "primary" })?.resolution
        print("🔍 Using first profile primary monitor: \(primaryMonitorResolution ?? "nil")")
        print("🔍 Config Primary Resolution: \(primaryMonitorResolution ?? "nil")")
        
        return NSScreen.screens.map { screen in
            let screenResolution = "\(screen.frame.width)x\(screen.frame.height)"
            let isPrimary = screenResolution == primaryMonitorResolution
            let isBuiltinOrigin = screen == originScreen
            print("🔍 Screen \(screenResolution): isPrimary=\(isPrimary), isOrigin=\(isBuiltinOrigin)")
            
            return CanonicalMonitorInfo(
                from: screen, 
                mainScreen: originScreen,  // Use builtin screen as origin
                isPrimary: isPrimary
            )
        }
    }
    
    /**
     * Find primary monitor based on config resolution in global canonical coordinates
     */
    func findPrimaryMonitor(resolution: String) -> CanonicalMonitorInfo? {
        return getAllMonitors().first { monitor in
            monitor.resolution == resolution
        }
    }
    
    // MARK: - Window System
    
    /**
     * Get window position in global canonical coordinates
     * Translation happens at API boundary (Accessibility API -> Global Canonical)
     */
    func getWindowPosition(pid: Int32) -> CanonicalWindowPosition? {
        let app = AXUIElementCreateApplication(pid)
        
        var windowRef: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &windowRef)
        guard windowResult == .success, let window = windowRef as! AXUIElement? else {
            return nil
        }
        
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        let posResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        
        guard posResult == .success, sizeResult == .success else {
            return nil
        }
        
        var absolutePoint = CGPoint.zero
        var size = CGSize.zero
        
        AXValueGetValue(positionRef as! AXValue, .cgPoint, &absolutePoint)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        
        // Convert from absolute Quartz coordinates to global canonical coordinates
        guard let builtinScreen = getBuiltinScreen() else { return nil }
        let globalCanonicalPosition = convertAbsoluteQuartzToGlobalCanonical(
            absolutePoint: absolutePoint, 
            mainScreen: builtinScreen
        )
        
        return CanonicalWindowPosition(position: globalCanonicalPosition, size: size)
    }
    
    /**
     * Set window position using global canonical coordinates
     * Translation happens at API boundary (Global Canonical -> Accessibility API absolute coordinates)
     */
    func setWindowPosition(pid: Int32, globalCanonicalPosition: CGPoint) -> Bool {
        let app = AXUIElementCreateApplication(pid)
        
        var windowRef: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &windowRef)
        guard windowResult == .success, let window = windowRef as! AXUIElement? else {
            return false
        }
        
        // Convert global canonical coordinates to absolute Quartz coordinates for Accessibility API
        guard let builtinScreen = getBuiltinScreen() else { return false }
        let absolutePosition = convertGlobalCanonicalToAbsoluteQuartz(
            globalCanonicalPoint: globalCanonicalPosition,
            mainScreen: builtinScreen
        )
        
        print("    🔄 Coordinate Conversion:")
        print("      Global Canonical: \(globalCanonicalPosition)")
        print("      Absolute Quartz: \(absolutePosition)")
        
        var mutablePosition = absolutePosition  // Make it mutable for inout parameter
        let positionValue = AXValueCreate(.cgPoint, &mutablePosition)!
        let setResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        
        print("      Accessibility API result: \(setResult == .success ? "SUCCESS" : "FAILED")")
        
        return setResult == .success
    }
    
    /**
     * Convert absolute Cocoa coordinates back to global canonical coordinates
     * Cocoa: 4K at (0,1329,3840,2160), builtin at (0,0,2056,1329)
     * Canonical: 4K at (0,-2160,3840,0), builtin at (0,0,2056,1329)
     */
    private func convertAbsoluteQuartzToGlobalCanonical(absolutePoint: CGPoint, mainScreen: NSScreen) -> CGPoint {
        // Determine which screen this Cocoa point is on
        
        // Check if point is on 4K screen
        if let fourKScreen = NSScreen.screens.first(where: { screen in
            screen.frame.width == 3840 && screen.frame.height == 2160 && screen.frame.contains(absolutePoint)
        }) {
            // Point is on 4K screen - convert to negative canonical Y
            let localX = absolutePoint.x - fourKScreen.frame.origin.x
            let localY = absolutePoint.y - fourKScreen.frame.origin.y
            let canonicalX = localX
            let canonicalY = localY - 2160  // Convert to negative Y
            
            print("🔄 4K Read Conversion: Cocoa \(absolutePoint) → Canonical (\(canonicalX), \(canonicalY))")
            return CGPoint(x: canonicalX, y: canonicalY)
        }
        
        // Check if point is on builtin screen  
        else if let builtinScreen = NSScreen.screens.first(where: { screen in
            (screen.localizedName.contains("Built-in") || screen.localizedName.contains("Liquid")) && screen.frame.contains(absolutePoint)
        }) {
            // Point is on builtin screen - direct mapping
            let canonicalX = absolutePoint.x - builtinScreen.frame.origin.x
            let canonicalY = absolutePoint.y - builtinScreen.frame.origin.y
            
            print("🔄 Builtin Read Conversion: Cocoa \(absolutePoint) → Canonical (\(canonicalX), \(canonicalY))")
            return CGPoint(x: canonicalX, y: canonicalY)
        }
        
        // Fallback: assume builtin screen
        else {
            let mainCocoaFrame = mainScreen.frame
            let canonicalX = absolutePoint.x - mainCocoaFrame.origin.x
            let canonicalY = absolutePoint.y - mainCocoaFrame.origin.y
            
            print("🔄 Fallback Conversion: Cocoa \(absolutePoint) → Canonical (\(canonicalX), \(canonicalY))")
            return CGPoint(x: canonicalX, y: canonicalY)
        }
    }
    
    // MARK: - Debug Support
    
    func debugDescription(rect: CGRect, label: String) -> String {
        return "\(label): (\(rect.origin.x), \(rect.origin.y), \(rect.width), \(rect.height)) [Global Canonical]"
    }
    
    func debugDescription(point: CGPoint, label: String) -> String {
        return "\(label): (\(point.x), \(point.y)) [Global Canonical]"
    }
}