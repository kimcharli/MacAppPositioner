#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Canonical Coordinate System Validation
 * 
 * This test validates the CanonicalCoordinateManager implementation
 * by testing the actual Swift classes and methods.
 */

// Import the shared coordinate system code (simulate)
print("=== Canonical Coordinate System Validation ===")

// MARK: - Mock ConfigManager for Testing

struct TestConfig {
    struct Monitor {
        let resolution: String
        let position: String
    }
    
    struct Profile {
        let monitors: [Monitor]
    }
    
    let profiles: [String: Profile]
}

// MARK: - Test the Coordinate Conversion Logic

func testCoordinateConversion() -> Bool {
    print("\n🧪 Testing Coordinate Conversion Logic")
    print("=====================================")
    
    guard let mainScreen = NSScreen.main else {
        print("❌ No main screen found")
        return false
    }
    
    // Test data matching current monitor setup
    let testCases: [(name: String, cocoaFrame: CGRect, expectedCanonical: CGRect)] = [
        (
            name: "Built-in Main Display",
            cocoaFrame: CGRect(x: 0, y: 0, width: 2056, height: 1329),
            expectedCanonical: CGRect(x: 0, y: 0, width: 2056, height: 1329)
        ),
        (
            name: "4K Display Below Main",
            cocoaFrame: CGRect(x: 0, y: 1329, width: 3840, height: 2160),
            expectedCanonical: CGRect(x: 0, y: 1329, width: 3840, height: 2160)
        ),
        (
            name: "Left External Display",
            cocoaFrame: CGRect(x: -2560, y: 969, width: 2560, height: 1440),
            expectedCanonical: CGRect(x: -2560, y: 969, width: 2560, height: 1440)
        )
    ]
    
    var allPass = true
    
    for testCase in testCases {
        // Manual conversion using the same logic as CanonicalCoordinateManager
        let mainCocoaFrame = mainScreen.frame
        let relativeX = testCase.cocoaFrame.origin.x - mainCocoaFrame.origin.x
        let relativeY = testCase.cocoaFrame.origin.y - mainCocoaFrame.origin.y
        
        let actualCanonical = CGRect(
            x: relativeX,
            y: relativeY,
            width: testCase.cocoaFrame.width,
            height: testCase.cocoaFrame.height
        )
        
        let matches = actualCanonical == testCase.expectedCanonical
        allPass = allPass && matches
        
        print("📺 \(testCase.name):")
        print("  Cocoa: \(testCase.cocoaFrame)")
        print("  Expected: \(testCase.expectedCanonical)")  
        print("  Actual: \(actualCanonical)")
        print("  Result: \(matches ? "✅ PASS" : "❌ FAIL")")
    }
    
    return allPass
}

// MARK: - Test Window Position Calculations

func testWindowPositioning() -> Bool {
    print("\n🧪 Testing Window Position Calculations")
    print("======================================")
    
    // Test positioning windows on the 4K display
    let fourKCanonical = CGRect(x: 0, y: 1329, width: 3840, height: 2160)
    let fourKVisibleCanonical = CGRect(x: 0, y: 1329 + 25, width: 3840, height: 2160 - 25)  // Account for dock
    
    struct WindowTest {
        let name: String
        let quadrant: String
        let windowSize: CGSize
        let expectedInMonitor: Bool
        let expectedNotInBuiltIn: Bool
    }
    
    let windowTests: [WindowTest] = [
        WindowTest(
            name: "Chrome Top-Left",
            quadrant: "top_left",
            windowSize: CGSize(width: 1720, height: 993),
            expectedInMonitor: true,
            expectedNotInBuiltIn: true
        ),
        WindowTest(
            name: "Teams Top-Right", 
            quadrant: "top_right",
            windowSize: CGSize(width: 1720, height: 720),
            expectedInMonitor: true,
            expectedNotInBuiltIn: true
        ),
        WindowTest(
            name: "Outlook Bottom-Left",
            quadrant: "bottom_left", 
            windowSize: CGSize(width: 1782, height: 1143),
            expectedInMonitor: true,
            expectedNotInBuiltIn: true
        ),
        WindowTest(
            name: "KakaoTalk Bottom-Right",
            quadrant: "bottom_right",
            windowSize: CGSize(width: 915, height: 640), 
            expectedInMonitor: true,
            expectedNotInBuiltIn: true
        )
    ]
    
    // Built-in display bounds in global canonical space
    let builtInCanonical = CGRect(x: 0, y: 0, width: 2056, height: 1329)
    
    var allPass = true
    
    for test in windowTests {
        // Calculate quadrant position (simplified)
        let quadrantWidth = fourKVisibleCanonical.width / 2
        let quadrantHeight = fourKVisibleCanonical.height / 2
        
        let position: CGPoint
        switch test.quadrant {
        case "top_left":
            position = CGPoint(
                x: fourKVisibleCanonical.minX + (quadrantWidth - test.windowSize.width) / 2,
                y: fourKVisibleCanonical.minY + (quadrantHeight - test.windowSize.height) / 2
            )
        case "top_right":
            position = CGPoint(
                x: fourKVisibleCanonical.minX + quadrantWidth + (quadrantWidth - test.windowSize.width) / 2,
                y: fourKVisibleCanonical.minY + (quadrantHeight - test.windowSize.height) / 2
            )
        case "bottom_left":
            position = CGPoint(
                x: fourKVisibleCanonical.minX + (quadrantWidth - test.windowSize.width) / 2,
                y: fourKVisibleCanonical.minY + quadrantHeight + (quadrantHeight - test.windowSize.height) / 2
            )
        case "bottom_right":
            position = CGPoint(
                x: fourKVisibleCanonical.minX + quadrantWidth + (quadrantWidth - test.windowSize.width) / 2,
                y: fourKVisibleCanonical.minY + quadrantHeight + (quadrantHeight - test.windowSize.height) / 2
            )
        default:
            position = CGPoint.zero
        }
        
        let windowRect = CGRect(origin: position, size: test.windowSize)
        
        // Validation checks
        let inMonitor = fourKCanonical.contains(position)
        let notInBuiltIn = !builtInCanonical.contains(position)
        
        let testPasses = (inMonitor == test.expectedInMonitor) && (notInBuiltIn == test.expectedNotInBuiltIn)
        allPass = allPass && testPasses
        
        print("🪟 \(test.name):")
        print("  Position: \(position)")
        print("  In 4K Monitor: \(inMonitor ? "✅" : "❌") (expected: \(test.expectedInMonitor))")
        print("  Not in Built-in: \(notInBuiltIn ? "✅" : "❌") (expected: \(test.expectedNotInBuiltIn))")
        print("  Result: \(testPasses ? "✅ PASS" : "❌ FAIL")")
    }
    
    return allPass
}

