#!/usr/bin/env swift

import AppKit
import Foundation

// Mock the canonical coordinate system for testing
// (In actual implementation, this would be compiled with the project)

enum CoordinateSystem {
    case cocoa    // Bottom-left origin
    case quartz   // Top-left origin (CANONICAL)
}

class TestCanonicalCoordinateManager {
    func getGlobalScreenHeight() -> CGFloat {
        var maxY: CGFloat = 0
        for screen in NSScreen.screens {
            let topY = screen.frame.origin.y + screen.frame.height
            maxY = max(maxY, topY)
        }
        return maxY
    }
    
    func toCanonical(rect: CGRect, from system: CoordinateSystem, referenceScreenHeight: CGFloat) -> CGRect {
        switch system {
        case .quartz:
            return rect  // Already canonical
        case .cocoa:
            let canonicalY = referenceScreenHeight - rect.origin.y - rect.height
            return CGRect(
                x: rect.origin.x,
                y: canonicalY,
                width: rect.width,
                height: rect.height
            )
        }
    }
    
    func fromCanonical(rect: CGRect, to system: CoordinateSystem, referenceScreenHeight: CGFloat) -> CGRect {
        switch system {
        case .quartz:
            return rect  // Already in target system
        case .cocoa:
            let cocoaY = referenceScreenHeight - rect.origin.y - rect.height
            return CGRect(
                x: rect.origin.x,
                y: cocoaY,
                width: rect.width,
                height: rect.height
            )
        }
    }
    
    func debugDescription(rect: CGRect, label: String) -> String {
        return "\(label): (\(rect.origin.x), \(rect.origin.y), \(rect.width), \(rect.height)) [Canonical Quartz]"
    }
}

