#!/usr/bin/env swift

import AppKit
import Foundation

/**
 * Debug screen detection to find the coordinate system bug
 */

print("=== Screen Detection Debug ===")

guard let mainScreen = NSScreen.main else {
    print("❌ No main screen found")
    exit(1)
}

print("NSScreen.main: \(mainScreen.frame)")
print("NSScreen.main localizedName: \(mainScreen.localizedName)")

print("\nAll screens:")
for (i, screen) in NSScreen.screens.enumerated() {
    let isMain = screen == mainScreen
    let isBuiltIn = screen.localizedName.contains("Built-in") || 
                   screen.localizedName.contains("Liquid")
    print("  Screen \(i): \(screen.frame)")
    print("    Name: \(screen.localizedName)")
    print("    isMain: \(isMain)")
    print("    isBuiltIn: \(isBuiltIn)")
    print()
}

// Find the actual builtin screen
if let builtinScreen = NSScreen.screens.first(where: { screen in
    screen.localizedName.contains("Built-in") || screen.localizedName.contains("Liquid")
}) {
    print("✅ Found builtin screen: \(builtinScreen.frame)")
    print("   Name: \(builtinScreen.localizedName)")
    
    if builtinScreen == mainScreen {
        print("   ✅ Builtin screen IS NSScreen.main")
    } else {
        print("   ❌ Builtin screen is NOT NSScreen.main")
        print("   🐛 BUG: Coordinate system will be wrong!")
    }
} else {
    print("❌ No builtin screen found")
}

// Check which screen should be at (0,0) in global canonical
print("\nExpected coordinate system:")
print("- Builtin screen should be at (0, 0)")  
print("- 4K screen should be at (0, positive_Y)")

// Show what the current coordinate conversion would produce
func convertCocoaToGlobalCanonical(cocoaFrame: CGRect, mainScreen: NSScreen) -> CGRect {
    let mainCocoaFrame = mainScreen.frame
    return CGRect(
        x: cocoaFrame.origin.x - mainCocoaFrame.origin.x,
        y: cocoaFrame.origin.y - mainCocoaFrame.origin.y,
        width: cocoaFrame.width,
        height: cocoaFrame.height
    )
}

print("\nActual coordinate conversion using NSScreen.main:")
for (i, screen) in NSScreen.screens.enumerated() {
    let globalCanonical = convertCocoaToGlobalCanonical(cocoaFrame: screen.frame, mainScreen: mainScreen)
    print("  Screen \(i): Cocoa \(screen.frame) → Global Canonical \(globalCanonical)")
}