import Foundation
import AppKit

/**
 * Profile Manager
 * 
 * ARCHITECTURE PRINCIPLE:
 * - Uses a consistent internal coordinate system (top-left origin) for all calculations.
 */

class CocoaProfileManager {

    private let configManager = ConfigManager.shared
    private let coordinateManager = CocoaCoordinateManager.shared
    
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
            
            for monitor in profile.monitors {
                if monitor.resolution == "builtin" || monitor.resolution == "macbook" {
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
                            position: WindowPosition,
                            sizing: String?,
                            targetMonitor: CocoaMonitorInfo,
                            appSettings: AppSettings?) {

        let pids = getAppPIDs(bundleID: bundleID)
        guard !pids.isEmpty else {
            print("  ❌ App not running: \(bundleID)")
            return
        }

        if position == .keep {
            print("  🔒 \(bundleID) has 'keep' position - skipping repositioning")
            return
        }

        // When multiple processes share a bundle ID (e.g. a visible Chrome and a
        // headless debug instance), try each PID until we find one with a moveable window.
        // hasMovableWindow checks without activation so no flicker on skipped processes.
        guard let pid = pids.first(where: { coordinateManager.hasMovableWindow(pid: $0) }) else {
            print("  ❌ No moveable window found for \(bundleID) across \(pids.count) process(es).")
            return
        }

        var actualWindowSize = AppConstants.defaultWindowSize
        if let currentPosition = coordinateManager.getWindowRect(pid: pid) {
            print("  Current position: \(coordinateManager.debugDescription(rect: currentPosition, label: "Current"))")

            if position == .center {
                let windowCenter = CGPoint(x: currentPosition.midX, y: currentPosition.midY)
                if targetMonitor.frame.contains(windowCenter) {
                    print("  📱 \(bundleID) is already on target screen, skipping repositioning")
                    return
                }
            }

            if sizing == "keep" || appSettings?.sizing == "keep" {
                actualWindowSize = currentPosition.size
            }
        }

        let calculatedPosition: CGPoint
        switch position {
        case .center:
            calculatedPosition = CGPoint(
                x: targetMonitor.visibleFrame.midX - actualWindowSize.width / 2,
                y: targetMonitor.visibleFrame.midY - actualWindowSize.height / 2
            )
        case .keep:
            return
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            calculatedPosition = coordinateManager.calculateQuadrantPosition(
                quadrant: position,
                windowSize: actualWindowSize,
                visibleFrame: targetMonitor.visibleFrame
            )
        }

        print("  Calculated Position: \(calculatedPosition) [Global]")
        coordinateManager.setWindowPosition(pid: pid, position: calculatedPosition, size: nil)

        if let finalPosition = coordinateManager.getWindowRect(pid: pid) {
            print("  Final position: \(coordinateManager.debugDescription(rect: finalPosition, label: "Final"))")
        }
    }
    
    // MARK: - Plan Generation
    
    func generatePlan(for profileName: String) -> ExecutionPlan? {
        guard let config = configManager.loadConfig(), let profile = config.profiles[profileName] else {
            print("Failed to load config or profile.")
            return nil
        }

        let allMonitors = coordinateManager.getAllMonitors(for: profileName)
        var actions: [AppAction] = []

        if let workspaceMonitorConfig = profile.monitors.first(where: { $0.position == .workspace }),
           let workspaceMonitor = coordinateManager.findWorkspaceMonitor(resolution: workspaceMonitorConfig.resolution),
           let layout = config.layout?.workspace {
            for (bundleID, workspaceApp) in layout {
                let action = createAppAction(bundleID: bundleID, position: workspaceApp.position, sizing: workspaceApp.sizing, targetMonitor: workspaceMonitor, appSettings: config.applications?[bundleID])
                actions.append(action)
            }
        }

        if let builtinApps = config.layout?.builtin,
           let builtinMonitor = allMonitors.first(where: { $0.isBuiltIn }) {
            for (bundleID, builtinApp) in builtinApps {
                let action = createAppAction(bundleID: bundleID, position: builtinApp.position, sizing: builtinApp.sizing, targetMonitor: builtinMonitor, appSettings: config.applications?[bundleID])
                actions.append(action)
            }
        }

        return ExecutionPlan(profileName: profileName, monitors: allMonitors, actions: actions)
    }

    private func createAppAction(bundleID: String, position: WindowPosition, sizing: String?, targetMonitor: CocoaMonitorInfo, appSettings: AppSettings?) -> AppAction {
        let currentPosition = getAppPIDs(bundleID: bundleID).first(where: { coordinateManager.hasMovableWindow(pid: $0) }).flatMap { coordinateManager.getWindowRect(pid: $0) }
        var actualWindowSize = currentPosition?.size ?? AppConstants.defaultWindowSize

        if sizing == "keep" || appSettings?.sizing == "keep" {
            if let currentSize = currentPosition?.size {
                actualWindowSize = currentSize
            }
        }

        let calculatedPosition = coordinateManager.calculateQuadrantPosition(quadrant: position, windowSize: actualWindowSize, visibleFrame: targetMonitor.visibleFrame)
        let targetRect = CGRect(origin: calculatedPosition, size: actualWindowSize)
        
        var actionType: ActionType = .move
        if position == .keep {
            actionType = .keep
        } else if let current = currentPosition {
            let tolerance = AppConstants.positioningTolerance
            if abs(current.origin.x - targetRect.origin.x) < tolerance && abs(current.origin.y - targetRect.origin.y) < tolerance {
                actionType = .keep
            }
        }

        let appName = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID })?.localizedName ?? bundleID

