import Foundation

/// Installs and maintains the Node runtime that ships inside the app bundle
/// (Contents/Resources/runtime): the HUD status line and the aggregator
/// daemon. Before this, a DMG install had no aggregator at all, so Clawd
/// never saw any Claude Code session unless the user also ran install.sh.
final class RuntimeInstaller {
    enum AggregatorStatus: Equatable {
        case unknown
        case running
        /// Node.js not found. The app still works (usage, chat detection),
        /// only Claude Code session tracking is unavailable.
        case nodeMissing
        case failed(String)
    }

    private let fm = FileManager.default
    private let queue = DispatchQueue(label: "clawd.runtime", qos: .utility)

    /// Copy scripts and make sure the LaunchAgent runs. Completion on main.
    func ensureInstalled(completion: @escaping (AggregatorStatus) -> Void) {
        queue.async {
            let status = self.ensureInstalledSync()
            DispatchQueue.main.async { completion(status) }
        }
    }

    private func ensureInstalledSync() -> AggregatorStatus {
        Paths.ensurePetDir()
        let updated: Bool
        do {
            updated = try installRuntimeIfNeeded()
        } catch {
            return .failed("스크립트 설치 실패: \(error.localizedDescription)")
        }
        guard fm.fileExists(atPath: Paths.aggregatorScript) else {
            return .failed("aggregator 스크립트를 찾지 못했어요")
        }
        guard let node = Self.resolveNodePath() else { return .nodeMissing }
        return ensureLaunchAgent(node: node, restart: updated)
    }

    // MARK: - Runtime scripts

    private var bundledRuntime: String? {
        guard let res = Bundle.main.resourcePath else { return nil }
        let p = res + "/runtime"
        return fm.fileExists(atPath: p + "/pet-aggregator.mjs") ? p : nil
    }

    private var bundleVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "\(short)+\(build)"
    }

    /// Replace ~/.claude/pet/runtime when the bundled copy is a different
    /// version. Swap is atomic: a running HUD never sees a half-copied dir.
    /// Returns true when files changed.
    private func installRuntimeIfNeeded() throws -> Bool {
        guard let src = bundledRuntime else { return false }
        let versionFile = Paths.runtimeDir + "/.version"
        let installed = (try? String(contentsOfFile: versionFile, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if installed == bundleVersion && fm.fileExists(atPath: Paths.hudScript) { return false }

        let staging = Paths.petDir + "/.runtime-\(UUID().uuidString)"
        try fm.copyItem(atPath: src, toPath: staging)
        try bundleVersion.write(toFile: staging + "/.version", atomically: true, encoding: .utf8)

        if fm.fileExists(atPath: Paths.runtimeDir) {
            _ = try fm.replaceItemAt(URL(fileURLWithPath: Paths.runtimeDir),
                                     withItemAt: URL(fileURLWithPath: staging))
        } else {
            try fm.moveItem(atPath: staging, toPath: Paths.runtimeDir)
        }
        return true
    }

    // MARK: - LaunchAgent

    private func launchAgentPlist(node: String) -> [String: Any] {
        [
            "Label": Paths.launchAgentLabel,
            "ProgramArguments": [node, Paths.aggregatorScript],
            "KeepAlive": true,
            "RunAtLoad": true,
            "ProcessType": "Background",
            "ThrottleInterval": 10,
            "StandardOutPath": Paths.logsDir + "/aggregator.log",
            "StandardErrorPath": Paths.logsDir + "/aggregator.log",
        ]
    }

    private func ensureLaunchAgent(node: String, restart: Bool) -> AggregatorStatus {
        try? fm.createDirectory(atPath: Paths.logsDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: (Paths.launchAgentPlist as NSString).deletingLastPathComponent,
                                withIntermediateDirectories: true)

        let desired = launchAgentPlist(node: node)
        let current = NSDictionary(contentsOfFile: Paths.launchAgentPlist)
        let plistChanged = current == nil || !current!.isEqual(to: desired)
        let domain = "gui/\(getuid())"
        let service = "\(domain)/\(Paths.launchAgentLabel)"

        if plistChanged {
            guard let data = try? PropertyListSerialization.data(fromPropertyList: desired, format: .xml, options: 0),
                  JSONFile.writeAtomic(data, to: Paths.launchAgentPlist) else {
                return .failed("LaunchAgent 파일을 쓰지 못했어요")
            }
            _ = Self.run("/bin/launchctl", ["bootout", service])
            let r = Self.run("/bin/launchctl", ["bootstrap", domain, Paths.launchAgentPlist])
            if r.status != 0 && !Self.isLoaded(service) {
                return .failed("aggregator 실행 실패: \(r.output.prefix(120))")
            }
            return .running
        }

        if !Self.isLoaded(service) {
            let r = Self.run("/bin/launchctl", ["bootstrap", domain, Paths.launchAgentPlist])
            if r.status != 0 && !Self.isLoaded(service) {
                return .failed("aggregator 실행 실패: \(r.output.prefix(120))")
            }
        } else if restart {
            _ = Self.run("/bin/launchctl", ["kickstart", "-k", service])
        }
        return .running
    }

    private static func isLoaded(_ service: String) -> Bool {
        run("/bin/launchctl", ["print", service]).status == 0
    }

    // MARK: - Node

    /// GUI apps don't inherit the terminal PATH, so probe common install
    /// locations first and then ask the user's login shell.
    /// The login shell is the last resort and its answer is cached: running
    /// the user's shell init from the app can touch mounted volumes and make
    /// macOS show a "wants to access files on a network volume" prompt.
    static func resolveNodePath() -> String? {
        let fm = FileManager.default
        let home = Paths.home
        let cacheFile = Paths.petDir + "/node-path.txt"
        if let cached = (try? String(contentsOfFile: cacheFile, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !cached.isEmpty, fm.isExecutableFile(atPath: cached) {
            return cached
        }
        var candidates = [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/opt/homebrew/opt/node/bin/node",
            home + "/.volta/bin/node",
            home + "/.local/bin/node",
            home + "/.bun/bin/node",
            home + "/.asdf/shims/node",
            home + "/.local/share/mise/shims/node",
        ]
        // nvm: newest installed version first
        let nvm = home + "/.nvm/versions/node"
        if let versions = try? fm.contentsOfDirectory(atPath: nvm) {
            let sorted = versions.sorted { $0.compare($1, options: .numeric) == .orderedDescending }
            candidates += sorted.map { "\(nvm)/\($0)/bin/node" }
        }
        if let found = candidates.first(where: { fm.isExecutableFile(atPath: $0) }) {
            return found
        }
        for shell in ["/bin/zsh", "/bin/bash"] where fm.isExecutableFile(atPath: shell) {
            let r = run(shell, ["-ilc", "command -v node"], timeout: 8)
            let path = r.output.split(separator: "\n").last.map(String.init)?
                .trimmingCharacters(in: .whitespaces) ?? ""
            if r.status == 0, !path.isEmpty, fm.isExecutableFile(atPath: path) {
                try? path.write(toFile: cacheFile, atomically: true, encoding: .utf8)
                return path
            }
        }
        return nil
    }

    // MARK: - Process helper

    @discardableResult
    static func run(_ launchPath: String, _ args: [String], timeout: TimeInterval = 10) -> (status: Int32, output: String) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: launchPath)
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        do { try proc.run() } catch { return (-1, error.localizedDescription) }

        // Drain the pipe while the process runs: output larger than the
        // pipe buffer (e.g. `ps -axo args`) would otherwise block it.
        var data = Data()
        let reader = DispatchGroup()
        reader.enter()
        DispatchQueue.global(qos: .utility).async {
            data = pipe.fileHandleForReading.readDataToEndOfFile()
            reader.leave()
        }
        let deadline = Date().addingTimeInterval(timeout)
        while proc.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.05) }
        if proc.isRunning { proc.terminate() }
        proc.waitUntilExit()
        reader.wait()
        return (proc.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }
}

