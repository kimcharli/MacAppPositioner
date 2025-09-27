import SwiftUI
import AppKit

/**
 * Main content view for the Mac App Positioner GUI
 * 
 * This view provides a user-friendly interface for:
 * - Viewing available profiles
 * - Detecting current monitor setup
 * - Applying window layouts
 * - Managing profile configurations
 */

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            ProfileManagerView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("Profiles")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

/**
 * Main dashboard view (original ContentView content)
 */
struct MainDashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Mac App Positioner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Automatic window positioning across multiple monitors")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            Divider()
            
            // Monitor Visualization Section
            MonitorVisualizationView(viewModel: viewModel)
            
            Divider()
            
            // Current Setup Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile Detection")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let detected = viewModel.detectedProfile {
                            Text("Detected Profile: \(detected)")
                                .font(.body)
                                .fontWeight(.medium)
                        } else {
                            Text("No matching profile detected")
                                .font(.body)
                                .foregroundColor(.orange)
                        }
                        
                        Button("Refresh Detection") {
                            viewModel.detectCurrentProfile()
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Available Profiles Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Available Profiles")
                    .font(.headline)
                
                if viewModel.profiles.isEmpty {
                    Text("No profiles found in config.json")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.profiles, id: \.self) { profileName in
                        ProfileRowView(
                            profileName: profileName,
                            isDetected: profileName == viewModel.detectedProfile,
                            onApply: {
                                viewModel.applyProfile(profileName)
                            },
                            onPlan: {
                                viewModel.generateAndShowPlan(for: profileName)
                            }
                        )
                    }
                }
            }
            
            Divider()
            
            // Status Section
            VStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(minHeight: 40)
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 500)
        .onAppear {
            viewModel.loadProfiles()
            viewModel.detectCurrentProfile()
        }
    }
}

/**
 * Individual profile row component
 */
struct ProfileRowView: View {
    let profileName: String
    let isDetected: Bool
    let onApply: () -> Void
    let onPlan: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profileName)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if isDetected {
                        Text("(Current)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Button("Plan") {
                onPlan()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            Button("Apply Layout") {
                onApply()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

struct ExecutionPlanView: View {
    let plan: ExecutionPlan
    private let coordinateManager = CocoaCoordinateManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Execution Plan for \(plan.profileName)")
                .font(.title)
                .fontWeight(.bold)

            Text("Monitors:")
                .font(.headline)
            ForEach(plan.monitors, id: \.resolution) { monitor in
                Text("  - \(monitor.resolution) (Workspace: \(monitor.isWorkspace ? "Yes" : "No"), Built-in: \(monitor.isBuiltIn ? "Yes" : "No"))")
            }

            Text("App Actions:")
                .font(.headline)
            
            ScrollView {
                ForEach(plan.actions, id: \.bundleID) { action in
                    VStack(alignment: .leading) {
                        Text("  - \(action.appName):")
                            .fontWeight(.medium)
                        Text("    Action: \(action.action.rawValue)")
                        if let current = action.currentPosition {
                            Text("    Current: \(coordinateManager.debugDescription(rect: current, label: "", system: "Accessibility"))")
                        }
                        Text("    Target:  \(coordinateManager.debugDescription(rect: action.targetPosition, label: "", system: "Accessibility"))")
                    }
                    .padding(.bottom, 8)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
    }
}


// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}