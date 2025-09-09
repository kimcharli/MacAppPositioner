import Foundation
import AppKit

/**
 * Native Cocoa Profile Manager
 * 
 * ARCHITECTURE PRINCIPLE:
 * - Uses ONLY native Cocoa coordinates (NSScreen.frame)
 * - NO coordinate conversions or custom systems
 * - Bottom-left origin, Y increases upward (native macOS behavior)
 * - Direct NSScreen API usage throughout
 */

class CocoaProfileManager {
    
    private let configManager = ConfigManager()
    private let coordinateManager = CocoaCoordinateManager.shared
    
    // MARK: - Helper Functions
    
    // MARK: - Profile Detection
    
    func detectProfile() -> String? {
        guard let config = configManager.loadConfig() else {
            print("Failed to load config")
            return nil
        }

        let monitors = coordinateManager.getAllMonitors()
        let currentResolutions = Set(monitors.map { AppUtils.normalizeResolution($0.resolution) })

        for (profileName, profile) in config.profiles {
            var profileResolutions: Set<String> = []
            
            // Build set of expected resolutions for this profile
            for monitor in profile.monitors {
                if monitor.resolution == "builtin" || monitor.resolution == "macbook" {
                    // Find builtin screen resolution
                    if let builtinMonitor = monitors.first(where: { $0.isBuiltIn }) {
                        profileResolutions.insert(AppUtils.normalizeResolution(builtinMonitor.resolution))
                    }
                } else {
                    profileResolutions.insert(AppUtils.normalizeResolution(monitor.resolution))
                }
            }
            
            if profileResolutions == currentResolutions {
                print("✅ Matched profile: \(profileName)")
                return profileName
            }
        }
        
        return nil
    }
    
    // MARK: - Profile Application
    
    func applyProfile(_ profileName: String) {
        print("🎯 COCOA ProfileManager: applyProfile called")
        
        guard let config = configManager.loadConfig() else {
            print("Failed to load config")
            return
        }
        
        guard let profile = config.profiles[profileName] else {
            print("Profile \(profileName) not found")
            return
        }
        
        let allMonitors = coordinateManager.getAllMonitors(for: profileName)
        print("=== All Monitors in Native Cocoa ===")
        for (index, monitor) in allMonitors.enumerated() {
            print("Monitor \(index + 1): \(monitor.resolution)")
            print("  Frame: \(coordinateManager.debugDescription(rect: monitor.frame, label: "Frame"))")
            print("  isMain: \(monitor.isMain), isWorkspace: \(monitor.isWorkspace)")
        }
        
        // Find the workspace monitor from the config
        guard let workspaceMonitorConfig = profile.monitors.first(where: { $0.position == "workspace" }) else {
            print("No workspace monitor found in profile")
            return
        }
        
        guard let workspaceMonitor = coordinateManager.findWorkspaceMonitor(resolution: workspaceMonitorConfig.resolution) else {
            print("Workspace monitor with resolution \(workspaceMonitorConfig.resolution) not found")
            return
        }
        
        print("=== Native Cocoa Coordinate System Debug ===")
        print("Workspace Monitor (Native Cocoa coordinates):")
        print("  Frame: \(coordinateManager.debugDescription(rect: workspaceMonitor.frame, label: "Frame"))")
        print("  Visible Frame: \(coordinateManager.debugDescription(rect: workspaceMonitor.visibleFrame, label: "Visible Frame"))")
        
        guard let layout = config.layout?.workspace else {
            print("No workspace layout defined")
            return
        }
        
        // Position applications using native Cocoa coordinates
        for (quadrant, bundleID) in layout {
            print("\nProcessing \(bundleID) for position '\(quadrant)':")
            
            guard let pid = getAppPID(bundleID: bundleID) else {
                print("  ❌ App not running: \(bundleID)")
                continue
            }
            
            // Get current window position and size (native Cocoa)
            var actualWindowSize = CGSize(width: 1200, height: 800) // Default fallback
            if let currentPosition = getCurrentWindowPosition(pid: pid) {
                print("  Current position: \(coordinateManager.debugDescription(rect: currentPosition, label: "Current"))")
                actualWindowSize = currentPosition.size
            }
            
            // Calculate target position in native Cocoa coordinates using actual window size
            let targetPosition = coordinateManager.calculateQuadrantPosition(
                quadrant: quadrant,
                windowSize: actualWindowSize,
                visibleFrame: workspaceMonitor.visibleFrame
            )
            
            print("    Quadrant Calculation (Native Cocoa):")
            print("    Visible Frame: \(coordinateManager.debugDescription(rect: workspaceMonitor.visibleFrame, label: "Visible"))")
            print("    Calculated Position: \(targetPosition) [Native Cocoa]")
            
            // Set window position using native Cocoa coordinates
            coordinateManager.setWindowPosition(pid: pid, position: targetPosition)
            
            // Verify final position
            if let finalPosition = getCurrentWindowPosition(pid: pid) {
                print("  Final position: \(coordinateManager.debugDescription(rect: finalPosition, label: "Final"))")
            }
        }
        
        // Handle builtin layout if exists
        if let builtinApps = config.layout?.builtin {
            let builtinMonitor = allMonitors.first { $0.isBuiltIn }
            
            for bundleID in builtinApps {
                guard let pid = getAppPID(bundleID: bundleID) else {
                    print("❌ Builtin app not running: \(bundleID)")
                    continue
                }
                
                if let builtinMonitor = builtinMonitor {
                    // Check if app is already on the builtin monitor
                    if let currentPosition = getCurrentWindowPosition(pid: pid) {
                        let windowCenter = CGPoint(
                            x: currentPosition.midX,
                            y: currentPosition.midY
                        )
                        
                        // Check if window center is within builtin monitor bounds
                        let isOnBuiltin = builtinMonitor.frame.contains(windowCenter)
                        
                        if isOnBuiltin {
                            print("\n📱 \(bundleID) is already on builtin screen, skipping repositioning")
                            continue
                        }
                    }
                    
                    // Only reposition if not already on builtin screen
                    let centerPosition = CGPoint(
                        x: builtinMonitor.visibleFrame.midX - 300,
                        y: builtinMonitor.visibleFrame.midY - 200
                    )
                    
                    print("\n📱 Moving \(bundleID) to builtin screen:")
                    print("  Position: \(centerPosition) [Native Cocoa]")
                    
                    coordinateManager.setWindowPosition(pid: pid, position: centerPosition)
                }
            }
        }
    }
    
