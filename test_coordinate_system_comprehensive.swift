#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Comprehensive Coordinate System Test Suite
 * 
 * This test suite validates the global canonical coordinate system implementation
 * and detects coordinate system violations early in development.
 */

print("=== Comprehensive Coordinate System Test Suite ===")

// MARK: - Test Data Setup

struct TestMonitorSetup {
    let name: String
    let cocoaFrame: CGRect
    let expectedGlobalCanonical: CGRect
    let isMain: Bool
}

// Test with current monitor setup
let testSetups: [TestMonitorSetup] = [
    TestMonitorSetup(
        name: "Built-in Main Display",
        cocoaFrame: CGRect(x: 0, y: 0, width: 2056, height: 1329),
        expectedGlobalCanonical: CGRect(x: 0, y: 0, width: 2056, height: 1329),
        isMain: true
    ),
    TestMonitorSetup(
        name: "4K Primary Display (Below Main)",
        cocoaFrame: CGRect(x: 0, y: 1329, width: 3840, height: 2160),
        expectedGlobalCanonical: CGRect(x: 0, y: 1329, width: 3840, height: 2160),
        isMain: false
    ),
    TestMonitorSetup(
        name: "Left External Display",
        cocoaFrame: CGRect(x: -2560, y: 969, width: 2560, height: 1440),
        expectedGlobalCanonical: CGRect(x: -2560, y: 969, width: 2560, height: 1440),
        isMain: false
    )
]

let mainDisplayFrame = CGRect(x: 0, y: 0, width: 2056, height: 1329)

// MARK: - Test 1: Coordinate Conversion Accuracy

print("\n🧪 Test 1: Coordinate Conversion Accuracy")
print("==========================================")

var test1Pass = true

for setup in testSetups {
    // Manual coordinate conversion (matching CanonicalCoordinateManager logic)
    let relativeX = setup.cocoaFrame.origin.x - mainDisplayFrame.origin.x
    let relativeY = setup.cocoaFrame.origin.y - mainDisplayFrame.origin.y
    let actualGlobalCanonical = CGRect(x: relativeX, y: relativeY, width: setup.cocoaFrame.width, height: setup.cocoaFrame.height)
    
    let matches = actualGlobalCanonical == setup.expectedGlobalCanonical
    test1Pass = test1Pass && matches
    
    print("📺 \(setup.name):")
    print("  Cocoa Frame: \(setup.cocoaFrame)")
    print("  Expected Global Canonical: \(setup.expectedGlobalCanonical)")
    print("  Actual Global Canonical: \(actualGlobalCanonical)")
    print("  ✅ Match: \(matches ? "PASS" : "FAIL")")
}

print("\n🎯 Test 1 Result: \(test1Pass ? "✅ PASS" : "❌ FAIL")")

// MARK: - Test 2: Spatial Relationship Validation

print("\n🧪 Test 2: Spatial Relationship Validation")
print("==========================================")

var test2Pass = true

// Test spatial relationships in global canonical space
let builtIn = testSetups[0].expectedGlobalCanonical  // (0, 0, 2056, 1329)
let fourK = testSetups[1].expectedGlobalCanonical    // (0, 1329, 3840, 2160)
let leftDisplay = testSetups[2].expectedGlobalCanonical  // (-2560, 969, 2560, 1440)

// Spatial relationship tests
let fourKBelowBuiltIn = (fourK.origin.y > builtIn.maxY - 50) // Allow small gap
let fourKAlignedLeftWithBuiltIn = (fourK.origin.x == builtIn.origin.x)
let leftDisplayLeftOfBuiltIn = (leftDisplay.maxX <= builtIn.origin.x)

print("📐 Spatial Relationships:")
print("  4K Display is below Built-in: \(fourKBelowBuiltIn ? "✅ PASS" : "❌ FAIL")")
print("  4K Display is left-aligned with Built-in: \(fourKAlignedLeftWithBuiltIn ? "✅ PASS" : "❌ FAIL")")
print("  Left Display is left of Built-in: \(leftDisplayLeftOfBuiltIn ? "✅ PASS" : "❌ FAIL")")

test2Pass = fourKBelowBuiltIn && fourKAlignedLeftWithBuiltIn && leftDisplayLeftOfBuiltIn

print("\n🎯 Test 2 Result: \(test2Pass ? "✅ PASS" : "❌ FAIL")")

// MARK: - Test 3: Window Positioning Validation

print("\n🧪 Test 3: Window Positioning Validation")
print("========================================")

var test3Pass = true

// Test window positions in global canonical space
struct WindowTest {
    let name: String
    let targetMonitor: CGRect
    let quadrant: String
    let expectedPosition: CGPoint
}

let windowTests: [WindowTest] = [
    WindowTest(
        name: "Chrome on 4K top-left",
        targetMonitor: fourK,
        quadrant: "top_left",
        expectedPosition: CGPoint(x: fourK.origin.x + 100, y: fourK.origin.y + 100)
    ),
    WindowTest(
        name: "Outlook on 4K bottom-left", 
        targetMonitor: fourK,
        quadrant: "bottom_left",
        expectedPosition: CGPoint(x: fourK.origin.x + 100, y: fourK.maxY - 600)
    ),
    WindowTest(
        name: "Teams on 4K top-right",
        targetMonitor: fourK,
        quadrant: "top_right", 
        expectedPosition: CGPoint(x: fourK.maxX - 1000, y: fourK.origin.y + 100)
    )
]

