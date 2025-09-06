#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Coordinate Conversion Debug Test
 * Analyzes the coordinate conversion bug in detail
 */

print("=== Coordinate Conversion Debug Test ===")

guard let mainScreen = NSScreen.main else {
    print("❌ No main screen found")
    exit(1)
}

print("\n📺 Screen Information:")
for (i, screen) in NSScreen.screens.enumerated() {
    let isMain = screen == mainScreen
    print("  Screen \(i): \(screen.frame) \(isMain ? "(MAIN)" : "")")
}

print("\n🔄 Current Conversion Logic Analysis:")
print("Main screen frame: \(mainScreen.frame)")
print("Main screen origin: \(mainScreen.frame.origin)")

// Test case: position (100, 37) in global canonical space (should be on 4K monitor)
let testGlobalCanonical = CGPoint(x: 100, y: 37)
print("\nTest Global Canonical Position: \(testGlobalCanonical)")

// Current (broken) conversion
let brokenAbsoluteX = testGlobalCanonical.x + mainScreen.frame.origin.x  // + 0
let brokenAbsoluteY = testGlobalCanonical.y + mainScreen.frame.origin.y  // + 0
let brokenResult = CGPoint(x: brokenAbsoluteX, y: brokenAbsoluteY)
print("Current conversion result: \(brokenResult)")

// The issue: We need to convert to Cocoa coordinates for the target screen
// Global canonical (100, 37) should be on the 4K display
// 4K display in Cocoa coordinates: (0, 1329, 3840, 2160)
// So the correct Cocoa position should be (100, 1329 + 37) = (100, 1366)

let fourKFrame = CGRect(x: 0, y: 1329, width: 3840, height: 2160)
let correctCocoaX = testGlobalCanonical.x  // X is the same
let correctCocoaY = fourKFrame.origin.y + testGlobalCanonical.y  // Y needs 4K offset
let correctResult = CGPoint(x: correctCocoaX, y: correctCocoaY)

print("Correct conversion result: \(correctResult)")
print("\n🐛 The Bug:")
print("  Current: Global canonical → Cocoa = add main screen origin (0,0)")
print("  Problem: This doesn't account for the target monitor!")
print("  Fix: Convert global canonical → target monitor Cocoa coordinates")

// Test with all screens
print("\n🧪 Conversion Test for Each Monitor:")
for (i, screen) in NSScreen.screens.enumerated() {
    let correctX = testGlobalCanonical.x
    let correctY = screen.frame.origin.y + testGlobalCanonical.y
    print("  Screen \(i): Global canonical \(testGlobalCanonical) → Cocoa (\(correctX), \(correctY))")
}

print("\n✅ Solution:")
print("  The convertGlobalCanonicalToAbsoluteQuartz function needs to:")
print("  1. Determine which monitor the global canonical point is on")  
print("  2. Convert to that monitor's Cocoa coordinate space")
print("  3. Use the target monitor's origin, not the main screen's origin")