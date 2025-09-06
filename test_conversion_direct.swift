#!/usr/bin/env swift
import AppKit
import Foundation

// Copy the coordinate conversion logic for testing
func convertCocoaToGlobalCanonical(cocoaFrame: CGRect, mainScreen: NSScreen) -> CGRect {
    let mainCocoaFrame = mainScreen.frame
    let relativeX = cocoaFrame.origin.x - mainCocoaFrame.origin.x
    let screenResolution = "\(cocoaFrame.width)x\(cocoaFrame.height)"
    
    let globalCanonicalX = relativeX
    let globalCanonicalY: CGFloat
    
    if screenResolution == "3840.0x2160.0" {
        globalCanonicalY = -cocoaFrame.height  // Y: -2160 to 0
    } else if cocoaFrame == mainCocoaFrame {
        globalCanonicalY = 0  // Y: 0 to 1329
    } else {
        let relativeCocoa = cocoaFrame.origin.y - mainCocoaFrame.origin.y
        if relativeCocoa > 0 {
            globalCanonicalY = mainCocoaFrame.height  // Below builtin
        } else {
            globalCanonicalY = -cocoaFrame.height  // Above builtin
        }
    }
    
    return CGRect(x: globalCanonicalX, y: globalCanonicalY, width: cocoaFrame.width, height: cocoaFrame.height)
}

// Test with actual screen data
guard let builtinScreen = NSScreen.screens.first(where: { screen in
    screen.localizedName.contains("Built-in") || screen.localizedName.contains("Liquid")
}) else {
    print("No builtin screen found")
    exit(1)
}

for screen in NSScreen.screens {
    if screen.frame.width == 3840 && screen.frame.height == 2160 {
        let frame = convertCocoaToGlobalCanonical(cocoaFrame: screen.frame, mainScreen: builtinScreen)
        let visibleFrame = convertCocoaToGlobalCanonical(cocoaFrame: screen.visibleFrame, mainScreen: builtinScreen)
        
        print("4K Screen Conversion Test:")
        print("Frame: \(screen.frame) → \(frame)")
        print("Visible: \(screen.visibleFrame) → \(visibleFrame)")
        break
    }
}
