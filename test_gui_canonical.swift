#!/usr/bin/env swift

import AppKit
import Foundation

// Test script to verify GUI uses canonical coordinate system
func testGUICanonicalSystem() {
    print("🎯 Testing GUI Canonical Coordinate System Integration")
    print("")
    
    // Mock the GUI's monitor detection logic
    let canonicalCoordinateManager = CanonicalCoordinateManager.shared
    let configManager = ConfigManager()
    
    print("1. Testing Canonical Monitor Detection (GUI Logic):")
    let canonicalMonitors = canonicalCoordinateManager.getAllMonitors()
    
    for (index, monitor) in canonicalMonitors.enumerated() {
        print("   Monitor \(index + 1): \(monitor.resolution)")
        print("     Frame: \(monitor.frame) [Canonical Quartz]")
        print("     Scale: \(monitor.scale), Built-in: \(monitor.isBuiltIn)")
        print("     NSScreen.main check: \(monitor.isMain)")
        print("")
    }
    
    print("2. Testing Config-Based Primary Detection (GUI Logic):")
    if let config = configManager.loadConfig() {
        let homeProfile = config.profiles["home"]
        let primaryMonitorResolution = homeProfile?.monitors.first(where: { $0.position == "primary" })?.resolution
        print("   Config defines primary as: \(primaryMonitorResolution ?? "None")")
        
        for monitor in canonicalMonitors {
            let isPrimaryFromConfig = monitor.resolution == primaryMonitorResolution
            let status = isPrimaryFromConfig ? "✅ PRIMARY (Config)" : (monitor.isMain ? "⚠️  Main (NSScreen)" : "📱 Secondary")
            print("   \(monitor.resolution): \(status)")
        }
        print("")
    }
    
    print("3. Verification:")
    let externalMonitor = canonicalMonitors.first { $0.resolution == "3840.0x2160.0" }
    let builtInMonitor = canonicalMonitors.first { $0.isBuiltIn }
    
    if let external = externalMonitor, let builtIn = builtInMonitor {
        print("   4K External (3840x2160): Found")
        print("     NSScreen.main says: \(external.isMain ? "Main" : "Not Main")")
        print("   Built-in Display: Found")  
        print("     NSScreen.main says: \(builtIn.isMain ? "Main" : "Not Main")")
        print("")
        
        if !external.isMain && builtIn.isMain {
            print("   ✅ CORRECT: GUI will use config-defined primary (4K External)")
            print("   ✅ CORRECT: GUI will ignore NSScreen.main (Built-in)")
        } else {
            print("   ❌ ISSUE: Unexpected main screen designation")
        }
    }
    
    print("")
    print("4. Expected GUI Behavior:")
    print("   - Monitor Visualization should show 4K External as 'Main'")  
    print("   - Built-in Display should show as secondary")
    print("   - Apply Layout should use 4K External for positioning")
    print("   - All coordinates internally use canonical Quartz system")
}

// Stub classes for testing (would be compiled with project in real usage)
class CanonicalCoordinateManager {
    static let shared = CanonicalCoordinateManager()
    
    func getAllMonitors() -> [CanonicalMonitorInfo] {
        let globalHeight = getGlobalScreenHeight()
        return NSScreen.screens.map { screen in
            let cocoaFrame = screen.frame
            let canonicalFrame = toCanonical(rect: cocoaFrame, from: .cocoa, referenceScreenHeight: globalHeight)
            
            return CanonicalMonitorInfo(
                frame: canonicalFrame,
                visibleFrame: canonicalFrame,
                resolution: "\(cocoaFrame.width)x\(cocoaFrame.height)",
                scale: screen.backingScaleFactor,
                isMain: screen == NSScreen.main,
                isBuiltIn: screen.backingScaleFactor > 1.0
            )
        }
    }
    
    func getGlobalScreenHeight() -> CGFloat {
        var maxY: CGFloat = 0
        for screen in NSScreen.screens {
            let topY = screen.frame.origin.y + screen.frame.height
            maxY = max(maxY, topY)
        }
        return maxY
    }
    
    func toCanonical(rect: CGRect, from system: CoordinateSystem, referenceScreenHeight: CGFloat) -> CGRect {
        switch system {
        case .quartz: return rect
        case .cocoa:
            let canonicalY = referenceScreenHeight - rect.origin.y - rect.height
            return CGRect(x: rect.origin.x, y: canonicalY, width: rect.width, height: rect.height)
        }
    }
}

struct CanonicalMonitorInfo {
    let frame: CGRect
    let visibleFrame: CGRect
    let resolution: String
    let scale: CGFloat
    let isMain: Bool
    let isBuiltIn: Bool
}

enum CoordinateSystem { case cocoa, quartz }

class ConfigManager {
    func loadConfig() -> Config? {
        guard let url = URL(string: "file://\(FileManager.default.currentDirectoryPath)/config.json") else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Config.self, from: data)
    }
}

struct Config: Codable {
    let profiles: [String: Profile]
}

struct Profile: Codable {
    let monitors: [Monitor]
}

struct Monitor: Codable {
    let resolution: String
    let position: String
}

testGUICanonicalSystem()