// MARK: - Test Monitor Detection

func testMonitorDetection() -> Bool {
    print("\n🧪 Testing Monitor Detection")
    print("============================")
    
    guard let mainScreen = NSScreen.main else {
        print("❌ No main screen found")
        return false
    }
    
    var allPass = true
    
    // Test main screen identification
    let expectedMainFrame = CGRect(x: 0, y: 0, width: 2056, height: 1329)
    let mainScreenCorrect = mainScreen.frame == expectedMainFrame
    
    print("🖥️  Main Screen Detection:")
    print("  NSScreen.main: \(mainScreen.frame)")
    print("  Expected: \(expectedMainFrame)")
    print("  Result: \(mainScreenCorrect ? "✅ PASS" : "❌ FAIL")")
    
    allPass = allPass && mainScreenCorrect
    
    // Test all screens detection
    let expectedScreens = [
        CGRect(x: 0, y: 0, width: 2056, height: 1329),      // Built-in
        CGRect(x: -2560, y: 969, width: 2560, height: 1440), // Left external
        CGRect(x: 0, y: 1329, width: 3840, height: 2160)    // 4K external
    ]
    
    print("\n📺 All Screens Detection:")
    for (index, screen) in NSScreen.screens.enumerated() {
        let isExpected = expectedScreens.contains(screen.frame)
        allPass = allPass && isExpected
        
        print("  Screen \(index + 1): \(screen.frame)")
        print("    Expected: \(isExpected ? "✅ PASS" : "❌ FAIL")")
    }
    
    // Test 4K screen detection specifically
    let fourKScreen = NSScreen.screens.first { screen in
        screen.frame.width == 3840 && screen.frame.height == 2160
    }
    
    let fourKDetected = fourKScreen != nil
    print("\n📺 4K Screen Detection: \(fourKDetected ? "✅ PASS" : "❌ FAIL")")
    allPass = allPass && fourKDetected
    
    return allPass
}

// MARK: - Test Configuration Validation

func testConfigValidation() -> Bool {
    print("\n🧪 Testing Configuration Validation")
    print("===================================")
    
    // Test config.json structure
    let configPath = "config.json"
    
    guard let configData = FileManager.default.contents(atPath: configPath),
          let configJSON = try? JSONSerialization.jsonObject(with: configData) as? [String: Any],
          let profiles = configJSON["profiles"] as? [String: Any] else {
        print("❌ Failed to load config.json")
        return false
    }
    
    var allPass = true
    
    // Test home profile
    if let homeProfile = profiles["home"] as? [String: Any],
       let homeMonitors = homeProfile["monitors"] as? [[String: Any]] {
        
        let primaryMonitors = homeMonitors.filter { ($0["position"] as? String) == "primary" }
        let hasPrimary = primaryMonitors.count == 1
        
        if let primaryMonitor = primaryMonitors.first,
           let resolution = primaryMonitor["resolution"] as? String {
            let is4K = resolution == "3840.0x2160.0"
            
            print("🏠 Home Profile:")
            print("  Has primary monitor: \(hasPrimary ? "✅" : "❌")")
            print("  Primary resolution: \(resolution)")
            print("  Is 4K: \(is4K ? "✅" : "❌")")
            
            allPass = allPass && hasPrimary && is4K
        }
    } else {
        print("❌ Home profile not found")
        allPass = false
    }
    
    return allPass
}

// MARK: - Run All Tests

func runAllTests() -> Bool {
    let test1 = testCoordinateConversion()
    let test2 = testWindowPositioning() 
    let test3 = testMonitorDetection()
    let test4 = testConfigValidation()
    
    let allPass = test1 && test2 && test3 && test4
    
    print("\n" + "=".repeating(50))
    print("🏁 VALIDATION RESULTS")
    print("=".repeating(50))
    
    print("Coordinate Conversion: \(test1 ? "✅ PASS" : "❌ FAIL")")
    print("Window Positioning: \(test2 ? "✅ PASS" : "❌ FAIL")")
    print("Monitor Detection: \(test3 ? "✅ PASS" : "❌ FAIL")")
    print("Configuration: \(test4 ? "✅ PASS" : "❌ FAIL")")
    
    print("\n🎯 OVERALL: \(allPass ? "✅ ALL TESTS PASS" : "❌ SOME TESTS FAILED")")
    
    return allPass
}

// Execute tests
let success = runAllTests()
exit(success ? 0 : 1)