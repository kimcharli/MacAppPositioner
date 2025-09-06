#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Chrome Positioning Test - Fixed with proper offset handling
 */

print("=== Chrome Positioning Test (Fixed) ===")

// Target position: top-left corner of primary screen, accounting for menu bar and title bar
let menuBarHeight: CGFloat = 25  // Standard macOS menu bar
let titleBarHeight: CGFloat = 28  // Standard window title bar
let margin: CGFloat = 50  // Distance from edge

// Adjust target position to account for menu bar and title bar
let targetGlobalCanonical = CGPoint(x: margin, y: margin + menuBarHeight + titleBarHeight)

print("Target position (Global Canonical, accounting for bars): \(targetGlobalCanonical)")

// Find Chrome
let workspace = NSWorkspace.shared
let runningApps = workspace.runningApplications
guard let chromeApp = runningApps.first(where: { $0.bundleIdentifier == "com.google.Chrome" }) else {
    print("❌ Chrome not running")
    exit(1)
}

print("✅ Found Chrome app")

// Get Chrome window
let app = AXUIElementCreateApplication(chromeApp.processIdentifier)
var windowsRef: CFTypeRef?
let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)

guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
    print("❌ No Chrome windows found")
    exit(1)
}

let window = windows[0]

// Get current position
var currentPosRef: CFTypeRef?
AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &currentPosRef)

if let posRef = currentPosRef, CFGetTypeID(posRef) == AXValueGetTypeID() {
    var currentPos = CGPoint.zero
    AXValueGetValue(posRef as! AXValue, .cgPoint, &currentPos)
    print("Current Chrome position: \(currentPos)")
}

// Find the 4K screen
guard let primaryScreen = NSScreen.screens.first(where: { screen in
    screen.frame.width == 3840 && screen.frame.height == 2160
}) else {
    print("❌ 4K primary screen not found")
    exit(1)
}

print("✅ Found 4K primary screen: \(primaryScreen.frame)")

// Convert to Cocoa coordinates
let cocoaX = primaryScreen.frame.origin.x + targetGlobalCanonical.x
let cocoaY = primaryScreen.frame.origin.y + targetGlobalCanonical.y
let targetCocoaPosition = CGPoint(x: cocoaX, y: cocoaY)

print("Target position (Cocoa coordinates): \(targetCocoaPosition)")

// Position the window
var mutablePosition = targetCocoaPosition
let positionValue = AXValueCreate(.cgPoint, &mutablePosition)!
let setResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)

print("Accessibility API result: \(setResult == .success ? "SUCCESS" : "FAILED")")

// Wait and check result
Thread.sleep(forTimeInterval: 0.5)

var newPosRef: CFTypeRef?
AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &newPosRef)

if let posRef = newPosRef, CFGetTypeID(posRef) == AXValueGetTypeID() {
    var newPos = CGPoint.zero
    AXValueGetValue(posRef as! AXValue, .cgPoint, &newPos)
    print("New Chrome position: \(newPos)")
    
    let deltaX = abs(newPos.x - targetCocoaPosition.x)
    let deltaY = abs(newPos.y - targetCocoaPosition.y)
    
    print("Position delta: X=\(deltaX), Y=\(deltaY)")
    
    if deltaX < 20 && deltaY < 20 {
        print("✅ SUCCESS: Chrome positioned at top-left corner of primary screen!")
        
        // Verify it's actually on the 4K display
        let onPrimaryScreen = newPos.y >= primaryScreen.frame.origin.y && 
                             newPos.y < primaryScreen.frame.maxY &&
                             newPos.x >= primaryScreen.frame.origin.x && 
                             newPos.x < primaryScreen.frame.maxX
                             
        if onPrimaryScreen {
            print("✅ CONFIRMED: Chrome is on the 4K primary screen")
        } else {
            print("❌ WARNING: Chrome may not be on the correct screen")
        }
    } else {
        print("❌ POSITIONING FAILED: Chrome not at target position")
        
        // If Y is still off, try adjusting for actual menu bar height
        if deltaY > 20 {
            print("\n🧪 Adjusting for actual menu bar height...")
            let adjustedY = cocoaY - (newPos.y - cocoaY)  // Compensate for the offset
            let adjustedTarget = CGPoint(x: cocoaX, y: adjustedY)
            
            var adjustedMutablePosition = adjustedTarget
            let adjustedPositionValue = AXValueCreate(.cgPoint, &adjustedMutablePosition)!
            let adjustedSetResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, adjustedPositionValue)
            
            print("Adjusted target: \(adjustedTarget)")
            print("Adjusted API result: \(adjustedSetResult == .success ? "SUCCESS" : "FAILED")")
            
            Thread.sleep(forTimeInterval: 0.5)
            
            var finalPosRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &finalPosRef)
            
            if let posRef = finalPosRef, CFGetTypeID(posRef) == AXValueGetTypeID() {
                var finalPos = CGPoint.zero
                AXValueGetValue(posRef as! AXValue, .cgPoint, &finalPos)
                print("Final Chrome position: \(finalPos)")
                
                let finalDeltaX = abs(finalPos.x - adjustedTarget.x)
                let finalDeltaY = abs(finalPos.y - adjustedTarget.y)
                
                if finalDeltaX < 20 && finalDeltaY < 20 {
                    print("✅ SUCCESS: Adjusted positioning worked!")
                } else {
                    print("❌ Adjusted positioning also failed. Delta: X=\(finalDeltaX), Y=\(finalDeltaY)")
                }
            }
        }
    }
}