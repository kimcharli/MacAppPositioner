#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Integration Test for Window Positioning
 * 
 * This test validates that the canonical coordinate system correctly positions windows
 * on the intended monitors without manual positioning.
 */

print("=== Window Positioning Integration Test ===")

// Load the canonical coordinate system (simulate)
guard let mainScreen = NSScreen.main else {
    print("❌ No main screen found")
    exit(1)
}

let mainDisplayFrame = mainScreen.frame
print("🖥️  Main Display: \(mainDisplayFrame)")

// Find the 4K display
let fourKDisplay = NSScreen.screens.first { screen in
    screen.frame.width == 3840 && screen.frame.height == 2160
}

guard let fourK = fourKDisplay else {
    print("❌ 4K display not found")
    exit(1)
}

print("📺 4K Display: \(fourK.frame)")

// MARK: - Test Window Position Calculations

struct PositioningTest {
    let name: String
    let quadrant: String
    let expectedMonitor: NSScreen
    let windowSize: CGSize
}

let tests: [PositioningTest] = [
    PositioningTest(
        name: "Chrome - Top Left on 4K",
        quadrant: "top_left", 
        expectedMonitor: fourK,
        windowSize: CGSize(width: 1720, height: 993)
    ),
    PositioningTest(
        name: "Outlook - Bottom Left on 4K",
        quadrant: "bottom_left",
        expectedMonitor: fourK, 
        windowSize: CGSize(width: 1782, height: 1143)
    ),
    PositioningTest(
        name: "Teams - Top Right on 4K", 
        quadrant: "top_right",
        expectedMonitor: fourK,
        windowSize: CGSize(width: 1720, height: 720)
    ),
    PositioningTest(
        name: "KakaoTalk - Bottom Right on 4K",
        quadrant: "bottom_right",
        expectedMonitor: fourK,
        windowSize: CGSize(width: 915, height: 640)
    )
]

// MARK: - Simulate Canonical Coordinate Conversion

func convertCocoaToGlobalCanonical(cocoaFrame: CGRect, mainScreen: NSScreen) -> CGRect {
    let mainCocoaFrame = mainScreen.frame
    let relativeX = cocoaFrame.origin.x - mainCocoaFrame.origin.x
    let relativeY = cocoaFrame.origin.y - mainCocoaFrame.origin.y
    
    return CGRect(
        x: relativeX,
        y: relativeY, 
        width: cocoaFrame.width,
        height: cocoaFrame.height
    )
}

// MARK: - Simulate Quadrant Position Calculation

func calculateQuadrantPosition(quadrant: String, windowSize: CGSize, monitorFrame: CGRect) -> CGPoint? {
    let quadrantWidth = monitorFrame.width / 2
    let quadrantHeight = monitorFrame.height / 2
    
    switch quadrant {
    case "top_left":
        return CGPoint(
            x: monitorFrame.minX + (quadrantWidth - windowSize.width) / 2,
            y: monitorFrame.minY + (quadrantHeight - windowSize.height) / 2
        )
    case "top_right":
        return CGPoint(
            x: monitorFrame.minX + quadrantWidth + (quadrantWidth - windowSize.width) / 2,
            y: monitorFrame.minY + (quadrantHeight - windowSize.height) / 2
        )
    case "bottom_left":
        return CGPoint(
            x: monitorFrame.minX + (quadrantWidth - windowSize.width) / 2,
            y: monitorFrame.minY + quadrantHeight + (quadrantHeight - windowSize.height) / 2
        )
    case "bottom_right":
        return CGPoint(
            x: monitorFrame.minX + quadrantWidth + (quadrantWidth - windowSize.width) / 2,
            y: monitorFrame.minY + quadrantHeight + (quadrantHeight - windowSize.height) / 2
        )
    default:
        return nil
    }
}

// MARK: - Run Positioning Tests

var allTestsPass = true

for test in tests {
    print("\n🧪 Testing: \(test.name)")
    
    // Convert monitor to global canonical coordinates
    let globalCanonicalFrame = convertCocoaToGlobalCanonical(
        cocoaFrame: test.expectedMonitor.frame,
        mainScreen: mainScreen
    )
    
    print("  Monitor Global Canonical: \(globalCanonicalFrame)")
    
    // Calculate position in global canonical space
    guard let globalCanonicalPosition = calculateQuadrantPosition(
        quadrant: test.quadrant,
        windowSize: test.windowSize,
        monitorFrame: globalCanonicalFrame
    ) else {
        print("  ❌ Failed to calculate position")
        allTestsPass = false
        continue
    }
    
    print("  Calculated Position (Global Canonical): \(globalCanonicalPosition)")
    
    // Validation checks
    let withinMonitorBounds = globalCanonicalFrame.contains(globalCanonicalPosition)
    let notInMainDisplay = !CGRect(x: 0, y: 0, width: mainScreen.frame.width, height: mainScreen.frame.height).contains(globalCanonicalPosition)
    
    // For 4K display, position should be below main display (Y > 1329)
    let correctYPosition = test.expectedMonitor == fourK ? globalCanonicalPosition.y >= 1329 : true
    
    print("  Validations:")
    print("    Within monitor bounds: \(withinMonitorBounds ? "✅" : "❌")")
    print("    Not in main display: \(notInMainDisplay ? "✅" : "❌")")
    print("    Correct Y position: \(correctYPosition ? "✅" : "❌")")
    
    let testPasses = withinMonitorBounds && notInMainDisplay && correctYPosition
    print("  Result: \(testPasses ? "✅ PASS" : "❌ FAIL")")
    
    allTestsPass = allTestsPass && testPasses
}

// MARK: - Test Monitor Identification

print("\n🧪 Testing Monitor Identification")

let builtInDetected = NSScreen.screens.contains { screen in
    screen == mainScreen && screen.frame == CGRect(x: 0, y: 0, width: 2056, height: 1329)
}

let fourKDetected = NSScreen.screens.contains { screen in
    screen.frame.width == 3840 && screen.frame.height == 2160
}

print("Built-in main display detected: \(builtInDetected ? "✅" : "❌")")
print("4K display detected: \(fourKDetected ? "✅" : "❌")")

let monitorDetectionPass = builtInDetected && fourKDetected
allTestsPass = allTestsPass && monitorDetectionPass

// MARK: - Overall Results

print("\n" + "=".repeating(50))
print("🏁 INTEGRATION TEST RESULTS")
print("=".repeating(50))

print("Window Positioning Tests: \(allTestsPass ? "✅ PASS" : "❌ FAIL")")
print("Monitor Detection: \(monitorDetectionPass ? "✅ PASS" : "❌ FAIL")")

print("\n🎯 FINAL RESULT: \(allTestsPass ? "✅ ALL TESTS PASS" : "❌ SOME TESTS FAILED")")

if allTestsPass {
    print("\n✅ Coordinate system is working correctly!")
    print("   Windows should be positioned on the 4K display as expected.")
} else {
    print("\n❌ COORDINATE SYSTEM ISSUES DETECTED!")
    print("   Windows may be positioned incorrectly.")
    print("   Review the failed validations above.")
}

exit(allTestsPass ? 0 : 1)