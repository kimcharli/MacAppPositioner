#!/usr/bin/env swift

import AppKit
import Foundation

print("=== Monitor Detection Debug ===")
print("")

print("Available NSScreens:")
for (index, screen) in NSScreen.screens.enumerated() {
    let frame = screen.frame
    let visibleFrame = screen.visibleFrame
    let scale = screen.backingScaleFactor
    let isMain = screen == NSScreen.main
    
    print("Screen \(index + 1):")
    print("  Frame: \(frame)")
    print("  Visible Frame: \(visibleFrame)")
    print("  Resolution: \(frame.width)x\(frame.height)")
    print("  Scale Factor: \(scale)")
    print("  Is Main: \(isMain)")
    print("  Is Built-in: \(scale > 1.0 ? "Yes" : "No")")
    print("")
}

print("Expected Primary Monitor from config:")
print("  Resolution: 3840.0x2160.0")
print("")

// Test resolution matching
let targetResolution = "3840.0x2160.0"
if let primaryScreen = NSScreen.screens.first(where: { "\($0.frame.width)x\($0.frame.height)" == targetResolution }) {
    print("✅ Found matching primary monitor:")
    print("  Frame: \(primaryScreen.frame)")
    print("  Visible Frame: \(primaryScreen.visibleFrame)")
} else {
    print("❌ Could not find monitor with resolution \(targetResolution)")
    print("Available resolutions:")
    for screen in NSScreen.screens {
        print("  - \(screen.frame.width)x\(screen.frame.height)")
    }
}