#!/usr/bin/env swift
import AppKit
import Foundation

print("=== Exact Screen Coordinates from Swift API ===")
print()

// Get NSScreen.main
if let mainScreen = NSScreen.main {
    print("NSScreen.main:")
    print("  Frame: \(mainScreen.frame)")
    print("  Visible Frame: \(mainScreen.visibleFrame)")
    print("  Name: \(mainScreen.localizedName)")
    print("  Scale: \(mainScreen.backingScaleFactor)")
    print()
} else {
    print("❌ No NSScreen.main found!")
}

// Get all screens
print("All NSScreen.screens (\(NSScreen.screens.count) total):")
print()

for (index, screen) in NSScreen.screens.enumerated() {
    let isMain = screen == NSScreen.main
    let isBuiltIn = screen.localizedName.contains("Built-in") || screen.localizedName.contains("Liquid")
    let is4K = screen.frame.width == 3840 && screen.frame.height == 2160
    
    print("Screen \(index): \(screen.localizedName)")
    print("  Frame: \(screen.frame)")
    print("  Visible Frame: \(screen.visibleFrame)")
    print("  Scale Factor: \(screen.backingScaleFactor)")
    print("  Is NSScreen.main: \(isMain)")
    print("  Is Built-in: \(isBuiltIn)")  
    print("  Is 4K: \(is4K)")
    
    if is4K {
        print("  📺 This is the 4K screen")
    }
    if isBuiltIn {
        print("  💻 This is the built-in screen")
    }
    if isMain {
        print("  🎯 This is NSScreen.main")
    }
    print()
}

// Show coordinate system info
print("Coordinate System Information:")
print("- Cocoa coordinates use bottom-left origin (Y increases upward)")
print("- Accessibility API uses top-left origin (Y increases downward)")
print("- NSScreen.frame and visibleFrame are in Cocoa coordinates")
print()

// Calculate what 4K screen coordinates should be in top-left origin system
if let builtinScreen = NSScreen.screens.first(where: { screen in
    screen.localizedName.contains("Built-in") || screen.localizedName.contains("Liquid")
}), let fourKScreen = NSScreen.screens.first(where: { screen in
    screen.frame.width == 3840 && screen.frame.height == 2160
}) {
    print("Physical Layout Analysis:")
    print("Built-in (Cocoa): \(builtinScreen.frame)")
    print("4K Screen (Cocoa): \(fourKScreen.frame)")
    
    // In Cocoa: 4K at Y=1329 means it's BELOW built-in at Y=0 (Cocoa origin is bottom-left)
    // But physically you said 4K is ABOVE built-in
    // So the macOS Display arrangement doesn't match physical reality
    
    let fourKRelativeY = fourKScreen.frame.origin.y - builtinScreen.frame.origin.y
    if fourKRelativeY > 0 {
        print("⚠️  macOS thinks 4K is BELOW built-in (Cocoa Y=\(fourKRelativeY))")
        print("⚠️  But you said 4K is physically ABOVE built-in")
        print("⚠️  This mismatch is causing the coordinate problems!")
    }
}
