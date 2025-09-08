#!/usr/bin/env swift

import AppKit

print("=== NSScreen.main Debug ===")

if let mainScreen = NSScreen.main {
    print("NSScreen.main:")
    print("  Frame: \(mainScreen.frame)")
    print("  Resolution: \(mainScreen.frame.width)x\(mainScreen.frame.height)")
    print("  Scale: \(mainScreen.backingScaleFactor)")
    print("  LocalizedName: \(mainScreen.localizedName)")
} else {
    print("No main screen found")
}

print("\n=== All NSScreens ===")
for (index, screen) in NSScreen.screens.enumerated() {
    print("Screen \(index + 1):")
    print("  Frame: \(screen.frame)")
    print("  Resolution: \(screen.frame.width)x\(screen.frame.height)")
    print("  LocalizedName: \(screen.localizedName)")
    print("  Is NSScreen.main: \(screen == NSScreen.main)")
}