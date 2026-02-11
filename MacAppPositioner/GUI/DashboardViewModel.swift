import Foundation
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var profiles: [String] = []
    @Published var detectedProfile: String? = nil
    @Published var statusMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var monitors: [MonitorInfo] = []
    @Published var planToShow: ExecutionPlan? = nil
    
    private var planWindow: NSWindow?

    private let profileManager = CocoaProfileManager()
    private let configManager = ConfigManager.shared

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
    
    func generateAndShowPlan(for profileName: String) {
        isLoading = true
        statusMessage = "Generating plan for \(profileName)..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let plan = self.profileManager.generatePlan(for: profileName)
            
            DispatchQueue.main.async {
                self.planToShow = plan
                self.isLoading = false
                if let plan = plan {
                    self.statusMessage = "✅ Plan generated for \(profileName)"
                    self.showPlanInWindow(plan: plan)
                } else {
                    self.statusMessage = "❌ Could not generate plan for \(profileName)"
                }
            }
        }
    }
    
    private func showPlanInWindow(plan: ExecutionPlan) {
        if planWindow == nil {
            let planView = ExecutionPlanView(plan: plan)
            let hostingView = NSHostingView(rootView: planView)
            
            planWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            planWindow?.center()
            planWindow?.contentView = hostingView
            planWindow?.title = "Execution Plan for \(plan.profileName)"
            planWindow?.isReleasedWhenClosed = false // Important to manage window lifecycle
        }
        
        planWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
        let profileManager = CocoaProfileManager()
        
        let currentProfile = profileManager.detectProfile()
        
        let cocoaMonitors = cocoaCoordinateManager.getAllMonitors(for: currentProfile)
        
        for (index, cocoaMonitor) in cocoaMonitors.enumerated() {
            let displayName = cocoaMonitor.isBuiltIn ? "Built-in Display" : "External Display"

            let monitor = MonitorInfo(
                id: index,
                name: displayName,
                resolution: cocoaMonitor.resolution,
                width: cocoaMonitor.frame.width,
                height: cocoaMonitor.frame.height,
                originX: cocoaMonitor.frame.origin.x,
                originY: cocoaMonitor.frame.origin.y,
                isBuiltIn: cocoaMonitor.isBuiltIn,
                isWorkspace: cocoaMonitor.isWorkspace,
                backingScaleFactor: cocoaMonitor.scale
            )
            
            monitorInfos.append(monitor)
        }
        
        return monitorInfos
    }
}
