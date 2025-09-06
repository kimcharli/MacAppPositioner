#!/usr/bin/env swift

import AppKit

print("=== Coordinate Conversion Debug ===")

guard let mainScreen = NSScreen.main else {
    print("No main screen found")
    exit(1)
}

print("Main Screen (Reference):")
print("  Frame: \(mainScreen.frame)")
print("  Resolution: \(mainScreen.frame.width)x\(mainScreen.frame.height)")

print("\nTesting coordinate conversion for each screen:")

for (index, screen) in NSScreen.screens.enumerated() {
    let cocoaFrame = screen.frame
    print("\nScreen \(index + 1) - \(screen.localizedName):")
    print("  Cocoa Frame: \(cocoaFrame)")
    print("  Is Main Screen: \(screen == mainScreen)")
    
    // Manual coordinate conversion
    let mainCocoaFrame = mainScreen.frame
    let relativeX = cocoaFrame.origin.x - mainCocoaFrame.origin.x
    let relativeY = cocoaFrame.origin.y - mainCocoaFrame.origin.y
    
    // Convert to Global Canonical coordinates (simple relative positioning)
    let globalCanonicalX = relativeX
    let globalCanonicalY = relativeY
    
    let globalCanonical = CGRect(
        x: globalCanonicalX,
        y: globalCanonicalY,
        width: cocoaFrame.width,
        height: cocoaFrame.height
    )
    
    print("  Global Canonical: \(globalCanonical)")
    print("  Conversion steps:")
    print("    relativeX = \(cocoaFrame.origin.x) - \(mainCocoaFrame.origin.x) = \(relativeX)")
    print("    relativeY = \(cocoaFrame.origin.y) - \(mainCocoaFrame.origin.y) = \(relativeY)")
    print("    globalCanonicalX = \(relativeX)")
    print("    globalCanonicalY = \(relativeY)")
}
