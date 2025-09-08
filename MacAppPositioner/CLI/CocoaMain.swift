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
      apply <profile-name>    - Apply window layout for profile
      update <profile-name>   - Update profile with current monitor setup
      generate-config         - Generate monitor configuration
      test-coordinates        - Test native Cocoa coordinate system
    
    Examples:
      MacAppPositioner detect
      MacAppPositioner apply home  
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
        
        switch command {
        case "detect":
            if let profile = profileManager.detectProfile() {
                print("Detected profile: \(profile)")
            } else {
                print("No matching profile found")
                print("\nRun 'generate-config' to create a configuration for your current setup")
            }
            
        case "apply":
            guard arguments.count > 2 else {
                print("Usage: MacAppPositioner apply <profile-name>")
                exit(1)
            }
            let profileName = arguments[2]
            profileManager.applyProfile(profileName)
            
        case "update":
            guard arguments.count > 2 else {
                print("Usage: MacAppPositioner update <profile-name>")
                exit(1)
            }
            let profileName = arguments[2]
            print("Update functionality coming soon for profile: \(profileName)")
            
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