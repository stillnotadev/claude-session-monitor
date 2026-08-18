import Foundation

/// User-configurable thresholds, stored at ~/.config/claude-sessions/config.json.
/// Edit that file directly (or use the "Edit thresholds config" menu item) to
/// tune this without touching code.
struct Config: Codable {
    var warningFreePercent: Int = 30
    var criticalFreePercent: Int = 15
    var diskWarningGB: Double = 20
    var diskCriticalGB: Double = 10
    var batteryWarningPercent: Int = 20
    var refreshIntervalSeconds: Double = 10

    static var path: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/claude-sessions")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("config.json")
    }

    static func load() -> Config {
        if let data = try? Data(contentsOf: path),
           let config = try? JSONDecoder().decode(Config.self, from: data) {
            return config
        }
        let defaultConfig = Config()
        defaultConfig.save()
        return defaultConfig
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: Config.path)
    }
}
