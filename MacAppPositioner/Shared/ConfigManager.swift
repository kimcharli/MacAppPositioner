import Foundation

struct BuiltinApp: Codable {
    var position: String? = "center"  // "center" (default), "keep", or specific position
    var sizing: String? = "keep"      // "keep" (default) or specific size
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if (try? container.decode(String.self)) != nil {
            // Handle legacy string format (just bundle ID)
            position = "center"
            sizing = "keep"
        } else {
            // Handle new dictionary format
            let dictContainer = try decoder.container(keyedBy: CodingKeys.self)
            position = try dictContainer.decodeIfPresent(String.self, forKey: .position) ?? "center"
            sizing = try dictContainer.decodeIfPresent(String.self, forKey: .sizing) ?? "keep"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case position = "position"
        case sizing = "sizing"
    }
}

struct WorkspaceApp: Codable {
    var position: String  // "top_left", "top_right", "bottom_left", "bottom_right", or "keep"
    var sizing: String? = "keep"    // "keep" (default) or specific size
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            // Handle legacy string format (just position like "top_left")
            position = stringValue
            sizing = "keep"
        } else {
            // Handle new dictionary format
            let dictContainer = try decoder.container(keyedBy: CodingKeys.self)
            position = try dictContainer.decode(String.self, forKey: .position)
            sizing = try dictContainer.decodeIfPresent(String.self, forKey: .sizing) ?? "keep"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case position = "position"
        case sizing = "sizing"
    }
}

struct Layout: Codable {
    var workspace: [String: WorkspaceApp]?
    var builtin: [String: BuiltinApp]?
    
    enum CodingKeys: String, CodingKey {
        case workspace = "workspace"
        case builtin = "builtin"
    }
}

struct AppSettings: Codable {
    var positioningStrategy: String?  // Special positioning behavior (e.g., "chrome")
    var positioning: String?  // Override: "keep" to prevent repositioning
    var sizing: String? = "keep"  // Override: "keep" (default) to prevent resizing

    enum CodingKeys: String, CodingKey {
        case positioningStrategy = "positioning_strategy"
        case positioning = "positioning"
        case sizing = "sizing"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        positioningStrategy = try container.decodeIfPresent(String.self, forKey: .positioningStrategy)
        positioning = try container.decodeIfPresent(String.self, forKey: .positioning)
        sizing = try container.decodeIfPresent(String.self, forKey: .sizing) ?? "keep"
    }
}

struct Monitor: Codable {
    var resolution: String
    var position: String
}

struct Profile: Codable {
    var monitors: [Monitor]
}

struct Config: Codable {
    var layout: Layout?
    var applications: [String: AppSettings]
    var profiles: [String: Profile]
}

class ConfigManager {
    static let shared = ConfigManager() // Singleton instance
    private var cachedConfig: Config? // Cache for the loaded configuration

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
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let config = try decoder.decode(Config.self, from: data)
                    print("Loaded config from: \(url.path)")
                    cachedConfig = config // Cache the loaded config
                    return config
                } catch {
                    print("Error decoding config at \(url.path): \(error)")
                }
            }
        }
        
        print("Config not found in any standard location")
        print("Searched paths:")
        for path in configPaths {
            print("  - \(path.path)")
        }
        return nil
    }

    func saveConfig(_ config: Config) -> Bool {
        // When saving, also update the cache
        cachedConfig = config
        
        let url = URL(fileURLWithPath: "config.json")
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
