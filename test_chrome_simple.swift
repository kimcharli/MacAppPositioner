#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Simple Chrome test - position at very top of 4K display
 */

print("=== Simple Chrome Positioning ===")

// Find Chrome
let workspace = NSWorkspace.shared
let runningApps = workspace.runningApplications
guard let chromeApp = runningApps.first(where: { $0.bundleIdentifier == "com.google.Chrome" }) else {
    print("❌ Chrome not running")
    exit(1)
}

let app = AXUIElementCreateApplication(chromeApp.processIdentifier)
var windowsRef: CFTypeRef?
let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)

guard result == .success, let windows = windowsRef as? [AXUIElement], !windows.isEmpty else {
    print("❌ No Chrome windows found")
    exit(1)
}

let window = windows[0]

// Try positioning at the very top of 4K display
// 4K display Cocoa coordinates: (0, 1329, 3840, 2160)
let targetPosition = CGPoint(x: 50, y: 1329)  // Very top of 4K display

print("Target position (Cocoa): \(targetPosition)")

var mutablePosition = targetPosition
let positionValue = AXValueCreate(.cgPoint, &mutablePosition)!
let setResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)

print("API result: \(setResult == .success ? "SUCCESS" : "FAILED")")

Thread.sleep(forTimeInterval: 0.5)

// Check result
var newPosRef: CFTypeRef?
AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &newPosRef)

if let posRef = newPosRef, CFGetTypeID(posRef) == AXValueGetTypeID() {
    var newPos = CGPoint.zero
    AXValueGetValue(posRef as! AXValue, .cgPoint, &newPos)
    print("Actual position: \(newPos)")
    
    // Check if it's on the 4K display
    let fourKBounds = CGRect(x: 0, y: 1329, width: 3840, height: 2160)
    let isOnFourK = fourKBounds.contains(newPos)
    
    print("Is on 4K display: \(isOnFourK ? "✅ YES" : "❌ NO")")
    
    if newPos.y >= 1329 {
        print("✅ SUCCESS: Chrome is positioned on the 4K display!")
    } else {
        print("❌ Chrome is still above the 4K display (Y=\(newPos.y), 4K starts at Y=1329)")
        
        // Let's try a different approach - position much lower on the 4K display
        print("\n🧪 Trying middle of 4K display...")
        let middlePosition = CGPoint(x: 50, y: 1800)  // Middle of 4K display
        
        var middleMutablePosition = middlePosition
        let middlePositionValue = AXValueCreate(.cgPoint, &middleMutablePosition)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, middlePositionValue)
        
        Thread.sleep(forTimeInterval: 0.5)
        
        var finalPosRef: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &finalPosRef)
        
        if let posRef = finalPosRef, CFGetTypeID(posRef) == AXValueGetTypeID() {
            var finalPos = CGPoint.zero
            AXValueGetValue(posRef as! AXValue, .cgPoint, &finalPos)
            print("Position after middle attempt: \(finalPos)")
            
            if finalPos.y >= 1329 {
                print("✅ SUCCESS: Middle positioning worked!")
            } else {
                print("❌ Still constrained above 4K display")
            }
        }
    }
}