#!/usr/bin/env swift

import AppKit
import Foundation

// Mock window manager for testing
class TestWindowManager {
    func getWindowFrame(pid: Int32) -> (CGPoint, CGSize)? {
        // Return different test window sizes
        switch pid {
        case 1: return (CGPoint(x: 100, y: 200), CGSize(width: 1200, height: 800))  // Chrome
        case 2: return (CGPoint(x: 50, y: 100), CGSize(width: 1000, height: 700))   // Outlook  
        case 3: return (CGPoint(x: 2000, y: 300), CGSize(width: 800, height: 600))  // Teams
        case 4: return (CGPoint(x: 2500, y: 150), CGSize(width: 400, height: 500))  // KakaoTalk
        default: return nil
        }
    }
}

// Test positioning calculations
func testPositioningLogic() {
    print("=== Positioning Logic Test Cases ===\n")
    
    // Get the primary monitor (4K external)
    let targetResolution = "3840.0x2160.0"
    guard let primaryScreen = NSScreen.screens.first(where: { "\($0.frame.width)x\($0.frame.height)" == targetResolution }) else {
        print("❌ Cannot find primary monitor for testing")
        return
    }
    
    let screenFrame = primaryScreen.frame
    let visibleFrame = primaryScreen.visibleFrame
    
    print("Primary Monitor:")
    print("  Screen Frame: \(screenFrame)")
    print("  Visible Frame: \(visibleFrame)")
    print("  Screen Origin: (\(screenFrame.minX), \(screenFrame.minY))")
    print("")
    
    // Calculate quadrant dimensions
    let quadrantWidth = visibleFrame.width / 2
    let quadrantHeight = visibleFrame.height / 2
    
    print("Quadrant Information:")
    print("  Quadrant Size: \(quadrantWidth) x \(quadrantHeight)")
    print("")
    
    // Test each position with different window sizes
    let testCases = [
        ("top_left", "Chrome", CGSize(width: 1200, height: 800)),
        ("bottom_left", "Outlook", CGSize(width: 1000, height: 700)),
        ("top_right", "Teams", CGSize(width: 800, height: 600)),
        ("bottom_right", "KakaoTalk", CGSize(width: 400, height: 500))
    ]
    
    print("Expected Quadrant Boundaries:")
    print("  Top-Left: x[\(visibleFrame.minX) - \(visibleFrame.minX + quadrantWidth)], y[\(visibleFrame.minY + quadrantHeight) - \(visibleFrame.maxY)]")
    print("  Top-Right: x[\(visibleFrame.minX + quadrantWidth) - \(visibleFrame.maxX)], y[\(visibleFrame.minY + quadrantHeight) - \(visibleFrame.maxY)]")
    print("  Bottom-Left: x[\(visibleFrame.minX) - \(visibleFrame.minX + quadrantWidth)], y[\(visibleFrame.minY) - \(visibleFrame.minY + quadrantHeight)]")
    print("  Bottom-Right: x[\(visibleFrame.minX + quadrantWidth) - \(visibleFrame.maxX)], y[\(visibleFrame.minY) - \(visibleFrame.minY + quadrantHeight)]")
    print("")
    
    for (position, app, windowSize) in testCases {
        print("Testing \(position) positioning for \(app):")
        print("  Window Size: \(windowSize)")
        
        var newPosition = CGPoint.zero
        
        switch position {
        case "top_left":
            newPosition = CGPoint(
                x: visibleFrame.minX + (quadrantWidth - windowSize.width) / 2,
                y: visibleFrame.minY + quadrantHeight + (quadrantHeight - windowSize.height) / 2
            )
        case "top_right":
            newPosition = CGPoint(
                x: visibleFrame.minX + quadrantWidth + (quadrantWidth - windowSize.width) / 2,
                y: visibleFrame.minY + quadrantHeight + (quadrantHeight - windowSize.height) / 2
            )
        case "bottom_left":
            newPosition = CGPoint(
                x: visibleFrame.minX + (quadrantWidth - windowSize.width) / 2,
                y: visibleFrame.minY + (quadrantHeight - windowSize.height) / 2
            )
        case "bottom_right":
            newPosition = CGPoint(
                x: visibleFrame.minX + quadrantWidth + (quadrantWidth - windowSize.width) / 2,
                y: visibleFrame.minY + (quadrantHeight - windowSize.height) / 2
            )
        default:
            print("  ❌ Unknown position")
            continue
        }
        
        print("  Calculated Position: \(newPosition)")
        
        // Validate the position is within expected quadrant
        let isValid = validateQuadrantPosition(position: position, 
                                               calculatedPoint: newPosition,
                                               windowSize: windowSize,
                                               visibleFrame: visibleFrame,
                                               quadrantWidth: quadrantWidth,
                                               quadrantHeight: quadrantHeight)
        
        print("  Validation: \(isValid ? "✅ PASS" : "❌ FAIL")")
        print("")
    }
}

func validateQuadrantPosition(position: String, 
                              calculatedPoint: CGPoint, 
                              windowSize: CGSize,
                              visibleFrame: CGRect,
                              quadrantWidth: CGFloat,
                              quadrantHeight: CGFloat) -> Bool {
    
    let windowRect = CGRect(origin: calculatedPoint, size: windowSize)
    
    switch position {
    case "top_left":
        let quadrantRect = CGRect(x: visibleFrame.minX, 
                                  y: visibleFrame.minY + quadrantHeight,
                                  width: quadrantWidth, 
                                  height: quadrantHeight)
        return quadrantRect.contains(windowRect)
        
    case "top_right":
        let quadrantRect = CGRect(x: visibleFrame.minX + quadrantWidth, 
                                  y: visibleFrame.minY + quadrantHeight,
                                  width: quadrantWidth, 
                                  height: quadrantHeight)
        return quadrantRect.contains(windowRect)
        
    case "bottom_left":
        let quadrantRect = CGRect(x: visibleFrame.minX, 
                                  y: visibleFrame.minY,
                                  width: quadrantWidth, 
                                  height: quadrantHeight)
        return quadrantRect.contains(windowRect)
        
    case "bottom_right":
        let quadrantRect = CGRect(x: visibleFrame.minX + quadrantWidth, 
                                  y: visibleFrame.minY,
                                  width: quadrantWidth, 
                                  height: quadrantHeight)
        return quadrantRect.contains(windowRect)
        
    default:
        return false
    }
}

// Run the test
testPositioningLogic()

print("=== Coordinate System Analysis ===")
print("Cocoa Coordinate System:")
print("  - Origin at bottom-left")
print("  - Y increases upward") 
print("  - Visible frame accounts for menu bar/dock")
print("")
print("Quartz Coordinate System:") 
print("  - Origin at top-left")
print("  - Y increases downward")
print("  - Used for window positioning")
print("")
print("Coordinate transformation is handled by CoordinateManager")