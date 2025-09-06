import Foundation
import AppKit

/**
 * CoordinateManager handles coordinate system conversions between different macOS frameworks.
 *
 * macOS uses two primary coordinate systems:
 * 1. Cocoa/NSScreen: Bottom-left origin (0,0 at bottom-left of main screen)
 * 2. Quartz/Accessibility: Top-left origin (0,0 at top-left of main screen)
 *
 * This class provides translation methods to convert between these coordinate systems,
 * which is essential for accurate window positioning across multiple monitors.
 */
class CoordinateManager {

    /**
     * Translates a rectangle from Cocoa coordinate system (bottom-left origin) to 
     * Quartz coordinate system (top-left origin).
     *
     * This conversion is critical for window positioning because:
     * - NSScreen reports monitor positions using bottom-left origin
     * - Accessibility API expects window positions using top-left origin
     * - Without conversion, windows appear in incorrect positions
     *
     * @param rect: CGRect in Cocoa coordinate system (bottom-left origin)
     * @return: CGRect in Quartz coordinate system (top-left origin)
     *
     * Example:
     * - Cocoa rect: (100, 200, 300, 150) on 1440px high screen
     * - Quartz result: (100, 1090, 300, 150) // Y flipped: 1440 - 200 - 150 = 1090
     */
    func translateRectFromCocoaToQuartz(rect: CGRect, screen: NSScreen? = nil) -> CGRect {
        // Use provided screen or fall back to main screen for coordinate conversion reference
        let referenceScreen = screen ?? NSScreen.main
        guard let targetScreen = referenceScreen else {
            print("Warning: Could not get screen for coordinate conversion")
            return rect
        }
        
        let screenHeight = targetScreen.frame.height

        // Convert Y coordinate from bottom-left to top-left origin
        // Formula: newY = screenHeight - originalY - rectHeight
        let newY = screenHeight - rect.origin.y - rect.height
        
        // X coordinate remains unchanged, only Y coordinate is flipped
        return CGRect(x: rect.origin.x, y: newY, width: rect.width, height: rect.height)
    }
    
    /**
     * Translates a point from Cocoa coordinate system to Quartz coordinate system.
     * Convenience method for single points without width/height considerations.
     *
     * @param point: CGPoint in Cocoa coordinate system
     * @param height: Height reference for the object at this point (default: 0)
     * @return: CGPoint in Quartz coordinate system
     */
    func translatePointFromCocoaToQuartz(point: CGPoint, height: CGFloat = 0, screen: NSScreen? = nil) -> CGPoint {
        let rect = CGRect(origin: point, size: CGSize(width: 0, height: height))
        let translatedRect = translateRectFromCocoaToQuartz(rect: rect, screen: screen)
        return translatedRect.origin
    }
    
    /**
     * Validates that a coordinate conversion makes sense by checking bounds.
     * Useful for debugging coordinate system issues.
     *
     * @param originalRect: Original Cocoa rectangle
     * @param convertedRect: Converted Quartz rectangle
     * @return: Boolean indicating if conversion appears valid
     */
    func validateCoordinateConversion(originalRect: CGRect, convertedRect: CGRect) -> Bool {
        guard let primaryScreen = NSScreen.main else {
            return false
        }
        
        let screenHeight = primaryScreen.frame.height
        
        // Basic validation checks
        let xUnchanged = originalRect.origin.x == convertedRect.origin.x
        let sizeUnchanged = originalRect.size == convertedRect.size
        let yInBounds = convertedRect.origin.y >= 0 && convertedRect.origin.y <= screenHeight
        
        return xUnchanged && sizeUnchanged && yInBounds
    }
}