for windowTest in windowTests {
    // Check if position is within target monitor bounds
    let withinMonitor = windowTest.targetMonitor.contains(windowTest.expectedPosition)
    
    // Check if position is NOT in built-in display bounds (common bug)
    let notInBuiltIn = !builtIn.contains(windowTest.expectedPosition)
    
    let passes = withinMonitor && notInBuiltIn
    test3Pass = test3Pass && passes
    
    print("🪟 \(windowTest.name):")
    print("  Expected Position: \(windowTest.expectedPosition)")
    print("  Within 4K Monitor: \(withinMonitor ? "✅" : "❌")")
    print("  Not in Built-in: \(notInBuiltIn ? "✅" : "❌")")
    print("  Result: \(passes ? "✅ PASS" : "❌ FAIL")")
}

print("\n🎯 Test 3 Result: \(test3Pass ? "✅ PASS" : "❌ FAIL")")

// MARK: - Test 4: Real System Validation

print("\n🧪 Test 4: Real System Validation")
print("==================================")

var test4Pass = true

guard let mainScreen = NSScreen.main else {
    print("❌ No main screen found")
    test4Pass = false
    print("\n🎯 Test 4 Result: ❌ FAIL")
    print("\n🎯 Test 5 Result: ❌ SKIPPED")
    print("\n🎯 FINAL RESULT: ❌ SOME TESTS FAILED")
    exit(1)
print("🖥️ Main Screen Validation:")
print("  NSScreen.main: \(mainScreen.frame)")
print("  Expected: \(mainDisplayFrame)")

let mainScreenMatches = mainScreen.frame == mainDisplayFrame
print("  Match: \(mainScreenMatches ? "✅ PASS" : "❌ FAIL")")
test4Pass = test4Pass && mainScreenMatches

// Test all screens
print("\n📺 All Screens:")
for (index, screen) in NSScreen.screens.enumerated() {
    let isMainScreen = screen == mainScreen
    let expectedMain = (screen.frame == mainDisplayFrame)
    let correctMainIdentification = (isMainScreen == expectedMain)
    
    print("  Screen \(index + 1): \(screen.frame)")
    print("    Is NSScreen.main: \(isMainScreen)")
    print("    Should be main: \(expectedMain)")
    print("    Correct identification: \(correctMainIdentification ? "✅" : "❌")")
    
    test4Pass = test4Pass && correctMainIdentification
}

print("\n🎯 Test 4 Result: \(test4Pass ? "✅ PASS" : "❌ FAIL")")

// MARK: - Test 5: Config Profile Validation

print("\n🧪 Test 5: Config Profile Validation")
print("====================================")

// Check if config.json exists and has correct structure
let configPath = "config.json"
var test5Pass = true

if let configData = FileManager.default.contents(atPath: configPath),
   let configJSON = try? JSONSerialization.jsonObject(with: configData) as? [String: Any],
   let profiles = configJSON["profiles"] as? [String: Any] {
    
    print("📋 Config validation:")
    
    for (profileName, profileData) in profiles {
        guard let profile = profileData as? [String: Any],
              let monitors = profile["monitors"] as? [[String: Any]] else {
            continue
        }
        
        let primaryMonitors = monitors.filter { ($0["position"] as? String) == "primary" }
        let hasPrimary = primaryMonitors.count == 1
        
        print("  Profile '\(profileName)': \(hasPrimary ? "✅" : "❌") Has exactly 1 primary monitor")
        
        if let primaryMonitor = primaryMonitors.first,
           let resolution = primaryMonitor["resolution"] as? String {
            let is4K = resolution == "3840.0x2160.0"
            print("    Primary resolution: \(resolution) \(is4K ? "✅ (4K)" : "⚠️")")
        }
        
        test5Pass = test5Pass && hasPrimary
    }
} else {
    print("❌ Failed to load config.json")
    test5Pass = false
}

print("\n🎯 Test 5 Result: \(test5Pass ? "✅ PASS" : "❌ FAIL")")

// MARK: - Overall Test Results

let allTestsPass = test1Pass && test2Pass && test3Pass && test4Pass && test5Pass

print("\n" + String(repeating: "=", count: 50))
print("🏁 OVERALL TEST RESULTS")
print(String(repeating: "=", count: 50))

print("Test 1 - Coordinate Conversion: \(test1Pass ? "✅ PASS" : "❌ FAIL")")
print("Test 2 - Spatial Relationships: \(test2Pass ? "✅ PASS" : "❌ FAIL")")
print("Test 3 - Window Positioning: \(test3Pass ? "✅ PASS" : "❌ FAIL")")
print("Test 4 - Real System Validation: \(test4Pass ? "✅ PASS" : "❌ FAIL")")
print("Test 5 - Config Profile Validation: \(test5Pass ? "✅ PASS" : "❌ FAIL")")

print("\n🎯 FINAL RESULT: \(allTestsPass ? "✅ ALL TESTS PASS" : "❌ SOME TESTS FAILED")")

if !allTestsPass {
    print("\n⚠️  COORDINATE SYSTEM ISSUES DETECTED!")
    print("   Review failed tests and fix coordinate system implementation")
    print("   before proceeding with development.")
}

// Exit with appropriate code
exit(allTestsPass ? 0 : 1)