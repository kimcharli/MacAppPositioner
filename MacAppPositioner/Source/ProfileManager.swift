import Foundation
import AppKit

class ProfileManager {

    let configManager = ConfigManager()
    let windowManager = WindowManager()
    let coordinateManager = CoordinateManager()

    func updateProfile(name: String) {
        guard var config = configManager.loadConfig() else {
            print("Failed to load config")
            return
        }

        guard var profile = config.profiles[name] else {
            print("Profile '\(name)' not found")
            return
        }

        var newMonitors: [Monitor] = []
        guard let primaryScreen = NSScreen.main else {
            print("Could not get main screen")
            return
        }

        for screen in NSScreen.screens {
            var resolution = "\(screen.frame.width)x\(screen.frame.height)"
            var position = ""
            if screen.frame.origin.x < primaryScreen.frame.origin.x {
                position = "left"
            } else if screen.frame.origin.x > primaryScreen.frame.origin.x {
                position = "right"
            } else {
                position = "secondary"
            }
            if screen.backingScaleFactor > 1.0 {
                resolution = "macbook"
            }
            newMonitors.append(Monitor(resolution: resolution, position: position))
        }
        
        profile.monitors = newMonitors
        config.profiles[name] = profile
        
        // Now save the updated config back to the file
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
        guard let primaryScreen = NSScreen.main else {
            print("Could not get main screen")
            print("]")
            return
        }

        for screen in NSScreen.screens {
            var resolution = "\(screen.frame.width)x\(screen.frame.height)"
            var position = ""
            if screen.backingScaleFactor > 1.0 {
                resolution = "macbook"
            }
            if screen.frame.origin.x < primaryScreen.frame.origin.x {
                position = "left"
            } else if screen.frame.origin.x > primaryScreen.frame.origin.x {
                position = "right"
            } else {
                // This could be improved to handle more complex layouts
                position = "secondary"
            }

            print("  {")
            print("    \"resolution\": \"\(resolution)\",")
            print("    \"position\": \"\(position)\"")
            print("  },")
        }
        print("]")
    }

    func detectProfile() -> String? {
        guard let config = configManager.loadConfig() else {
            print("Failed to load config")
            return nil
        }

        let currentScreens = NSScreen.screens
        let currentResolutions = Set(currentScreens.map { "\($0.frame.width)x\($0.frame.height)" })

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
                if let builtIn = currentScreens.first(where: { $0.backingScaleFactor > 1.0 }) {
                    profileResolutions.insert("\(builtIn.frame.width)x\(builtIn.frame.height)")
                }
            }

            if currentResolutions == profileResolutions {
                return profileName
            }
        }
        
        return nil
    }

    func applyProfile(name: String) {
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
            print("Primary monitor not defined in profile '\(name)'" )
            return
        }

        // Find the corresponding NSScreen object
        guard let primaryScreen = NSScreen.screens.first(where: { "\($0.frame.width)x\($0.frame.height)" == primaryMonitorConfig.resolution }) else {
            print("Primary monitor with resolution \(primaryMonitorConfig.resolution) not found")
            return
        }

        let screenFrame = primaryScreen.visibleFrame

        if let layout = config.layout?.primary {
            for (positionName, bundleIdentifier) in layout {
                let runningApps = NSWorkspace.shared.runningApplications
                if let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) {
                    let pid = app.processIdentifier
                    
                    if let (initialPosition, size) = windowManager.getWindowFrame(pid: pid) {
                        print("Initial position of \(bundleIdentifier): \(initialPosition)")

                        var newPositionCocoa = CGPoint.zero
                        switch positionName {
                        case "top_left":
                            newPositionCocoa = CGPoint(x: screenFrame.minX, y: screenFrame.maxY - size.height)
                        case "top_right":
                            newPositionCocoa = CGPoint(x: screenFrame.maxX - size.width, y: screenFrame.maxY - size.height)
                        case "bottom_left":
                            newPositionCocoa = CGPoint(x: screenFrame.minX, y: screenFrame.minY)
                        case "bottom_right":
                            newPositionCocoa = CGPoint(x: screenFrame.maxX - size.width, y: screenFrame.minY)
                        default:
                            print("Unknown position: \(positionName)")
                        }
                        
                        let windowRectCocoa = CGRect(origin: newPositionCocoa, size: size)
                        let windowRectQuartz = coordinateManager.translateRectFromCocoaToQuartz(rect: windowRectCocoa)
                        
                        print("Moving \(bundleIdentifier) to \(windowRectQuartz.origin)")
                        let success = windowManager.setWindowPosition(pid: pid, position: windowRectQuartz.origin)
                        
                        if success {
                            print("  ✅ Successfully moved \(bundleIdentifier)")
                        } else {
                            print("  ❌ Failed to move \(bundleIdentifier)")
                        }

                        if let (finalPosition, _) = windowManager.getWindowFrame(pid: pid) {
                            print("  Final position of \(bundleIdentifier): \(finalPosition)")
                        }
                    }
                }
            }
        }
    }
}
