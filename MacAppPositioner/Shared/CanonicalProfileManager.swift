import Foundation
import AppKit

/**
 * Profile Manager using Canonical Coordinate System
 * 
 * ARCHITECTURE PRINCIPLE:
 * - ALL calculations done in canonical Quartz coordinates
 * - ALL stored coordinates are canonical Quartz coordinates  
 * - NO coordinate system mixing or guessing
 */

class CanonicalProfileManager {
    
    private let configManager = ConfigManager()
    private let coordinateManager = CanonicalCoordinateManager.shared
    
    // MARK: - Profile Detection
    
    func detectProfile() -> String? {
        guard let config = configManager.loadConfig() else {
            print("Failed to load config")
            return nil
        }

        let monitors = coordinateManager.getAllMonitors()
        let currentResolutions = Set(monitors.map { $0.resolution })

        for (profileName, profile) in config.profiles {
            var profileResolutions: Set<String> = []
            var hasMacbook = false
            
            for monitor in profile.monitors {
                if monitor.resolution == "macbook" {
                    hasMacbook = true
                } else {
                    profileResolutions.insert(monitor.resolution)
                }
            }

            if hasMacbook {
                if let builtIn = monitors.first(where: { $0.isBuiltIn }) {
                    profileResolutions.insert(builtIn.resolution)
                }
            }

            if currentResolutions == profileResolutions {
                return profileName
            }
        }
        
        return nil
    }
    
    // MARK: - Profile Application
    
