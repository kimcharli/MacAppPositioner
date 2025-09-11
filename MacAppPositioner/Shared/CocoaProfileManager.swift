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
    
    // MARK: - Unified Positioning
    
    private func positionApp(bundleID: String,
                            position: String,
                            sizing: String?,
                            targetMonitor: CocoaMonitorInfo,
                            appSettings: AppSettings?,
                            mainScreen: NSScreen?) {
        
        NSLog("positionApp called for \(bundleID) with position: \(position)")
        
        guard let pid = getAppPID(bundleID: bundleID) else {
            print("  ❌ App not running: \(bundleID)")
            NSLog("  ❌ App not running: \(bundleID)")
            return
        }
        
        NSLog("Found PID \(pid) for \(bundleID)")
        
        // Check if position is set to "keep"
        if position == "keep" {
            print("  🔒 \(bundleID) has 'keep' position - skipping repositioning")
            return
        }
        
        // Get current window position and size
        var actualWindowSize = CGSize(width: 1200, height: 800) // Default fallback
        if let currentPosition = getCurrentWindowPosition(pid: pid) {
            print("  Current position: \(coordinateManager.debugDescription(rect: currentPosition, label: "Current"))")
            
            // Check if already on target monitor (for center position)
            if position == "center" {
                let windowCenter = CGPoint(
                    x: currentPosition.midX,
                    y: currentPosition.midY
                )
                
                if targetMonitor.frame.contains(windowCenter) {
                    print("  📱 \(bundleID) is already on target screen, skipping repositioning")
                    return
                }
            }
            
            // Use current size if sizing is set to "keep" (default)
            if sizing == "keep" || appSettings?.sizing == "keep" {
                actualWindowSize = currentPosition.size
                print("  🔒 Keeping current window size: \(actualWindowSize)")
            } else {
                actualWindowSize = currentPosition.size
            }
        }
        
        // Calculate target position based on position value
        let calculatedPosition: CGPoint
        switch position {
        case "center":
            // Center on monitor
            calculatedPosition = CGPoint(
                x: targetMonitor.visibleFrame.midX - actualWindowSize.width / 2,
                y: targetMonitor.visibleFrame.midY - actualWindowSize.height / 2
            )
            print("  Centering on monitor")
        case "top_left", "top_right", "bottom_left", "bottom_right":
            // Use quadrant positioning
            calculatedPosition = coordinateManager.calculateQuadrantPosition(
                quadrant: position,
                windowSize: actualWindowSize,
                visibleFrame: targetMonitor.visibleFrame
            )
            print("  Quadrant Calculation (Native Cocoa):")
            print("  Visible Frame: \(coordinateManager.debugDescription(rect: targetMonitor.visibleFrame, label: "Visible"))")
        default:
            print("  ⚠️ Unknown position: \(position), using center")
            calculatedPosition = CGPoint(
                x: targetMonitor.visibleFrame.midX - actualWindowSize.width / 2,
                y: targetMonitor.visibleFrame.midY - actualWindowSize.height / 2
            )
        }
        
        print("  Calculated Position: \(calculatedPosition) [Native Cocoa]")
        NSLog("  Setting \(bundleID) to position: \(calculatedPosition) on monitor \(targetMonitor.resolution)")
        
        // Set window position
        coordinateManager.setWindowPosition(pid: pid, position: calculatedPosition, size: nil, mainScreen: mainScreen)
        NSLog("  Position set for \(bundleID)")
        
        // Verify final position
        if let finalPosition = getCurrentWindowPosition(pid: pid) {
            print("  Final position: \(coordinateManager.debugDescription(rect: finalPosition, label: "Final"))")
        }
    }
    
    // MARK: - Profile Application
    
    /**
     * Applies the specified profile by positioning applications according to the layout.
     * This is the main entry point for applying a window layout.
     *
     * @param profileName The name of the profile to apply.
     */
    func applyProfile(_ profileName: String) {
        print("🎯 COCOA ProfileManager: applyProfile called")
        NSLog("🎯 COCOA ProfileManager: applyProfile called with profile: \(profileName)")
        
        guard let config = configManager.loadConfig() else {
            print("Failed to load config")
            NSLog("Failed to load config")
            return
        }
        
        NSLog("Config loaded successfully, profiles: \(config.profiles.keys)")
        
        guard let profile = config.profiles[profileName] else {
            print("Profile \(profileName) not found")
            NSLog("Profile \(profileName) not found in config")
            return
        }
        
        NSLog("Profile \(profileName) found, continuing with application")
        
        NSLog("About to call getAllMonitors for profile: \(profileName)")
        let allMonitors = coordinateManager.getAllMonitors(for: profileName)
        NSLog("getAllMonitors returned \(allMonitors.count) monitors")
        print("=== All Monitors in Native Cocoa ===")
        for (index, monitor) in allMonitors.enumerated() {
            print("Monitor \(index + 1): \(monitor.resolution)")
            print("  Frame: \(coordinateManager.debugDescription(rect: monitor.frame, label: "Frame"))")
            print("  isMain: \(monitor.isMain), isWorkspace: \(monitor.isWorkspace)")
        }
        
        // Find the workspace monitor from the config, which is our primary target for positioning.
        guard let workspaceMonitorConfig = profile.monitors.first(where: { $0.position == "workspace" }) else {
            print("No workspace monitor found in profile")
            return
        }
        
        guard let workspaceMonitor = coordinateManager.findWorkspaceMonitor(resolution: workspaceMonitorConfig.resolution) else {
            print("Workspace monitor with resolution \(workspaceMonitorConfig.resolution) not found")
            NSLog("Workspace monitor with resolution \(workspaceMonitorConfig.resolution) not found")
            return
        }
        
        NSLog("Found workspace monitor: \(workspaceMonitor.resolution), frame: \(workspaceMonitor.frame)")
        print("=== Native Cocoa Coordinate System Debug ===")
        print("Workspace Monitor (Native Cocoa coordinates):")
        print("  Frame: \(coordinateManager.debugDescription(rect: workspaceMonitor.frame, label: "Frame"))")
        print("  Visible Frame: \(coordinateManager.debugDescription(rect: workspaceMonitor.visibleFrame, label: "Visible Frame"))")
        
        guard let layout = config.layout?.workspace else {
            print("No workspace layout defined")
            NSLog("No workspace layout defined")
            return
        }
        
        NSLog("Processing \(layout.count) apps in workspace layout")
        
        // Use the reliable builtin screen detection instead of NSScreen.main which can change
        let mainScreen = coordinateManager.getBuiltinScreen()
        NSLog("Using builtin screen as mainScreen: \(mainScreen.frame)")

        // Position applications on the workspace monitor.
        for (bundleID, workspaceApp) in layout {
            NSLog("Processing app: \(bundleID) for position: \(workspaceApp.position)")
            print("\nProcessing \(bundleID) for workspace position '\(workspaceApp.position)':")
            
            let appSettings = config.applications[bundleID]
            
            NSLog("About to call positionApp for \(bundleID)")
            positionApp(
                bundleID: bundleID,
                position: workspaceApp.position,
                sizing: workspaceApp.sizing,
                targetMonitor: workspaceMonitor,
                appSettings: appSettings,
                mainScreen: mainScreen
            )
        }
        
        // Position applications on the built-in monitor, if a layout is defined.
        if let builtinApps = config.layout?.builtin,
           let builtinMonitor = allMonitors.first(where: { $0.isBuiltIn }) {
            
            for (bundleID, builtinApp) in builtinApps {
                let displayPosition = builtinApp.position ?? "center"
                print("\n📱 Processing \(bundleID) for builtin screen (position: \(displayPosition)):")
                
                let appSettings = config.applications[bundleID]
                
                positionApp(
                    bundleID: bundleID,
                    position: builtinApp.position ?? "center",
                    sizing: builtinApp.sizing,
                    targetMonitor: builtinMonitor,
                    appSettings: appSettings,
                    mainScreen: mainScreen
                )
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
        guard var config = configManager.loadConfig() else {
            print("Failed to load config.json")
            return
        }

        guard config.profiles[name] != nil else {
            print("Profile '\(name)' not found in config.json")
            return
        }

        let monitors = coordinateManager.getAllMonitors()
        let newMonitors = monitors.map { monitor -> Monitor in
            let position: String
            if monitor.isBuiltIn {
                position = "builtin"
            } else if monitor.isWorkspace {
                position = "workspace"
            } else {
                position = "secondary"
            }
            return Monitor(resolution: monitor.resolution, position: position)
        }

        let newProfile = Profile(monitors: newMonitors)
        config.profiles[name] = newProfile

        if configManager.saveConfig(config) {
            print("✅ Profile '\(name)' updated successfully.")
        } else {
            print("❌ Failed to save updated configuration.")
        }
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