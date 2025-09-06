#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Chrome Positioning Test
 * Direct test to position Chrome at top-left of primary screen
 */

print("=== Chrome Positioning Test ===")

// Target position: top-left corner of primary screen (4K display)
// Primary screen should be at global canonical (0, 0) with size (3840, 2160)
let targetGlobalCanonical = CGPoint(x: 50, y: 50)  // 50px from top-left corner

print("Target position (Global Canonical): \(targetGlobalCanonical)")

// Find Chrome windows
let workspace = NSWorkspace.shared
let runningApps = workspace.runningApplications
guard let chromeApp = runningApps.first(where: { $0.bundleIdentifier == "com.google.Chrome" }) else {
    print("❌ Chrome not running")
    exit(1)
}

print("✅ Found Chrome app")

// Get Chrome windows using Accessibility API
let app = AXUIElementCreateApplication(chromeApp.processIdentifier)
var windowsRef: CFTypeRef?
let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)

guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
    print("❌ No Chrome windows found")
    exit(1)
}

print("✅ Found \(windows.count) Chrome window(s)")

// Get the first window
let window = windows[0]

// Get current position
var currentPosRef: CFTypeRef?
var currentSizeRef: CFTypeRef?

AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &currentPosRef)
AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &currentSizeRef)

if let posRef = currentPosRef, let sizeRef = currentSizeRef {
    var currentPos = CGPoint.zero
    var currentSize = CGSize.zero
    
    if CFGetTypeID(posRef) == AXValueGetTypeID() && CFGetTypeID(sizeRef) == AXValueGetTypeID() {
        AXValueGetValue(posRef as! AXValue, .cgPoint, &currentPos)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &currentSize)
        
        print("Current Chrome position: \(currentPos)")
        print("Current Chrome size: \(currentSize)")
    }
}

// Convert target global canonical to actual screen coordinates
// The 4K display should be at Cocoa coordinates (0, 1329, 3840, 2160)
guard let mainScreen = NSScreen.main else {
    print("❌ No main screen")
    exit(1)
}

print("\nScreen information:")
for (i, screen) in NSScreen.screens.enumerated() {
    print("  Screen \(i): \(screen.frame)")
}

// Find the 4K screen (primary screen for our layout)
guard let primaryScreen = NSScreen.screens.first(where: { screen in
    screen.frame.width == 3840 && screen.frame.height == 2160
}) else {
    print("❌ 4K primary screen not found")
    exit(1)
}

print("✅ Found 4K primary screen: \(primaryScreen.frame)")

// Convert global canonical to Cocoa coordinates for the 4K screen
let cocoaX = primaryScreen.frame.origin.x + targetGlobalCanonical.x
let cocoaY = primaryScreen.frame.origin.y + targetGlobalCanonical.y
let targetCocoaPosition = CGPoint(x: cocoaX, y: cocoaY)

print("Target position (Cocoa coordinates): \(targetCocoaPosition)")

// Try multiple positioning approaches
print("\n🧪 Attempt 1: Direct Accessibility API positioning")

var mutablePosition = targetCocoaPosition
let positionValue = AXValueCreate(.cgPoint, &mutablePosition)!
let setResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)

print("Accessibility API result: \(setResult == .success ? "SUCCESS" : "FAILED (\(setResult))")")

// Wait a moment and check position
Thread.sleep(forTimeInterval: 0.5)

// Check new position
var newPosRef: CFTypeRef?
AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &newPosRef)

if let posRef = newPosRef, CFGetTypeID(posRef) == AXValueGetTypeID() {
    var newPos = CGPoint.zero
    AXValueGetValue(posRef as! AXValue, .cgPoint, &newPos)
    print("New Chrome position: \(newPos)")
    
    let deltaX = abs(newPos.x - targetCocoaPosition.x)
    let deltaY = abs(newPos.y - targetCocoaPosition.y)
    
    if deltaX < 10 && deltaY < 10 {
        print("✅ SUCCESS: Chrome moved to target position!")
    } else {
        print("❌ FAILED: Chrome didn't move to target position")
        print("   Expected: \(targetCocoaPosition)")
        print("   Actual: \(newPos)")
        print("   Delta: (\(deltaX), \(deltaY))")
        
        // Try alternative coordinate system
        print("\n🧪 Attempt 2: Alternative coordinate conversion")
        
        // Maybe we need to use screen-relative coordinates
        let altCocoaY = primaryScreen.frame.maxY - targetGlobalCanonical.y
        let altTargetPosition = CGPoint(x: cocoaX, y: altCocoaY)
        print("Alternative target (flipped Y): \(altTargetPosition)")
        
        var altMutablePosition = altTargetPosition
        let altPositionValue = AXValueCreate(.cgPoint, &altMutablePosition)!
        let altSetResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, altPositionValue)
        
        print("Alternative API result: \(altSetResult == .success ? "SUCCESS" : "FAILED")")
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check final position
        var finalPosRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &finalPosRef)
        
        if let posRef = finalPosRef, CFGetTypeID(posRef) == AXValueGetTypeID() {
            var finalPos = CGPoint.zero
            AXValueGetValue(posRef as! AXValue, .cgPoint, &finalPos)
            print("Final Chrome position: \(finalPos)")
            
            let finalDeltaX = abs(finalPos.x - altTargetPosition.x)
            let finalDeltaY = abs(finalPos.y - altTargetPosition.y)
            
            if finalDeltaX < 10 && finalDeltaY < 10 {
                print("✅ SUCCESS: Alternative approach worked!")
            } else {
                print("❌ Both approaches failed")
            }
        }
    }
}