// ============================================================================
// MARK: - HUD status line toggle
// ============================================================================

/// Edits ~/.claude/settings.json safely:
///  - refuses to touch a file it cannot parse (it used to overwrite it with
///    `{}`, wiping every other setting),
///  - only removes a statusLine that oh-my-clawd installed,
///  - remembers a third-party statusLine and restores it on disable.
enum HudSettings {
    static let command = "bash -c 'node \"$HOME/.claude/pet/runtime/hud.mjs\"'"
    private static let backupPath = Paths.petDir + "/statusline-backup.json"

    enum ToggleError: Error {
        case unreadableSettings
        case writeFailed
    }

    static func isOurs(_ cmd: String) -> Bool {
        cmd.contains(".claude/pet/runtime/hud.mjs")
            || cmd.contains("oh-my-clawd")
            || cmd == "bash -c 'node \"$HOME/.claude-hud/hud.mjs\"'"   // ≤ 2.1.8 app toggle
    }

    private static func currentCommand(_ json: [String: Any]) -> String? {
        (json["statusLine"] as? [String: Any])?["command"] as? String
    }

    static func isEnabled() -> Bool {
        guard let json = JSONFile.readObject(Paths.claudeSettings),
              let cmd = currentCommand(json) else { return false }
        return isOurs(cmd)
    }

    /// nil = file missing (treated as empty); throws when present but unparsable.
    private static func loadSettings() throws -> [String: Any] {
        guard let data = JSONFile.read(Paths.claudeSettings) else { return [:] }
        if data.isEmpty { return [:] }
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw ToggleError.unreadableSettings
        }
        return obj
    }

    private static func save(_ json: [String: Any]) throws {
        let opts: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: opts),
              JSONFile.writeAtomic(data, to: Paths.claudeSettings) else {
            throw ToggleError.writeFailed
        }
    }

    static func setEnabled(_ enabled: Bool) throws {
        var json = try loadSettings()
        let existing = json["statusLine"]

        if enabled {
            if let cmd = currentCommand(json), !isOurs(cmd), let existing = existing {
                JSONFile.writeObject(["statusLine": existing], to: backupPath)
            }
            json["statusLine"] = ["type": "command", "command": command]
        } else {
            guard let cmd = currentCommand(json), isOurs(cmd) else { return }
            if let backup = JSONFile.readObject(backupPath)?["statusLine"] {
                json["statusLine"] = backup
                try? FileManager.default.removeItem(atPath: backupPath)
            } else {
                json.removeValue(forKey: "statusLine")
            }
        }
        try save(json)
    }
}
