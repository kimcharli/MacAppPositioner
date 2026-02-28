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
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monitor Setup")
                .font(.headline)
            
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Detecting monitors...")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if viewModel.monitors.isEmpty {
                Text("No monitors detected")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.monitors) { monitor in
                            MonitorCardView(monitor: monitor)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 160)
                
                // Summary
                Text("\(viewModel.monitors.count) monitor(s) detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            viewModel.loadMonitorInfo()
        }
    }
}

/**
 * Individual monitor card component
 */
struct MonitorCardView: View {
    let monitor: CocoaMonitorInfo

    private var displayName: String {
        monitor.isBuiltIn ? "Built-in Display" : "External Display"
    }

    var body: some View {
        VStack(spacing: 8) {
            // Monitor visual representation
            ZStack {
                Rectangle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(width: 80, height: 50)
                    .overlay(
                        Rectangle()
                            .stroke(monitor.isWorkspace ? Color.purple : Color.gray, lineWidth: monitor.isWorkspace ? 3 : 2)
                    )
                    .cornerRadius(6)
                
                VStack(spacing: 2) {
                    Image(systemName: monitor.isBuiltIn ? "laptopcomputer" : "display")
                        .font(.title3)
                        .foregroundColor(monitor.isWorkspace ? .purple : .secondary)

                    if monitor.isWorkspace {
                        Text("Workspace")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                    }
                }
            }
            
            // Monitor details
            VStack(spacing: 2) {
                Text(displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                Text(monitor.resolution)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // Show badges for special monitor properties
                HStack(spacing: 4) {
                    if monitor.isWorkspace {
                        Text("4-Zone")
                            .font(.caption2)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(3)
                    }
                    
                    if monitor.scale > 1.0 {
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
        }
        .frame(width: 100)
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

struct MonitorVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorVisualizationView(viewModel: DashboardViewModel())
            .frame(width: 400)
            .padding()
    }
}