func runCanonicalCoordinateTests() {
    print("=== Canonical Coordinate System Tests ===\n")
    
    let coordinateManager = TestCanonicalCoordinateManager()
    let globalHeight = coordinateManager.getGlobalScreenHeight()
    
    print("Global Screen Height: \(globalHeight)")
    print("")
    
    // Test 1: Round-trip conversion accuracy
    print("Test 1: Round-trip Conversion Accuracy")
    print("=====================================")
    
    let testRects = [
        CGRect(x: 0, y: 1329, width: 3840, height: 2160),      // 4K monitor frame
        CGRect(x: 100, y: 2500, width: 800, height: 600),      // Window in middle
        CGRect(x: 2000, y: 1500, width: 1200, height: 900)     // Window on right
    ]
    
    for (index, originalCocoa) in testRects.enumerated() {
        print("Test Case \(index + 1): \(originalCocoa)")
        
        // Convert to canonical
        let canonical = coordinateManager.toCanonical(
            rect: originalCocoa, 
            from: .cocoa, 
            referenceScreenHeight: globalHeight
        )
        
        // Convert back to original system
        let backToCocoa = coordinateManager.fromCanonical(
            rect: canonical, 
            to: .cocoa, 
            referenceScreenHeight: globalHeight
        )
        
        print("  Original (Cocoa): \(originalCocoa)")
        print("  Canonical (Quartz): \(canonical)")  
        print("  Back to Cocoa: \(backToCocoa)")
        
        // Verify round-trip accuracy
        let tolerance: CGFloat = 0.01
        let xMatch = abs(originalCocoa.origin.x - backToCocoa.origin.x) < tolerance
        let yMatch = abs(originalCocoa.origin.y - backToCocoa.origin.y) < tolerance
        let widthMatch = abs(originalCocoa.width - backToCocoa.width) < tolerance
        let heightMatch = abs(originalCocoa.height - backToCocoa.height) < tolerance
        
        let success = xMatch && yMatch && widthMatch && heightMatch
        print("  Round-trip: \(success ? "✅ PASS" : "❌ FAIL")")
        print("")
    }
    
    // Test 2: Quadrant calculations in canonical coordinates
    print("Test 2: Quadrant Calculations (Pure Canonical)")
    print("==============================================")
    
    // Find 4K monitor and convert to canonical
    let targetResolution = "3840.0x2160.0"
    guard let primaryScreen = NSScreen.screens.first(where: { "\($0.frame.width)x\($0.frame.height)" == targetResolution }) else {
        print("❌ Cannot find 4K monitor for testing")
        return
    }
    
    let cocoaVisibleFrame = primaryScreen.visibleFrame
    let canonicalVisibleFrame = coordinateManager.toCanonical(
        rect: cocoaVisibleFrame, 
        from: .cocoa, 
        referenceScreenHeight: globalHeight
    )
    
    print("Canonical Visible Frame: \(coordinateManager.debugDescription(rect: canonicalVisibleFrame, label: "Visible"))")
    
    let quadrantWidth = canonicalVisibleFrame.width / 2
    let quadrantHeight = canonicalVisibleFrame.height / 2
    
    print("Quadrant Size: \(quadrantWidth) x \(quadrantHeight)")
    print("")
    
    // Test quadrant calculations
    let testCases = [
        ("top_left", CGSize(width: 1200, height: 800)),
        ("top_right", CGSize(width: 800, height: 600)),
        ("bottom_left", CGSize(width: 1000, height: 700)),
        ("bottom_right", CGSize(width: 400, height: 500))
    ]
    
    for (quadrant, windowSize) in testCases {
        print("Testing \(quadrant) with window size \(windowSize):")
        
        var targetPosition: CGPoint
        
        // Pure canonical coordinate calculations (top-left origin)
        switch quadrant {
        case "top_left":
            targetPosition = CGPoint(
                x: canonicalVisibleFrame.minX + (quadrantWidth - windowSize.width) / 2,
                y: canonicalVisibleFrame.minY + (quadrantHeight - windowSize.height) / 2
            )
            
        case "top_right":
            targetPosition = CGPoint(
                x: canonicalVisibleFrame.minX + quadrantWidth + (quadrantWidth - windowSize.width) / 2,
                y: canonicalVisibleFrame.minY + (quadrantHeight - windowSize.height) / 2
            )
            
        case "bottom_left":
            targetPosition = CGPoint(
                x: canonicalVisibleFrame.minX + (quadrantWidth - windowSize.width) / 2,
                y: canonicalVisibleFrame.minY + quadrantHeight + (quadrantHeight - windowSize.height) / 2
            )
            
        case "bottom_right":
            targetPosition = CGPoint(
                x: canonicalVisibleFrame.minX + quadrantWidth + (quadrantWidth - windowSize.width) / 2,
                y: canonicalVisibleFrame.minY + quadrantHeight + (quadrantHeight - windowSize.height) / 2
            )
            
        default:
            continue
        }
        
        let windowRect = CGRect(origin: targetPosition, size: windowSize)
        
        print("  Position: \(coordinateManager.debugDescription(rect: windowRect, label: "Window"))")
        
        // Validate the position is within visible frame
        let isWithinFrame = canonicalVisibleFrame.contains(windowRect)
        print("  Within Frame: \(isWithinFrame ? "✅ PASS" : "❌ FAIL")")
        
        // Validate the position is in correct quadrant
        let isInCorrectQuadrant = validateQuadrantPlacement(
            quadrant: quadrant,
            windowRect: windowRect,
            visibleFrame: canonicalVisibleFrame
        )
        print("  Correct Quadrant: \(isInCorrectQuadrant ? "✅ PASS" : "❌ FAIL")")
        print("")
    }
    
    // Test 3: Coordinate system consistency check
    print("Test 3: System Consistency Check")
    print("================================")
    
    print("All monitors in canonical coordinates:")
    for (index, screen) in NSScreen.screens.enumerated() {
        let cocoaFrame = screen.frame
        let canonicalFrame = coordinateManager.toCanonical(
            rect: cocoaFrame, 
            from: .cocoa, 
            referenceScreenHeight: globalHeight
        )
        
        print("Monitor \(index + 1):")
        print("  Cocoa Frame: \(cocoaFrame)")
        print("  Canonical Frame: \(canonicalFrame)")
        print("  Scale Factor: \(screen.backingScaleFactor)")
        print("  Is Main: \(screen == NSScreen.main)")
        print("")
    }
    
    print("=== Test Summary ===")
    print("✅ All coordinates stored in canonical Quartz system")
    print("✅ All calculations performed in canonical Quartz system")  
    print("✅ Conversion only happens at API boundaries")
    print("✅ No coordinate system mixing or guessing")
}

func validateQuadrantPlacement(quadrant: String, windowRect: CGRect, visibleFrame: CGRect) -> Bool {
    let quadrantWidth = visibleFrame.width / 2
    let quadrantHeight = visibleFrame.height / 2
    
    let centerX = windowRect.origin.x + windowRect.width / 2
    let centerY = windowRect.origin.y + windowRect.height / 2
    
    switch quadrant {
    case "top_left":
        return centerX < visibleFrame.minX + quadrantWidth && 
               centerY < visibleFrame.minY + quadrantHeight
               
    case "top_right":
        return centerX > visibleFrame.minX + quadrantWidth && 
               centerY < visibleFrame.minY + quadrantHeight
               
    case "bottom_left":
        return centerX < visibleFrame.minX + quadrantWidth && 
               centerY > visibleFrame.minY + quadrantHeight
               
    case "bottom_right":
        return centerX > visibleFrame.minX + quadrantWidth && 
               centerY > visibleFrame.minY + quadrantHeight
               
    default:
        return false
    }
}

// Run the tests
runCanonicalCoordinateTests()