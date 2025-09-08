#!/usr/bin/env swift
import AppKit
for screen in NSScreen.screens {
    print("Screen: \(screen.frame)")
    print("Visible: \(screen.visibleFrame)")
    print("---")
}
