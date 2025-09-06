#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Test the new coordinate conversion logic
 */

print("=== Testing New Coordinate Conversion Logic ===")

// Simulate the getAllMonitors() and convertGlobalCanonicalToAbsoluteQuartz functions

struct TestMonitorInfo {
    let frame: CGRect           // Global Canonical coordinates
    let resolution: String
}

// Simulate monitor setup based on what we know
let testMonitors = [
    TestMonitorInfo(frame: CGRect(x: 0, y: 0, width: 2056, height: 1329), resolution: "2056.0x1329.0"),
    TestMonitorInfo(frame: CGRect(x: -2560, y: 969, width: 2560, height: 1440), resolution: "2560.0x1440.0"),
    TestMonitorInfo(frame: CGRect(x: 0, y: 1329, width: 3840, height: 2160), resolution: "3840.0x2160.0")
]

print("\n📺 Test Monitors:")
for (i, monitor) in testMonitors.enumerated() {
    print("  Monitor \(i): Global Canonical \(monitor.frame), Resolution \(monitor.resolution)")
}

// Test conversion function
func testConvertGlobalCanonicalToAbsoluteQuartz(globalCanonicalPoint: CGPoint) -> CGPoint? {
    print("\n🔄 Converting global canonical point: \(globalCanonicalPoint)")
    
    // Find the target monitor containing this point
    for monitor in testMonitors {
        print("  Checking monitor: \(monitor.frame)")
        if monitor.frame.contains(globalCanonicalPoint) {
            print("    ✅ Point is in this monitor")
            
            // Convert from global canonical to this monitor's coordinate space
            let localX = globalCanonicalPoint.x - monitor.frame.origin.x
            let localY = globalCanonicalPoint.y - monitor.frame.origin.y
            print("    Local coordinates: (\(localX), \(localY))")
            
            // Get the NSScreen corresponding to this monitor
            if let nsScreen = NSScreen.screens.first(where: { screen in
                let screenResolution = "\(screen.frame.width)x\(screen.frame.height)"
                print("    Comparing screen resolution \(screenResolution) with \(monitor.resolution)")
                return screenResolution == monitor.resolution
            }) {
                print("    ✅ Found matching NSScreen: \(nsScreen.frame)")
                
                // Convert to Cocoa coordinates for this screen
                let cocoaX = nsScreen.frame.origin.x + localX
                let cocoaY = nsScreen.frame.origin.y + localY
                
                let result = CGPoint(x: cocoaX, y: cocoaY)
                print("    Final Cocoa coordinates: \(result)")
                return result
            } else {
                print("    ❌ No matching NSScreen found")
            }
        } else {
            print("    ❌ Point is not in this monitor")
        }
    }
    
    print("  ⚠️  Point not found in any monitor")
    return nil
}

// Test cases
let testPoints = [
    CGPoint(x: 100, y: 37),      // Should be on 4K display
    CGPoint(x: 100, y: 1500),    // Should be on 4K display  
    CGPoint(x: 100, y: 100),     // Should be on builtin display
    CGPoint(x: -1000, y: 1000)   // Should be on left display
]

for testPoint in testPoints {
    if let result = testConvertGlobalCanonicalToAbsoluteQuartz(globalCanonicalPoint: testPoint) {
        print("✅ Conversion successful: \(testPoint) → \(result)")
    } else {
        print("❌ Conversion failed for: \(testPoint)")
    }
}