    func applyProfile(name: String) {
        print("🎯 CANONICAL ProfileManager: applyProfile called")  // Debug marker
        
        // Debug all monitors in global canonical coordinates
        let allMonitors = coordinateManager.getAllMonitors()
        print("=== All Monitors in Global Canonical ===")
        for (index, monitor) in allMonitors.enumerated() {
            print("Monitor \(index + 1): \(monitor.resolution)")
            print("  Frame: \(coordinateManager.debugDescription(rect: monitor.frame, label: "Frame"))")
            print("  isMain: \(monitor.isMain), isPrimary: \(monitor.isPrimary)")
        }
        guard let config = configManager.loadConfig() else {
            print("Failed to load config")
            return
        }

        guard let profile = config.profiles[name] else {
            print("Profile '\(name)' not found")
            return
        }

        // Find the primary monitor from the config
        guard let primaryMonitorConfig = profile.monitors.first(where: { $0.position == "primary" }) else {
            print("Primary monitor not defined in profile '\(name)'")
            return
        }

        // Find the corresponding monitor in canonical coordinates
        guard let primaryMonitor = coordinateManager.findPrimaryMonitor(resolution: primaryMonitorConfig.resolution) else {
            print("Primary monitor with resolution \(primaryMonitorConfig.resolution) not found")
            return
        }

        print("=== Global Canonical Coordinate System Debug ===")
        print("Primary Monitor (Global Canonical coordinates - relative to main display 0,0):")
        print("  Frame: \(coordinateManager.debugDescription(rect: primaryMonitor.frame, label: "Frame"))")
        print("  Visible Frame: \(coordinateManager.debugDescription(rect: primaryMonitor.visibleFrame, label: "Visible Frame"))")
        print("")

        guard let layout = config.layout?.primary else {
            print("No primary layout defined")
            return
        }

        for (positionName, bundleIdentifier) in layout {
            print("Processing \(bundleIdentifier) for position '\(positionName)':")
            
            let runningApps = NSWorkspace.shared.runningApplications
            guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
                print("  Application not running: \(bundleIdentifier)")
                continue
            }
            
            let pid = app.processIdentifier
            
            guard let currentWindow = coordinateManager.getWindowPosition(pid: pid) else {
                print("  Could not get window for \(bundleIdentifier)")
                continue
            }
            
            print("  Current position: \(coordinateManager.debugDescription(rect: currentWindow.rect, label: "Current"))")
            
            // Calculate new position in canonical coordinates
            let newPosition = calculateQuadrantPosition(
                quadrant: positionName,
                windowSize: currentWindow.size,
                visibleFrame: primaryMonitor.visibleFrame
            )
            
            guard let targetPosition = newPosition else {
                print("  Unknown position: \(positionName)")
                continue
            }
            
            print("  Target position: \(coordinateManager.debugDescription(rect: CGRect(origin: targetPosition, size: currentWindow.size), label: "Target"))")
            
            // Set window position (already in canonical Quartz - no conversion needed)
            let success = coordinateManager.setWindowPosition(pid: pid, globalCanonicalPosition: targetPosition)
            
            if success {
                print("  ✅ Successfully moved \(bundleIdentifier)")
                
                // Verify final position
                if let finalWindow = coordinateManager.getWindowPosition(pid: pid) {
                    print("  Final position: \(coordinateManager.debugDescription(rect: finalWindow.rect, label: "Final"))")
                }
            } else {
                print("  ❌ Failed to move \(bundleIdentifier)")
            }
            print("")
        }
    }
    
    // MARK: - Position Calculation (Pure Canonical Coordinates)
    
    /**
     * Calculate quadrant position using ONLY canonical Quartz coordinates
     * Input: Canonical coordinates
     * Output: Canonical coordinates  
     * NO coordinate system conversion
     */
    private func calculateQuadrantPosition(quadrant: String, windowSize: CGSize, visibleFrame: CGRect) -> CGPoint? {
        // All calculations in canonical Quartz coordinates (top-left origin)
        let quadrantWidth = visibleFrame.width / 2
        let quadrantHeight = visibleFrame.height / 2
        
        print("    Quadrant Calculation (Canonical Quartz):")
        print("    Visible Frame: \(coordinateManager.debugDescription(rect: visibleFrame, label: "Visible"))")
        print("    Quadrant Size: \(quadrantWidth) x \(quadrantHeight)")
        print("    Window Size: \(windowSize)")
        
        var targetPosition: CGPoint
        
        switch quadrant {
        case "top_left":
            // Top-left quadrant: origin at visibleFrame top-left
            targetPosition = CGPoint(
                x: visibleFrame.minX + (quadrantWidth - windowSize.width) / 2,
                y: visibleFrame.minY + (quadrantHeight - windowSize.height) / 2
            )
            
        case "top_right":
            // Top-right quadrant: origin at top-right of left quadrant
            targetPosition = CGPoint(
                x: visibleFrame.minX + quadrantWidth + (quadrantWidth - windowSize.width) / 2,
                y: visibleFrame.minY + (quadrantHeight - windowSize.height) / 2
            )
            
        case "bottom_left":
            // Bottom-left quadrant: origin at bottom-left of top quadrant  
            targetPosition = CGPoint(
                x: visibleFrame.minX + (quadrantWidth - windowSize.width) / 2,
                y: visibleFrame.minY + quadrantHeight + (quadrantHeight - windowSize.height) / 2
            )
            
        case "bottom_right":
            // Bottom-right quadrant: origin at bottom-right intersection
            targetPosition = CGPoint(
                x: visibleFrame.minX + quadrantWidth + (quadrantWidth - windowSize.width) / 2,
                y: visibleFrame.minY + quadrantHeight + (quadrantHeight - windowSize.height) / 2
            )
            
        default:
            print("    Unknown quadrant: \(quadrant)")
            return nil
        }
        
        print("    Calculated Position: (\(targetPosition.x), \(targetPosition.y)) [Canonical Quartz]")
        return targetPosition
    }
    
    // MARK: - Profile Management
    
    func updateProfile(name: String) {
        guard var config = configManager.loadConfig() else {
            print("Failed to load config")
            return
        }

        guard var profile = config.profiles[name] else {
            print("Profile '\(name)' not found")
            return
        }

        // Get current monitors in canonical coordinates
        let monitors = coordinateManager.getAllMonitors()
        
        var newMonitors: [Monitor] = []

        for monitor in monitors {
            var resolution = monitor.resolution
            var position = ""
            
            // Handle built-in display
            if monitor.isBuiltIn {
                resolution = "macbook"
            }
            
            // Determine position based on monitor arrangement
            // Note: This logic may need refinement based on your setup
            if monitor.isMain {
                position = "primary"
            } else {
                // Simple position logic - could be enhanced
                position = "secondary"
            }
            
            newMonitors.append(Monitor(resolution: resolution, position: position))
        }
        
        profile.monitors = newMonitors
        config.profiles[name] = profile
        
        // Save the updated config back to the file
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(config)
            let url = URL(fileURLWithPath: "config.json")
            try data.write(to: url)
            print("Successfully updated profile '\(name)' in config.json")
        } catch {
            print("Error saving updated config: \(error)")
        }
    }
    
    func generateConfig() {
        print("\"monitors\": [")
        
        let monitors = coordinateManager.getAllMonitors()
        
        for monitor in monitors {
            var resolution = monitor.resolution
            var position = ""
            
            if monitor.isBuiltIn {
                resolution = "macbook"
            }
            
            if monitor.isMain {
                position = "primary"
            } else {
                position = "secondary"
            }

            print("  {")
            print("    \"resolution\": \"\(resolution)\",")
            print("    \"position\": \"\(position)\"")
            print("  },")
        }
        print("]")
    }
}