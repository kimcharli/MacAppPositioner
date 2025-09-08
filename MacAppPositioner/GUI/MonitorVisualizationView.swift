import SwiftUI
import AppKit

/**
 * MonitorVisualizationView displays the current monitor setup graphically
 * 
 * This view shows:
 * - All connected displays with their resolutions
 * - Physical arrangement of monitors
 * - Which monitor is designated as primary
 * - Built-in display identification
 */

struct MonitorVisualizationView: View {
    @State private var monitors: [MonitorInfo] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monitor Setup")
                .font(.headline)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Detecting monitors...")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if monitors.isEmpty {
                Text("No monitors detected")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(monitors, id: \.id) { monitor in
                            MonitorCardView(monitor: monitor)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 160)
                
                // Summary
                Text("\(monitors.count) monitor(s) detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadMonitorInfo()
        }
    }
    
    private func loadMonitorInfo() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let detectedMonitors = detectCurrentMonitors()
            
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
        
        // Get monitor info using native Cocoa coordinates
        let cocoaMonitors = cocoaCoordinateManager.getAllMonitors()
        
        // Load config to determine which monitor is primary according to config
        let config = configManager.loadConfig()
        let primaryMonitorResolution = config?.profiles.values.first?.monitors.first(where: { $0.position == "primary" })?.resolution
        
        for (index, cocoaMonitor) in cocoaMonitors.enumerated() {
            let displayName = cocoaMonitor.isBuiltIn ? "Built-in Display" : "External Display"
            
            // Check if this monitor is primary according to config (not NSScreen.main)
            let isPrimaryFromConfig = cocoaMonitor.resolution == primaryMonitorResolution
            
            let monitor = MonitorInfo(
                id: index,
                name: displayName,
                resolution: cocoaMonitor.resolution,
                width: cocoaMonitor.frame.width,
                height: cocoaMonitor.frame.height,
                originX: cocoaMonitor.frame.origin.x,
                originY: cocoaMonitor.frame.origin.y,
                isBuiltIn: cocoaMonitor.isBuiltIn,
                isPrimary: isPrimaryFromConfig,  // Use config-defined primary, not NSScreen.main
                backingScaleFactor: cocoaMonitor.scale
            )
            
            monitorInfos.append(monitor)
        }
        
        return monitorInfos
    }
}

/**
 * Individual monitor card component
 */
struct MonitorCardView: View {
    let monitor: MonitorInfo
    
    var body: some View {
        VStack(spacing: 8) {
            // Monitor visual representation
            ZStack {
                Rectangle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 80, height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(monitor.isPrimary ? Color.blue : Color.gray, lineWidth: 2)
                    )
                    .cornerRadius(6)
                
                VStack(spacing: 2) {
                    Image(systemName: monitor.isBuiltIn ? "laptopcomputer" : "display")
                        .font(.title3)
                        .foregroundColor(monitor.isPrimary ? .blue : .secondary)
                    
                    if monitor.isPrimary {
                        Text("Primary")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Monitor details
            VStack(spacing: 2) {
                Text(monitor.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(monitor.resolution)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if monitor.backingScaleFactor > 1.0 {
                    Text("Retina")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(3)
                }
            }
        }
        .frame(width: 100)
        .padding(.vertical, 8)
    }
}

/**
 * Data structure for monitor information
 */
struct MonitorInfo {
    let id: Int
    let name: String
    let resolution: String
    let width: CGFloat
    let height: CGFloat
    let originX: CGFloat
    let originY: CGFloat
    let isBuiltIn: Bool
    let isPrimary: Bool
    let backingScaleFactor: CGFloat
}

// MARK: - Preview

struct MonitorVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorVisualizationView()
            .frame(width: 400)
            .padding()
    }
}