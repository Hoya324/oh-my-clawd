import Foundation

/// Every file the app touches. Mirrors runtime/lib/paths.mjs.
///
///   ~/.claude/pet/
///     pet-state.json     aggregator → app
///     progress.json      aggregator only (stats, unlocks)
///     selection.json     app only (selected accessories)
///     usage-cache.json   app + HUD (shared usage API cache)
///     clawd-memory.json  app only (memos, reminders, chat)
///     runtime/           installed copy of the Node scripts
enum Paths {
    static let home = NSHomeDirectory()
    static let claudeDir = home + "/.claude"
    static let petDir = claudeDir + "/pet"

    static let petState = petDir + "/pet-state.json"
    static let progress = petDir + "/progress.json"
    static let selection = petDir + "/selection.json"
    static let usageCache = petDir + "/usage-cache.json"
    static let memory = petDir + "/clawd-memory.json"
    static let memoryBackupDir = petDir + "/backups"

    static let runtimeDir = petDir + "/runtime"
    static let hudScript = runtimeDir + "/hud.mjs"
    static let aggregatorScript = runtimeDir + "/pet-aggregator.mjs"

    static let claudeSettings = claudeDir + "/settings.json"
    static let launchAgentLabel = "com.claude.clawd-aggregator"
    static let launchAgentPlist = home + "/Library/LaunchAgents/\(launchAgentLabel).plist"
    static let logsDir = home + "/Library/Logs/OhMyClawd"

    static func ensurePetDir() {
        try? FileManager.default.createDirectory(
            atPath: petDir, withIntermediateDirectories: true
        )
    }
}

/// Small JSON file helpers. Writes are atomic (temp file + rename), so a
/// reader never sees a half-written file.
enum JSONFile {
    static func read(_ path: String) -> Data? {
        FileManager.default.contents(atPath: path)
    }

    static func readObject(_ path: String) -> [String: Any]? {
        guard let data = read(path) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    @discardableResult
    static func writeAtomic(_ data: Data, to path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    static func writeObject(_ object: Any, to path: String, pretty: Bool = true) -> Bool {
        var options: JSONSerialization.WritingOptions = []
        if pretty { options.insert(.prettyPrinted) }
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: options) else {
            return false
        }
        return writeAtomic(data, to: path)
    }
}