    // MARK: - Utility Functions
    
    private func getAppPID(bundleID: String) -> pid_t? {
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if app.bundleIdentifier == bundleID {
                return app.processIdentifier
            }
        }
        
        return nil
    }
    
    private func getCurrentWindowPosition(pid: pid_t) -> CGRect? {
        let app = AXUIElementCreateApplication(pid)
        
        var windows: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windows)
        
        guard result == .success,
              let windowArray = windows as? [AXUIElement],
              let window = windowArray.first else {
            return nil
        }
        
        var position: CFTypeRef?
        var size: CFTypeRef?
        
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &position)
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &size)
        
        var positionValue = CGPoint.zero
        var sizeValue = CGSize.zero
        
        if let position = position {
            AXValueGetValue(position as! AXValue, .cgPoint, &positionValue)
        }
        
        if let size = size {
            AXValueGetValue(size as! AXValue, .cgSize, &sizeValue)
        }
        
        return CGRect(origin: positionValue, size: sizeValue)
    }
    
    // MARK: - Profile Generation
    
    func updateProfile(name: String) {
        print("Update profile functionality not yet implemented for profile: \(name)")
    }
    
    func generateConfig() {
        let config = generateConfigForCurrentSetup()
        print(config)
    }
    
    func generateConfigForCurrentSetup() -> String {
        let monitors = coordinateManager.getAllMonitors()
        
        var generatedConfig = """
{
  "profiles": {
    "detected": {
      "monitors": [
"""
        
        for (index, monitor) in monitors.enumerated() {
            let position: String
            if monitor.isBuiltIn {
                position = "builtin"
            } else if index == 0 && !monitor.isBuiltIn {
                position = "workspace"  // First external monitor as workspace
            } else {
                position = "left"  // Additional monitors
            }
            
            generatedConfig += """
        {
          "resolution": "\(monitor.resolution)",
          "position": "\(position)"
        }
"""
            
            if index < monitors.count - 1 {
                generatedConfig += ","
            }
            generatedConfig += "\n"
        }
        
        generatedConfig += """
      ]
    }
  },
  "layout": {
    "workspace": {
      "top_left": "com.google.Chrome",
      "top_right": "com.microsoft.teams2",
      "bottom_left": "com.microsoft.Outlook",
      "bottom_right": "com.slack.Slack"
    },
    "builtin": [
      "md.obsidian"
    ]
  }
}
"""
        
        return generatedConfig
    }
}