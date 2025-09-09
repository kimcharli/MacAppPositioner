import Foundation
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var profiles: [String] = []
    @Published var detectedProfile: String? = nil
    @Published var statusMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var monitors: [MonitorInfo] = []

    private let profileManager = CocoaProfileManager()
    private let configManager = ConfigManager()

    func loadProfiles() {
        guard let config = configManager.loadConfig() else {
            statusMessage = "Error: config.json not found or invalid."
            return
        }
        profiles = Array(config.profiles.keys).sorted()
        statusMessage = "Loaded \(profiles.count) profile(s)"
    }

    func detectCurrentProfile() {
        isLoading = true
        statusMessage = "Detecting current setup..."

        DispatchQueue.global(qos: .userInitiated).async {
            let detected = self.profileManager.detectProfile()

            DispatchQueue.main.async {
                self.detectedProfile = detected
                self.isLoading = false

                if let detected = detected {
                    self.statusMessage = "✅ Detected profile: \(detected)"
                } else {
                    self.statusMessage = "❌ No matching profile for current monitor setup"
                }
            }
        }
    }

    func applyProfile(_ profileName: String) {
        isLoading = true
        statusMessage = "Applying \(profileName) profile..."

        DispatchQueue.global(qos: .userInitiated).async {
            self.profileManager.applyProfile(profileName)

            DispatchQueue.main.async {
                self.isLoading = false
                self.statusMessage = "✅ Applied \(profileName) profile"
            }
        }
    }

    func loadMonitorInfo() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let detectedMonitors = self.detectCurrentMonitors()

            DispatchQueue.main.async {
                self.monitors = detectedMonitors
                self.isLoading = false
            }
        }
    }

    private func detectCurrentMonitors() -> [MonitorInfo] {
        var monitorInfos: [MonitorInfo] = []
        let cocoaCoordinateManager = CocoaCoordinateManager.shared
        let configManager = ConfigManager()
        let profileManager = CocoaProfileManager()
        
        let currentProfile = profileManager.detectProfile()
        
        let cocoaMonitors = cocoaCoordinateManager.getAllMonitors(for: currentProfile)
        
        let config = configManager.loadConfig()
        var primaryResolution: String? = nil
        
        if let profile = currentProfile,
           let profileConfig = config?.profiles[profile] {
            primaryResolution = profileConfig.monitors.first(where: { $0.position == "primary" })?.resolution
        }
        
        for (index, cocoaMonitor) in cocoaMonitors.enumerated() {
            let displayName = cocoaMonitor.isBuiltIn ? "Built-in Display" : "External Display"
            
            let isWorkspace = cocoaMonitor.isWorkspace
            let isPrimary = primaryResolution != nil && AppUtils.normalizeResolution(cocoaMonitor.resolution) == AppUtils.normalizeResolution(primaryResolution!)
            
            let monitor = MonitorInfo(
                id: index,
                name: displayName,
                resolution: cocoaMonitor.resolution,
                width: cocoaMonitor.frame.width,
                height: cocoaMonitor.frame.height,
                originX: cocoaMonitor.frame.origin.x,
                originY: cocoaMonitor.frame.origin.y,
                isBuiltIn: cocoaMonitor.isBuiltIn,
                isPrimary: isPrimary,
                isWorkspace: isWorkspace,
                backingScaleFactor: cocoaMonitor.scale
            )
            
            monitorInfos.append(monitor)
        }
        
        return monitorInfos
    }
}
