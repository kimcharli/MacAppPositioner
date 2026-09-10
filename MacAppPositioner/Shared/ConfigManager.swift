import Foundation

// MARK: - Enums

/// Typed window positions used in layout configuration.
enum WindowPosition: String, Codable {
    case topLeft     = "top_left"
    case topRight    = "top_right"
    case bottomLeft  = "bottom_left"
    case bottomRight = "bottom_right"
    case center      = "center"
    case keep        = "keep"
}

/// The role a physical monitor plays within a profile.
enum MonitorRole: String, Codable {
    case workspace = "workspace"
    case builtin   = "builtin"
    case secondary = "secondary"
    case left      = "left"
    case right     = "right"
}

// MARK: - Layout Entry

/// Unified layout entry for both workspace and built-in monitor apps.
/// Replaces the former `BuiltinApp` / `WorkspaceApp` split.
struct AppLayoutEntry: Codable {
    var position: WindowPosition = .center
    var sizing: String? = "keep"

    /// Explicit memberwise init: declaring `init(from:)` below suppresses the
    /// synthesized one, and config generation needs to construct entries directly.
    init(position: WindowPosition, sizing: String? = "keep") {
        self.position = position
        self.sizing = sizing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            // Legacy string format: value is the position string
            position = WindowPosition(rawValue: stringValue) ?? .center
            sizing = "keep"
        } else {
            let dictContainer = try decoder.container(keyedBy: CodingKeys.self)
            position = try dictContainer.decodeIfPresent(WindowPosition.self, forKey: .position) ?? .center
            sizing   = try dictContainer.decodeIfPresent(String.self, forKey: .sizing) ?? "keep"
        }
    }

    enum CodingKeys: String, CodingKey {
        case position
        case sizing
    }
}

struct Layout: Codable {
    var workspace: [String: AppLayoutEntry]?
    var builtin: [String: AppLayoutEntry]?

    enum CodingKeys: String, CodingKey {
        case workspace = "workspace"
        case builtin   = "builtin"
    }
}

/// Per-application overrides, independent of any layout section.
///
/// Only `sizing` is honoured. A `positioning` key was decoded here for a long
/// time but never read by anything; it was removed rather than implemented
/// because `layout.<section>.<bundleID>.position: "keep"` already expresses the
/// same intent and *is* acted on. See LayoutEngine.resolve.
struct AppSettings: Codable {
    var sizing: String? = "keep"  // Override: "keep" (default) to prevent resizing

    enum CodingKeys: String, CodingKey {
        case sizing = "sizing"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sizing = try container.decodeIfPresent(String.self, forKey: .sizing) ?? "keep"
    }
}

struct Monitor: Codable {
    var resolution: String
    var position: MonitorRole
}

struct Profile: Codable {
    var monitors: [Monitor]
}

struct Config: Codable {
    var layout: Layout?
    var applications: [String: AppSettings]?
    var profiles: [String: Profile]
    var log_directory: String?
}

// MARK: - Protocol

protocol ConfigManaging: AnyObject {
    func loadConfig() -> Config?
    @discardableResult func saveConfig(_ config: Config) -> Bool
    func invalidateCache()
}

// MARK: - ConfigManager

class ConfigManager: ConfigManaging {
    static let shared = ConfigManager() // Singleton instance
    private var cachedConfig: Config?   // Cache for the loaded configuration
    private var loadedConfigURL: URL?   // URL that was successfully loaded

    private init() {} // Private initializer to enforce singleton pattern

    func loadConfig() -> Config? {
        if let config = cachedConfig {
            // print("Returning cached config.") // Optional: for debugging
            return config
        }

        // Try multiple locations for config.json
        let configPaths = [
            // 1. User's .config directory (standard location)
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".config")
                .appendingPathComponent("mac-app-positioner")
                .appendingPathComponent("config.json"),
            
            // 2. Application Support directory
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library")
                .appendingPathComponent("Application Support")
                .appendingPathComponent("MacAppPositioner")
                .appendingPathComponent("config.json"),
            
            // 3. Current directory (for CLI usage)
            URL(fileURLWithPath: "config.json"),
            
            // 4. Home directory
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".mac-app-positioner")
                .appendingPathComponent("config.json")
        ]
        
        for url in configPaths {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let config = try decoder.decode(Config.self, from: data)
                printDiagnostic("Loaded config from: \(url.path)")
                cachedConfig = config      // Cache the loaded config
                loadedConfigURL = url      // Remember where we loaded from
                return config
            } catch {
                // A file that exists but cannot be read is terminal. Falling
                // through to the "not found" branch would tell a user with a
                // one-character typo that their config is missing, when it was
                // found and rejected -- and would send them looking in the
                // wrong place, or silently pick up a stale config from a
                // lower-priority path.
                printDiagnostic("❌ Could not read the config at \(url.path)")
                printDiagnostic("   \(error)")
                printDiagnostic("   Fix this file, or move it aside to fall back to another location.")
                return nil
            }
        }

        printDiagnostic("Config not found in any standard location")
        printDiagnostic("Searched paths:")
        for path in configPaths {
            printDiagnostic("  - \(path.path)")
        }
        return nil
    }

    func invalidateCache() {
        cachedConfig = nil
    }

    func saveConfig(_ config: Config) -> Bool {
        // When saving, also update the cache
        cachedConfig = config

        // Write back to the same location we loaded from; fall back to cwd.
        let url = loadedConfigURL ?? URL(fileURLWithPath: "config.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(config)
            try data.write(to: url)
            return true
        } catch {
            print("Error encoding or writing config.json: \(error)")
            return false
        }
    }
}
