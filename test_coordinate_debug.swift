#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Debug coordinate conversion issue
 */

print("=== Coordinate Conversion Debug ===")

guard let mainScreen = NSScreen.main else {
    print("❌ No main screen found")
    exit(1)
}

// Helper function to convert Cocoa to Global Canonical (from CanonicalCoordinateManager)
func convertCocoaToGlobalCanonical(cocoaFrame: CGRect, mainScreen: NSScreen) -> CGRect {
    let mainCocoaFrame = mainScreen.frame
    
    return CGRect(
        x: cocoaFrame.origin.x - mainCocoaFrame.origin.x,
        y: cocoaFrame.origin.y - mainCocoaFrame.origin.y,
        width: cocoaFrame.width,
        height: cocoaFrame.height
    )
}

print("\n📺 Screen Information:")
for (i, screen) in NSScreen.screens.enumerated() {
    let isMain = screen == mainScreen
    print("  Screen \(i): \(screen.frame) \(isMain ? "(MAIN)" : "")")
    
    // Convert to global canonical
    let canonical = convertCocoaToGlobalCanonical(cocoaFrame: screen.frame, mainScreen: mainScreen)
    print("    Global Canonical: \(canonical)")
}

// Test the conversion logic with a point that should be on the 4K display
let testPoint = CGPoint(x: 100, y: 100)  // Should be on 4K display according to our layout
print("\n🧪 Testing conversion for point: \(testPoint)")

for screen in NSScreen.screens {
    // Convert screen's Cocoa frame to global canonical coordinates
    let screenGlobalCanonical = convertCocoaToGlobalCanonical(
        cocoaFrame: screen.frame,
        mainScreen: mainScreen
    )
    
    print("\n  Screen: \(screen.frame)")
    print("    Global Canonical Bounds: \(screenGlobalCanonical)")
    print("    Contains point \(testPoint)? \(screenGlobalCanonical.contains(testPoint))")
    
    // Check if the point is within this screen's global canonical bounds
    if screenGlobalCanonical.contains(testPoint) {
        print("    ✅ FOUND TARGET SCREEN")
        
        // Calculate local position within this screen
        let localX = testPoint.x - screenGlobalCanonical.origin.x
        let localY = testPoint.y - screenGlobalCanonical.origin.y
        
        print("    Local coordinates: (\(localX), \(localY))")
        
        // Convert to Cocoa coordinates
        let cocoaX = screen.frame.origin.x + localX
        let cocoaY = screen.frame.origin.y + localY
        
        let result = CGPoint(x: cocoaX, y: cocoaY)
        print("    Final Cocoa coordinates: \(result)")
    }
}

// Test a point that should clearly be on the 4K display
let fourKPoint = CGPoint(x: 100, y: 1500)  // Definitely on 4K display
print("\n🧪 Testing conversion for 4K point: \(fourKPoint)")

for screen in NSScreen.screens {
    let screenGlobalCanonical = convertCocoaToGlobalCanonical(
        cocoaFrame: screen.frame,
        mainScreen: mainScreen
    )
    
    print("  Screen bounds: \(screenGlobalCanonical)")
    print("    Contains \(fourKPoint)? \(screenGlobalCanonical.contains(fourKPoint))")
    
    if screenGlobalCanonical.contains(fourKPoint) {
        print("    ✅ This is the correct screen for 4K point")
        
        let localX = fourKPoint.x - screenGlobalCanonical.origin.x
        let localY = fourKPoint.y - screenGlobalCanonical.origin.y
        
        let cocoaX = screen.frame.origin.x + localX
        let cocoaY = screen.frame.origin.y + localY
        
        print("    Result: \(CGPoint(x: cocoaX, y: cocoaY))")
    }
}