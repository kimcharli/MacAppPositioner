import Foundation
import AppKit

/**
 * Mac App Positioner - CLI Interface with Native Cocoa Coordinate System
 * REFERENCE: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Transforms/Transforms.html
 */

func printUsage() {
    print("""
    Mac App Positioner - Native Cocoa Coordinate System Version
    
    Usage: MacAppPositioner <command>
    
    Commands:
      detect                  - Detect current monitor profile
      apply [profile-name]    - Auto-detect and apply profile (or force specific profile)
      update <profile-name>   - Update profile with current monitor setup
      generate-config         - Generate monitor configuration
      test-coordinates        - Test native Cocoa coordinate system
    
    Examples:
      MacAppPositioner detect
      MacAppPositioner apply              # Auto-detect and apply
      MacAppPositioner apply office       # Force apply 'office' profile
      MacAppPositioner update office
      MacAppPositioner generate-config
      MacAppPositioner test-coordinates
    """)
}

func testNativeCocoaSystem() {
    print("=== Native Cocoa Coordinate System Test ===")
    
    let coordinateManager = CocoaCoordinateManager.shared
    let monitors = coordinateManager.getAllMonitors()
    
    print("\n📺 All Monitors (Native Cocoa Coordinates):")
    for (index, monitor) in monitors.enumerated() {
        print("Monitor \(index + 1): \(monitor.resolution)")
        print("  Frame: \(monitor.frame) [Native Cocoa]")
        print("  Visible Frame: \(monitor.visibleFrame) [Native Cocoa]")
        print("  isMain: \(monitor.isMain), isBuiltIn: \(monitor.isBuiltIn), isWorkspace: \(monitor.isWorkspace)")
    }
    
    if let mainScreen = NSScreen.main {
        print("\n🖥️ NSScreen.main (Native Cocoa):")
        print("  Frame: \(mainScreen.frame) [Native Cocoa]")
        print("  Visible Frame: \(mainScreen.visibleFrame) [Native Cocoa]")
    }
    
    let builtinScreen = CocoaCoordinateManager.shared.getBuiltinScreen()
    print("\n🖥️ Builtin Screen (Reliable Detection):")
    print("  Frame: \(builtinScreen.frame) [Native Cocoa]")
    print("  Visible Frame: \(builtinScreen.visibleFrame) [Native Cocoa]")
    
    print("\n✅ Native Cocoa coordinate system test completed")
    print("Note: All coordinates use bottom-left origin, Y increases upward")
}

// MARK: - Main Function

@main
struct MacAppPositioner {
    static func main() {
        let arguments = CommandLine.arguments
        
        guard arguments.count > 1 else {
            printUsage()
            exit(1)
        }
        
        let command = arguments[1]
        let profileManager = CocoaProfileManager()
        let configManager = ConfigManager()
        let coordinateManager = CocoaCoordinateManager.shared

        switch command {
            case "detect":
                if let profile = profileManager.detectProfile() {
                    print("✅ Detected profile: \(profile)")
                } else {
                    print("❌ No matching profile detected.")
                }
            case "plan":
                let profileToPlan: String?
                if arguments.count > 2 {
                    profileToPlan = arguments[2]
                } else {
                    profileToPlan = profileManager.detectProfile()
                }

                if let profileName = profileToPlan, let plan = profileManager.generatePlan(for: profileName) {
                    print("✅ Execution Plan for Profile: \(plan.profileName)")
                    print("\nMonitors:")
                    for monitor in plan.monitors {
                        print("  - \(monitor.resolution) (Workspace: \(monitor.isWorkspace), Built-in: \(monitor.isBuiltIn))")
                    }
                    print("\nApp Actions:")
                    for action in plan.actions {
                        print("  - \(action.appName):")
                        print("    Action: \(action.action.rawValue)")
                        if let current = action.currentPosition {
                            print("    Current: \(coordinateManager.debugDescription(rect: current, label: "", system: "Accessibility"))")
                        } else {
                            print("    Current: Not running or window not found")
                        }
                        print("    Target: \(coordinateManager.debugDescription(rect: action.targetPosition, label: "", system: "Accessibility"))")
                    }
                } else {
                    print("❌ Could not generate a plan. No matching profile detected or profile not found.")
                }
            case "apply":
            if arguments.count > 2 {
                // Force apply specified profile
                let profileName = arguments[2]
                if let config = configManager.loadConfig(), config.profiles[profileName] != nil {
                    print("📌 Force applying profile: \(profileName)")
                    profileManager.applyProfile(profileName)
                } else {
                    print("❌ Profile '\(profileName)' not found in config.json.")
                    if let config = configManager.loadConfig() {
                        let profiles = Array(config.profiles.keys)
                        if !profiles.isEmpty {
                            print("💡 Available profiles: \(profiles.joined(separator: ", "))")
                        }
                    }
                    exit(1)
                }
            } else {
                // Auto-detect and apply
                if let detectedProfile = profileManager.detectProfile() {
                    print("✅ Auto-detected profile: \(detectedProfile)")
                    print("🎯 Applying detected profile...")
                    profileManager.applyProfile(detectedProfile)
                } else {
                    print("❌ No matching profile detected for current monitor configuration.")
                    if let config = configManager.loadConfig() {
                        let profiles = Array(config.profiles.keys)
                        if !profiles.isEmpty {
                            print("💡 Available profiles can be forced with: apply <profile_name>")
                            print("💡 Available profiles: \(profiles.joined(separator: ", "))")
                        }
                    }
                    exit(1)
                }
            }
            
        case "update":
            guard arguments.count > 2 else {
                print("Usage: MacAppPositioner update <profile-name>")
                exit(1)
            }
            let profileName = arguments[2]
            profileManager.updateProfile(name: profileName)
            
        case "generate-config":
            let generatedConfig = profileManager.generateConfigForCurrentSetup()
            print("Generated configuration for current setup:")
            print(generatedConfig)
            
        case "test-coordinates":
            testNativeCocoaSystem()
            
        default:
            print("Unknown command: \(command)")
            printUsage()
            exit(1)
        }
    }
}