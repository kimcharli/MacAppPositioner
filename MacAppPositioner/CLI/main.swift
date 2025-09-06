import AppKit

/**
 * Mac App Positioner - Command Line Interface
 *
 * A native macOS application that automatically positions application windows
 * according to predefined layouts across multiple monitors.
 *
 * Usage: MacAppPositioner <command> [profile_name]
 * Commands:
 *   - detect: Find matching profile for current monitor setup
 *   - apply: Apply window layout from specified profile
 *   - update: Update profile with current monitor configuration
 *   - generate-config: Generate configuration template for current setup
 */

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

/**
 * Application delegate that handles command-line interface functionality.
 * Processes commands immediately on launch and terminates.
 */
class AppDelegate: NSObject, NSApplicationDelegate {
    
    /**
     * Main application entry point. Processes command-line arguments and executes
     * the appropriate ProfileManager operations.
     *
     * @param aNotification: Application launch notification (unused)
     */
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let args = CommandLine.arguments
        
        // Validate minimum argument count
        if args.count < 2 {
            printUsage()
            NSApp.terminate(nil)
            return
        }

        let command = args[1]
        let profileName = (args.count > 2) ? args[2] : nil
        let profileManager = CanonicalProfileManager()

        // Execute requested command
        switch command {
        case "detect":
            executeDetectCommand(profileManager)
            
        case "apply":
            executeApplyCommand(profileManager, profileName: profileName)
            
        case "update":
            executeUpdateCommand(profileManager, profileName: profileName)
            
        case "generate-config":
            executeGenerateConfigCommand(profileManager)
            
        default:
            print("Unknown command: \(command)")
            printUsage()
        }
        
        // Terminate after command execution
        NSApp.terminate(nil)
    }
    
    // MARK: - Command Execution Methods
    
    /**
     * Executes profile detection command.
     * Identifies which configured profile matches the current monitor setup.
     */
    private func executeDetectCommand(_ profileManager: CanonicalProfileManager) {
        if let detectedProfile = profileManager.detectProfile() {
            print("Detected profile: \(detectedProfile)")
        } else {
            print("No matching profile detected.")
        }
    }
    
    /**
     * Executes profile application command.
     * Positions running applications according to the specified profile's layout.
     */
    private func executeApplyCommand(_ profileManager: CanonicalProfileManager, profileName: String?) {
        if let name = profileName {
            profileManager.applyProfile(name: name)
        } else {
            print("Please specify a profile name to apply.")
            printUsage()
        }
    }
    
    /**
     * Executes profile update command.
     * Updates an existing profile with the current monitor configuration.
     */
    private func executeUpdateCommand(_ profileManager: CanonicalProfileManager, profileName: String?) {
        if let name = profileName {
            profileManager.updateProfile(name: name)
        } else {
            print("Please specify a profile name to update.")
            printUsage()
        }
    }
    
    /**
     * Executes configuration generation command.
     * Outputs JSON configuration template for the current monitor setup.
     */
    private func executeGenerateConfigCommand(_ profileManager: CanonicalProfileManager) {
        profileManager.generateConfig()
    }
    
    // MARK: - Helper Methods
    
    /**
     * Prints command usage information.
     */
    private func printUsage() {
        print("Usage: MacAppPositioner <command> [profile_name]")
        print("")
        print("Commands:")
        print("  detect                    - Find matching profile for current monitor setup")
        print("  apply <profile_name>      - Apply window layout from specified profile")
        print("  update <profile_name>     - Update profile with current monitor configuration")  
        print("  generate-config           - Generate configuration template for current setup")
        print("")
        print("Examples:")
        print("  MacAppPositioner detect")
        print("  MacAppPositioner apply office")
        print("  MacAppPositioner update home")
        print("  MacAppPositioner generate-config")
    }
}

// Launch the application
app.run()