        return AppAction(
            bundleID: bundleID,
            appName: appName,
            currentPosition: currentPosition,
            targetPosition: targetRect,
            action: actionType
        )
    }
    
    // MARK: - Profile Application
    
    func applyProfile(_ profileName: String) {
        guard let config = configManager.loadConfig(), let profile = config.profiles[profileName] else {
            print("Failed to load config or profile.")
            return
        }

        // Remember which app had focus so we can restore it after positioning
        let previousApp = NSWorkspace.shared.frontmostApplication

        let allMonitors = coordinateManager.getAllMonitors(for: profileName)
        
        guard let workspaceMonitorConfig = profile.monitors.first(where: { $0.position == .workspace }) else {
            print("No workspace monitor found in profile")
            return
        }
        
        guard let workspaceMonitor = coordinateManager.findWorkspaceMonitor(resolution: workspaceMonitorConfig.resolution) else {
            print("Workspace monitor with resolution \(workspaceMonitorConfig.resolution) not found")
            return
        }
        
        if let layout = config.layout?.workspace {
            for (bundleID, workspaceApp) in layout {
                print("\nProcessing \(bundleID) for workspace position '\(workspaceApp.position)':")
                positionApp(
                    bundleID: bundleID,
                    position: workspaceApp.position,
                    sizing: workspaceApp.sizing,
                    targetMonitor: workspaceMonitor,
                    appSettings: config.applications?[bundleID]
                )
            }
        }
        
        if let builtinApps = config.layout?.builtin,
           let builtinMonitor = allMonitors.first(where: { $0.isBuiltIn }) {
            for (bundleID, builtinApp) in builtinApps {
                print("\n📱 Processing \(bundleID) for builtin screen (position: \(builtinApp.position.rawValue)):")
                positionApp(
                    bundleID: bundleID,
                    position: builtinApp.position,
                    sizing: builtinApp.sizing,
                    targetMonitor: builtinMonitor,
                    appSettings: config.applications?[bundleID]
                )
            }
        }

        // Restore focus to the app that was active before positioning
        if let previousApp = previousApp {
            previousApp.activate()
        }
    }

    // MARK: - Utility Functions
    
    /// Returns all PIDs for running apps with the given bundle ID, most recently
    /// launched first. Callers should try each PID in order and use the first
    /// one that has a moveable window.
    private func getAppPIDs(bundleID: String) -> [pid_t] {
        return NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier == bundleID }
            .sorted { $0.processIdentifier > $1.processIdentifier } // higher PID = more recent
            .map { $0.processIdentifier }
    }
    
    // MARK: - Profile Generation
    
    func updateProfile(name: String) {
        guard var config = ConfigManager.shared.loadConfig() else {
            print("Failed to load config.json")
            return
        }

        guard config.profiles[name] != nil else {
            print("Profile '\(name)' not found in config.json")
            return
        }

        let monitors = coordinateManager.getAllMonitors()
        let newMonitors = monitors.map { monitor in
            Monitor(resolution: monitor.resolution,
                    position: CocoaCoordinateManager.positionLabel(for: monitor))
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
            let role: MonitorRole
            if monitor.isBuiltIn {
                role = .builtin
            } else if index == 0 {
                role = .workspace
            } else {
                role = .left
            }
            
            generatedConfig += """
        {
          "resolution": "\(monitor.resolution)",
          "position": "\(role.rawValue)"
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
      "com.google.Chrome": { "position": "top_left" },
      "com.microsoft.teams2": { "position": "top_right" },
      "com.microsoft.Outlook": { "position": "bottom_left" },
      "com.slack.Slack": { "position": "bottom_right" }
    },
    "builtin": {
      "md.obsidian": { "position": "center" }
    }
  },
  "applications": {}
}
"""
        
        return generatedConfig
    }
}