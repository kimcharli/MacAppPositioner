import Foundation

/// Shared logger that tees all output to both stdout and a log file.
///
/// The log directory is read from the `log_directory` field in config.json
/// (supports `~` expansion). Falls back to `~/Documents/logs` when not set.
///
/// Call `AppLogger.shared.start(codeName:)` once at startup with `"cli"` or `"gui"`.
/// All subsequent `print()` calls (via the global override below) are automatically
/// written to the log file alongside stdout.
class AppLogger {
    static let shared = AppLogger()

    private var fileHandle: FileHandle?
    private(set) var logFilePath: String?
    private let queue = DispatchQueue(label: "com.macappositioner.logger")

    /// Default log directory when config.json has no `log_directory` key.
    private static let defaultLogDirectory = "~/Documents/logs"

    private init() {}

    // MARK: - Lifecycle

    /// Initialize logging session.
    /// Reads `log_directory` from config.json (lightweight pre-parse so we don't
    /// depend on the full ConfigManager which itself calls `print()`).
    /// Creates the directory if needed and opens a new log file
    /// named `<codeName>-<yyyyMMdd-HHmmss>.log`.
    func start(codeName: String) {
        let logDir = resolveLogDirectory()
        let logsURL = URL(fileURLWithPath: logDir)

        // Ensure directory exists
        try? FileManager.default.createDirectory(at: logsURL, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: Date())

        let logFile = logsURL.appendingPathComponent("\(codeName)-\(timestamp).log")
        logFilePath = logFile.path

        FileManager.default.createFile(atPath: logFile.path, contents: nil)
        fileHandle = FileHandle(forWritingAtPath: logFile.path)
        fileHandle?.seekToEndOfFile()

        // Header
        write("=== Mac App Positioner (\(codeName.uppercased())) — \(Date()) ===\n")
        Swift.print("📝 Logging to: \(logFile.path)")
    }

    /// Flush and close the current log file.
    func stop() {
        fileHandle?.synchronizeFile()
        fileHandle?.closeFile()
        fileHandle = nil
    }

    // MARK: - Writing

    /// Append a message to the log file (thread-safe).
    func write(_ message: String) {
        queue.sync {
            guard let data = message.data(using: .utf8) else { return }
            fileHandle?.write(data)
        }
    }

    // MARK: - Config Resolution

    /// Lightweight read of `log_directory` from config.json without going through
    /// ConfigManager (which itself calls `print()` and would recurse).
    private func resolveLogDirectory() -> String {
        let configPaths = [
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".config/mac-app-positioner/config.json"),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/MacAppPositioner/config.json"),
            URL(fileURLWithPath: "config.json")
        ]

        for url in configPaths {
            guard FileManager.default.fileExists(atPath: url.path),
                  let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dir = json["log_directory"] as? String else { continue }
            return Self.expandTilde(dir)
        }

        return Self.expandTilde(Self.defaultLogDirectory)
    }

    /// Expand a leading `~` to the current user's home directory.
    private static func expandTilde(_ path: String) -> String {
        guard path.hasPrefix("~") else { return path }
        return FileManager.default.homeDirectoryForCurrentUser.path
            + path.dropFirst() // drop the "~"
    }

    deinit {
        stop()
    }
}

// MARK: - Global print override

/// Shadows `Swift.print` so every existing `print()` call in the codebase
/// automatically writes to both stdout **and** the active log file.
/// No changes to call-sites required.
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
    AppLogger.shared.write(output + terminator)
}
