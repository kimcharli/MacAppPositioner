import SwiftUI
import AppKit

/**
 * SettingsView provides application preferences and configuration options
 * 
 * This view allows users to:
 * - Configure application preferences
 * - View system information and requirements
 * - Access help and documentation
 * - Configure accessibility settings
 */

struct SettingsView: View {
    @State private var launchAtLogin = false
    @State private var showNotifications = true
    @State private var defaultProfile = "Auto-detect"
    @State private var statusMessage = ""
    
    private let availableProfiles = ["Auto-detect", "home", "office"] // This would be loaded from config
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            // General Settings
            GroupBox("General") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Launch at login", isOn: $launchAtLogin)
                    
                    Toggle("Show notifications", isOn: $showNotifications)
                    
                    HStack {
                        Text("Default profile:")
                        Spacer()
                        Picker("Default profile", selection: $defaultProfile) {
                            ForEach(availableProfiles, id: \.self) { profile in
                                Text(profile).tag(profile)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                }
                .padding()
            }
            
            // Accessibility Settings
            GroupBox("Accessibility") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Accessibility permissions are required for window positioning")
                    }
                    
                    HStack(spacing: 12) {
                        Button("Open System Preferences") {
                            openAccessibilityPreferences()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Test Accessibility") {
                            testAccessibility()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            
            // System Information
            GroupBox("System Information") {
                VStack(alignment: .leading, spacing: 8) {
                    SystemInfoRowView(title: "macOS Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
                    SystemInfoRowView(title: "Monitors Detected", value: "\(NSScreen.screens.count)")
                    SystemInfoRowView(title: "Main Display", value: getMainDisplayInfo())
                    SystemInfoRowView(title: "Config Location", value: "config.json")
                }
                .padding()
            }
            
            // Help and Support
            GroupBox("Help & Support") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Button("View Documentation") {
                            openDocumentation()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Report Issue") {
                            openIssueTracker()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Generate Debug Info") {
                            generateDebugInfo()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("Version 1.0.0 - Built with Swift & SwiftUI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Status Message
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: 600)
    }
    
    // MARK: - Actions
    
    private func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        statusMessage = "Opened System Preferences - Add MacAppPositionerGUI to Accessibility list"
    }
    
    private func testAccessibility() {
        // Test if we can access running applications
        let runningApps = NSWorkspace.shared.runningApplications
        let testApp = runningApps.first { $0.bundleIdentifier == "com.apple.finder" }
        
        if let app = testApp {
            // Test accessibility by trying to access window attributes
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var windows: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows)
            
            if result == .success {
                statusMessage = "✅ Accessibility working correctly"
            } else {
                statusMessage = "❌ Accessibility permissions may be missing"
            }
        } else {
            statusMessage = "Unable to test accessibility - Finder not running"
        }
    }
    
    private func openDocumentation() {
        // In a real implementation, this would open the docs folder or website
        statusMessage = "Documentation would open here (docs/ folder)"
    }
    
    private func openIssueTracker() {
        // In a real implementation, this would open GitHub issues or support system
        statusMessage = "Issue tracker would open here"
    }
    
    private func generateDebugInfo() {
        let debugInfo = """
        Mac App Positioner Debug Information
        =====================================
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Monitors: \(NSScreen.screens.count)
        Main Display: \(getMainDisplayInfo())
        Running Apps: \(NSWorkspace.shared.runningApplications.count)
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(debugInfo, forType: .string)
        
        statusMessage = "Debug information copied to clipboard"
    }
    
    private func getMainDisplayInfo() -> String {
        let builtinScreen = CocoaCoordinateManager.shared.getBuiltinScreen()
        let frame = builtinScreen.frame
        let scale = builtinScreen.backingScaleFactor
        return "\(Int(frame.width))x\(Int(frame.height)) @\(scale)x"
    }
}

/**
 * System information row component
 */
struct SystemInfoRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}