import Foundation
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var profiles: [String] = []
    @Published var detectedProfile: String? = nil
    @Published var statusMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var monitors: [CocoaMonitorInfo] = []
    @Published var planToShow: ExecutionPlan? = nil
    
    private var planWindow: NSWindow?

    private let profileManager = CocoaProfileManager()

    func loadProfiles() {
        switch AppUtils.loadProfileNames() {
        case .success(let names):
            profiles = names
            statusMessage = "Loaded \(profiles.count) profile(s)"
        case .failure(let error):
            profiles = []
            statusMessage = "Error: \(error.localizedDescription)"
        }
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
            // Note: profileManager.applyProfile calls NSRunningApplication.activate(options:)
            // which requires the main thread for reliable behavior.
            DispatchQueue.main.sync {
                self.profileManager.applyProfile(profileName)
            }

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
            let currentProfile = self.profileManager.detectProfile()
            let detectedMonitors = CocoaCoordinateManager.shared.getAllMonitors(for: currentProfile)

            DispatchQueue.main.async {
                self.monitors = detectedMonitors
                self.isLoading = false
            }
        }
    }
}
