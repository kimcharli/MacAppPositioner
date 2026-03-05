import Foundation
import ApplicationServices
import AppKit

/**
 * Utility functions for MacAppPositioner application
 * 
 * This utility provides shared functions for:
 * - Resolution string normalization
 * - Profile loading and management
 * - Common operations across GUI components
 */

// MARK: - Constants

/// Application-wide constants. Add new shared magic numbers here instead of
/// scattering literals across files.
enum AppConstants {
    /// Fallback window size used when the current size cannot be determined.
    static let defaultWindowSize = CGSize(width: 1200, height: 800)

    /// Tolerance (in points) when comparing window positions for equality.
    static let positioningTolerance: CGFloat = 1.0
}

// MARK: - Errors

enum AppError: Error {
    case configLoadFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .configLoadFailed(let message):
            return message
        }
    }
}

class AppUtils {
    
    /**
     * Normalize resolution strings to handle both user-friendly and system formats
     * 
     * Converts various resolution formats to a consistent comparable format:
     * - "3440x1440" -> "3440x1440" (unchanged)
     * - "3440.0x1440.0" -> "3440x1440" (removes .0 suffixes)
     * - "3440 x 1440" -> "3440x1440" (removes spaces)
     * 
     * @param resolution: The resolution string to normalize
     * @returns: Normalized resolution string in "widthxheight" format
     */
    static func normalizeResolution(_ resolution: String) -> String {
        // Remove .0 suffixes and spaces to normalize to simple "widthxheight" format
        let cleaned = resolution
            .replacingOccurrences(of: ".0", with: "")
            .replacingOccurrences(of: " ", with: "")
        return cleaned
    }
    
    /**
     * Check if two resolution strings are equivalent after normalization
     * 
     * @param resolution1: First resolution string
     * @param resolution2: Second resolution string
     * @returns: True if the resolutions are equivalent after normalization
     */
    static func areResolutionsEquivalent(_ resolution1: String, _ resolution2: String) -> Bool {
        return normalizeResolution(resolution1) == normalizeResolution(resolution2)
    }
    
    // MARK: - Accessibility

    /// Check and log whether the app has Accessibility permission.
    /// Without it, AXUIElement calls silently fail and no windows can be moved.
    /// In GUI mode, shows an alert dialog with fix instructions when not granted.
    @discardableResult
    static func checkAccessibilityPermission(promptIfNeeded: Bool = false) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        let trusted = AXIsProcessTrustedWithOptions(options)
        if trusted {
            print("✅ Accessibility permission: granted")
        } else {
            print("⚠️  Accessibility permission: NOT granted — window positioning will fail")
            print("   To fix:")
            print("   1. Open System Settings > Privacy & Security > Accessibility")
            print("   2. Remove any existing MacAppPositionerGUI entry (select it, click '−')")
            print("   3. Click '+' and add /Applications/MacAppPositionerGUI.app")
            print("   4. Ensure the toggle is ON")
            print("   5. Quit and relaunch MacAppPositionerGUI")

            if promptIfNeeded {
                showAccessibilityAlert()
            }
        }
        return trusted
    }

    /// Show a macOS alert with step-by-step instructions to fix Accessibility permission.
    private static func showAccessibilityAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = """
            Mac App Positioner cannot move windows without Accessibility permission.

            To fix:
            1. Open System Settings > Privacy & Security > Accessibility
            2. Remove any existing MacAppPositionerGUI entry (click '−')
            3. Click '+' and add this app from /Applications/
            4. Make sure the toggle is ON
            5. Quit and relaunch this app
            """
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Dismiss")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Open System Settings > Privacy & Security > Accessibility
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    // MARK: - Profile Management Utilities
    
    /**
     * Load profile names from configuration
     * 
     * @returns: Result with sorted profile names or error
     */
    static func loadProfileNames() -> Result<[String], AppError> {
        let configManager = ConfigManager.shared
        guard let config = configManager.loadConfig() else {
            return .failure(.configLoadFailed("Failed to load config.json"))
        }
        
        let profileNames = Array(config.profiles.keys).sorted()
        return .success(profileNames)
    }
    
    /**
     * Load full profiles dictionary from configuration
     * 
     * @returns: Result with profiles dictionary or error
     */
    static func loadProfiles() -> Result<[String: Profile], AppError> {
        let configManager = ConfigManager.shared
        guard let config = configManager.loadConfig() else {
            return .failure(.configLoadFailed("Failed to load configuration"))
        }
        
        return .success(config.profiles)
    }
}