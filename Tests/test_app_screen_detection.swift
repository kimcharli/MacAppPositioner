#!/usr/bin/env swift
import AppKit
import Foundation

// Find Chrome
let workspace = NSWorkspace.shared
let runningApps = workspace.runningApplications
guard let chromeApp = runningApps.first(where: { $0.bundleIdentifier == "com.google.Chrome" }) else {
    print("❌ Chrome not running")
    exit(1)
}

// Get Chrome window position
let app = AXUIElementCreateApplication(chromeApp.processIdentifier)
var windowRef: CFTypeRef?
let result = AXUIElementCopyAttributeValue(app, kAXMainWindowAttribute as CFString, &windowRef)

guard result == .success, let window = windowRef as! AXUIElement? else {
    print("❌ No Chrome windows found")
    exit(1)
}

var positionRef: CFTypeRef?
AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)

if let posRef = positionRef, CFGetTypeID(posRef) == AXValueGetTypeID() {
    var windowPos = CGPoint.zero
    AXValueGetValue(posRef as! AXValue, .cgPoint, &windowPos)
    
    print("Chrome window position (Cocoa): \(windowPos)")
    
    // Check which screen contains this point
    for (i, screen) in NSScreen.screens.enumerated() {
        let screenFrame = screen.frame
        if screenFrame.contains(windowPos) {
            print("✅ Chrome is on Screen \(i): \(screenFrame)")
            print("   Screen name: \(screen.localizedName)")
            
            if screen.localizedName.contains("Built-in") {
                print("   📱 Chrome is on BUILTIN screen")
            } else if screenFrame.width == 3840 && screenFrame.height == 2160 {
                print("   🖥️ Chrome is on 4K screen")
            } else {
                print("   🖥️ Chrome is on external monitor")
            }
            break
        }
    }
    
    // Also show which screen it should be on based on target
    print("\nScreen analysis:")
    for (i, screen) in NSScreen.screens.enumerated() {
        print("Screen \(i): \(screen.frame) - \(screen.localizedName)")
    }
}
