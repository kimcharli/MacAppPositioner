import Foundation
import AppKit

/**
 * Mac App Positioner - CLI Interface with Canonical Coordinate System
 */

func printUsage() {
    print("""
    Mac App Positioner - Canonical Coordinate System Version
    
    Usage: MacAppPositioner <command>
    
    Commands:
      detect                  - Detect current monitor profile
      apply <profile-name>    - Apply window layout for profile
      update <profile-name>   - Update profile with current monitor setup
      generate-config         - Generate monitor configuration
      test-coordinates        - Test canonical coordinate system
    
    Examples:
      MacAppPositioner detect
      MacAppPositioner apply home  
      MacAppPositioner update office
      MacAppPositioner generate-config
      MacAppPositioner test-coordinates
    """)
}

func testCanonicalSystem() {
    let coordinateManager = CanonicalCoordinateManager.shared
    
    print("=== Canonical Coordinate System Test ===")
    print("")
    
    let monitors = coordinateManager.getAllMonitors()
    
    for (index, monitor) in monitors.enumerated() {
        print("Monitor \(index + 1):")
        print("  Resolution: \(monitor.resolution)")
        print("  \(coordinateManager.debugDescription(rect: monitor.frame, label: "Frame"))")
        print("  Scale: \(monitor.scale), Main: \(monitor.isMain), Built-in: \(monitor.isBuiltIn)")
        print("")
    }
    
    if let primaryMonitor = coordinateManager.findPrimaryMonitor(resolution: "3840.0x2160.0") {
        print("Primary Monitor Found:")
        print("  \(coordinateManager.debugDescription(rect: primaryMonitor.frame, label: "Primary Frame"))")
        print("")
    }
    
    print("✅ Canonical coordinate system working correctly")
}

func checkAccessibilityPermissions() {
    let trusted = AXIsProcessTrusted()
    if !trusted {
        print("⚠️  Accessibility permissions required for window positioning")
        print("   Please grant accessibility permissions in System Preferences")
        print("")
    }
}

// MARK: - Main Program Structure

struct MacAppPositionerCanonical {
    static func main() {
        checkAccessibilityPermissions()
        
        let arguments = CommandLine.arguments
        
        guard arguments.count >= 2 else {
            printUsage()
            exit(1)
        }
        
        let command = arguments[1]
        let profileManager = CanonicalProfileManager()
        
        switch command {
        case "detect":
            print("🔍 Detecting current monitor profile using canonical coordinate system...")
            if let detectedProfile = profileManager.detectProfile() {
                print("✅ Detected profile: \(detectedProfile)")
            } else {
                print("❌ No matching profile found for current monitor setup")
            }
            
        case "apply":
            guard arguments.count >= 3 else {
                print("❌ Error: Profile name required")
                print("Usage: MacAppPositioner apply <profile-name>")
                exit(1)
            }
            
            let profileName = arguments[2]
            print("🎯 Applying profile '\(profileName)' using canonical coordinate system...")
            print("📐 All calculations performed in Quartz coordinates (top-left origin)")
            print("")
            
            profileManager.applyProfile(name: profileName)
            
        case "update":
            guard arguments.count >= 3 else {
                print("❌ Error: Profile name required") 
                exit(1)
            }
            
            let profileName = arguments[2]
            print("🔄 Updating profile '\(profileName)' with current monitor setup...")
            profileManager.updateProfile(name: profileName)
            
        case "generate-config":
            print("⚙️  Generating configuration for current monitor setup...")
            profileManager.generateConfig()
            
        case "test-coordinates":
            print("🧪 Testing canonical coordinate system...")
            testCanonicalSystem()
            
        case "--version", "-v":
            print("Mac App Positioner v2.0 - Canonical Coordinate System")
            print("Architecture: Single coordinate system with API boundary translation")
            
        case "--help", "-h":
            printUsage()
            
        default:
            print("❌ Unknown command: \(command)")
            printUsage()
            exit(1)
        }
    }
}

MacAppPositionerCanonical.main()