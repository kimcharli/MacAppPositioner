import Foundation

struct Layout: Codable {
    var primary: [String: String]
    var builtin: [String]
}

struct AppSettings: Codable {
    var positioningStrategy: String

    enum CodingKeys: String, CodingKey {
        case positioningStrategy = "positioning_strategy"
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
    func loadConfig() -> Config? {
        let url = URL(fileURLWithPath: "config.json")

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(Config.self, from: data)
            return config
        } catch {
            print("Error decoding config.json: \(error)")
            return nil
        }
    }
}
