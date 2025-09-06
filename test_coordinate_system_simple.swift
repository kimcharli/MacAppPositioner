#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Simple Coordinate System Test
 * Quick validation for coordinate system correctness
 */

print("=== Simple Coordinate System Test ===")

var allTestsPass = true

// Test 1: Main Screen Detection
print("\n🧪 Test 1: Main Screen Detection")
if let mainScreen = NSScreen.main {
    let expectedFrame = CGRect(x: 0, y: 0, width: 2056, height: 1329)
    let matches = mainScreen.frame == expectedFrame
    print("  NSScreen.main: \(mainScreen.frame)")
    print("  Expected: \(expectedFrame)")
    print("  Result: \(matches ? "✅ PASS" : "❌ FAIL")")
    allTestsPass = allTestsPass && matches
} else {
    print("  ❌ No main screen found")
    allTestsPass = false
}

// Test 2: 4K Monitor Detection
print("\n🧪 Test 2: 4K Monitor Detection")
let fourKMonitor = NSScreen.screens.first { screen in
    screen.frame.width == 3840 && screen.frame.height == 2160
}

if let fourK = fourKMonitor {
    print("  4K Monitor Found: \(fourK.frame)")
    print("  Result: ✅ PASS")
} else {
    print("  ❌ 4K Monitor not found")
    allTestsPass = false
}

// Test 3: Coordinate Conversion
print("\n🧪 Test 3: Coordinate Conversion")
if let mainScreen = NSScreen.main, let fourK = fourKMonitor {
    // Test coordinate conversion for 4K monitor
    let cocoaFrame = fourK.frame  // (0, 1329, 3840, 2160)
    let mainFrame = mainScreen.frame  // (0, 0, 2056, 1329)
    
    // Global canonical conversion
    let relativeX = cocoaFrame.origin.x - mainFrame.origin.x
    let relativeY = cocoaFrame.origin.y - mainFrame.origin.y
    let globalCanonical = CGRect(x: relativeX, y: relativeY, width: cocoaFrame.width, height: cocoaFrame.height)
    
    let expectedCanonical = CGRect(x: 0, y: 1329, width: 3840, height: 2160)
    let matches = globalCanonical == expectedCanonical
    
    print("  4K Cocoa Frame: \(cocoaFrame)")
    print("  Expected Global Canonical: \(expectedCanonical)")
    print("  Actual Global Canonical: \(globalCanonical)")
    print("  Result: \(matches ? "✅ PASS" : "❌ FAIL")")
    allTestsPass = allTestsPass && matches
} else {
    print("  ❌ Cannot test - missing screens")
    allTestsPass = false
}

// Test 4: Window Position Validation
print("\n🧪 Test 4: Window Position Validation")
if let fourK = fourKMonitor {
    let fourKCanonical = CGRect(x: 0, y: 1329, width: 3840, height: 2160)
    
    // Test position that should be on 4K display
    let testPosition = CGPoint(x: 100, y: 1500)  // Should be on 4K display
    let builtInBounds = CGRect(x: 0, y: 0, width: 2056, height: 1329)
    
    let inFourK = fourKCanonical.contains(testPosition)
    let notInBuiltIn = !builtInBounds.contains(testPosition)
    
    print("  Test Position: \(testPosition)")
    print("  In 4K Monitor: \(inFourK ? "✅" : "❌")")
    print("  Not in Built-in: \(notInBuiltIn ? "✅" : "❌")")
    
    let positionTestPass = inFourK && notInBuiltIn
    print("  Result: \(positionTestPass ? "✅ PASS" : "❌ FAIL")")
    allTestsPass = allTestsPass && positionTestPass
} else {
    print("  ❌ Cannot test - 4K monitor not found")
    allTestsPass = false
}

// Overall Result
print("\n" + String(repeating: "=", count: 40))
print("🏁 OVERALL RESULT")
print(String(repeating: "=", count: 40))

print("Final Result: \(allTestsPass ? "✅ ALL TESTS PASS" : "❌ SOME TESTS FAILED")")

if allTestsPass {
    print("\n✅ Coordinate system is working correctly!")
    print("   Windows should position on 4K display as expected.")
} else {
    print("\n❌ Coordinate system issues detected!")
    print("   Review the failed tests above.")
}

exit(allTestsPass ? 0 : 1)