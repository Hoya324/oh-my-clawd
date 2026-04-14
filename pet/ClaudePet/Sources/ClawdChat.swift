import Foundation

// ============================================================================
// MARK: - Response types
// ============================================================================

enum ClawdActionType: String, Codable {
    case addMemo       = "add_memo"
    case completeMemo  = "complete_memo"
    case deleteMemo    = "delete_memo"
    case setReminder   = "set_reminder"
    case unknown
}

struct ClawdAction: Codable {
    let type: String
    let text: String?
    let dueAt: String?
    let tags: [String]?
    let id: String?
    let kind: String?
    let enabled: Bool?
    let intervalMin: Int?
    let timeOfDay: String?

    var typed: ClawdActionType {
        ClawdActionType(rawValue: type) ?? .unknown
    }
}

struct ClawdResponse: Codable {
    let actions: [ClawdAction]
    let reply: String
}

enum ClawdChatError: Error {
    case cliNotFound
    case processFailed(String)
    case timeout
    case parseFailed(raw: String)
}

// ============================================================================
// MARK: - Bridge
// ============================================================================

final class ClawdChat {
    static let modelId = "claude-haiku-4-5"
    private let timeoutSeconds: TimeInterval = 10
    private let memory: ClawdMemoryStore

    init(memory: ClawdMemoryStore) {
        self.memory = memory
    }

    /// Runs `claude -p` on a background thread and completes on the main queue.
    func send(userText: String,
              completion: @escaping (Result<ClawdResponse, ClawdChatError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let result = self.runBlocking(userText: userText)
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - Internal

    private func runBlocking(userText: String) -> Result<ClawdResponse, ClawdChatError> {
        guard let claudePath = Self.resolveClaudePath() else {
            return .failure(.cliNotFound)
        }

        let file = memory.read()
        let systemPrompt = Self.buildSystemPrompt(file: file)
        let stdinPayload = systemPrompt + "\n\nUser: " + userText + "\n"

        let task = Process()
        task.launchPath = claudePath
        task.arguments = [
            "-p",
            "--model", Self.modelId,
            "--output-format", "json",
        ]
        // GUI-launched apps get a minimal environment. Give claude a PATH that
        // covers the common install locations so it can find node/helpers.
        var env = ProcessInfo.processInfo.environment
        let home = NSHomeDirectory()
        let extraPaths = [
            "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin",
            home + "/.bun/bin", home + "/.local/bin", home + "/.npm-global/bin",
            (claudePath as NSString).deletingLastPathComponent,
        ]
        let existingPath = env["PATH"] ?? ""
        env["PATH"] = (extraPaths + [existingPath]).filter { !$0.isEmpty }
            .joined(separator: ":")
        env["HOME"] = home
        task.environment = env

        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        task.standardInput = stdin
        task.standardOutput = stdout
        task.standardError = stderr

        do {
            try task.run()
        } catch {
            return .failure(.processFailed("launch: \(error.localizedDescription)"))
        }

        stdin.fileHandleForWriting.write(stdinPayload.data(using: .utf8) ?? Data())
        try? stdin.fileHandleForWriting.close()

        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while task.isRunning {
            if Date() > deadline {
                task.terminate()
                return .failure(.timeout)
            }
            Thread.sleep(forTimeInterval: 0.05)
        }

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        let outStr = String(data: outData, encoding: .utf8) ?? ""
        let errStr = String(data: errData, encoding: .utf8) ?? ""

        guard task.terminationStatus == 0 else {
            return .failure(.processFailed("exit \(task.terminationStatus): \(errStr.prefix(200))"))
        }

        return Self.extractResponse(from: outStr)
    }

    private static let cachePath = NSHomeDirectory() + "/.claude/pet/clawd-cli-path.txt"
    private static let resolveLock = NSLock()
    private static var cachedPath: String?

    /// Public: call once at app launch to warm the cache. Non-blocking.
    static func warmUpClaudePath(completion: ((String?) -> Void)? = nil) {
        DispatchQueue.global(qos: .utility).async {
            let p = resolveClaudePath()
            DispatchQueue.main.async { completion?(p) }
        }
    }

    static func resolveClaudePath() -> String? {
        resolveLock.lock()
        defer { resolveLock.unlock() }

        if let p = cachedPath,
           FileManager.default.isExecutableFile(atPath: p) { return p }

        if let cached = try? String(contentsOfFile: cachePath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !cached.isEmpty,
           FileManager.default.isExecutableFile(atPath: cached) {
            cachedPath = cached
            return cached
        }

        let found = scanKnownLocations() ?? scanViaShell() ?? scanViaSpotlight()
        if let p = found {
            cachedPath = p
            try? p.write(toFile: cachePath, atomically: true, encoding: .utf8)
        }
        return found
    }

    private static func scanKnownLocations() -> String? {
        let home = NSHomeDirectory()
        let candidates = [
            home + "/.claude/local/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            home + "/.local/bin/claude",
            home + "/.bun/bin/claude",
            home + "/.npm-global/bin/claude",
            "/Applications/cmux.app/Contents/Resources/bin/claude",
            home + "/Applications/cmux.app/Contents/Resources/bin/claude",
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Ask interactive zsh/bash to resolve `claude` from the user's shell init.
    /// GUI-launched apps don't inherit terminal PATH, so we ask the shell itself.
    private static func scanViaShell() -> String? {
        for shell in ["/bin/zsh", "/bin/bash"] {
            guard FileManager.default.isExecutableFile(atPath: shell) else { continue }
            let proc = Process()
            proc.launchPath = shell
            proc.arguments = ["-ilc", "command -v claude"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = Pipe()
            do { try proc.run() } catch { continue }
            proc.waitUntilExit()
            guard proc.terminationStatus == 0 else { continue }
            let out = String(
                data: pipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            )?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let p = out, !p.isEmpty,
               FileManager.default.isExecutableFile(atPath: p) {
                return p
            }
        }
        return nil
    }

    /// Last-resort Spotlight scan. Slow, so only hit when other probes fail.
    private static func scanViaSpotlight() -> String? {
        let proc = Process()
        proc.launchPath = "/usr/bin/mdfind"
        proc.arguments = [
            "kMDItemFSName == 'claude' && kMDItemContentType == 'public.unix-executable'"
        ]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do { try proc.run() } catch { return nil }
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        let out = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        let lines = out.split(separator: "\n").map(String.init)
        return lines.first {
            $0.hasSuffix("/bin/claude") &&
            FileManager.default.isExecutableFile(atPath: $0)
        } ?? lines.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    // MARK: - Prompt

    private static func buildSystemPrompt(file: ClawdMemoryFile) -> String {
        let now = Date()
        let tz = TimeZone.current.identifier
        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime]
        let nowIso = isoFmt.string(from: now)

        let remindersJson = (try? JSONEncoder().encode(file.reminders))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let openMemos = file.memos.filter { !$0.done }.suffix(10)
        let memosJson = (try? JSONEncoder().encode(Array(openMemos)))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let recentChat = file.chatLog.suffix(6)
        let chatJson = (try? JSONEncoder().encode(Array(recentChat)))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        return """
        You are Clawd, a pixel-art mascot living in the user's macOS menu bar. \
        Help the user remember things, nudge good habits, and occasionally chat. \
        Reply in the user's language (default 한국어).

        You MUST respond with a single JSON object, no prose, no code fences:
        {"actions": Action[], "reply": string}

        Supported actions (ignore unknown fields, emit none if not needed):
          - add_memo      { "text": string, "dueAt": ISO8601 | null, "tags": string[] }
          - complete_memo { "id": string }
          - delete_memo   { "id": string }
          - set_reminder  { "kind": "water"|"stretch"|"diary",
                            "enabled": bool?,
                            "intervalMin": number?,
                            "timeOfDay": "HH:mm"? }

        If the user asks a general question (weather, news, facts), you may \
        use your web tools and put the answer in `reply` with actions: []. \
        Do not create memos the user did not ask for. Keep `reply` to 1–2 \
        warm sentences.

        Current time: \(nowIso) (\(tz)).
        Resolve relative times ("3시", "내일 오전 10시", "30분 뒤") to absolute ISO8601 \
        in the user's timezone. If ambiguous, leave dueAt null and ask in `reply`.

        Current reminders: \(remindersJson)
        Open memos (newest last, up to 10): \(memosJson)
        Recent chat (last 6, oldest first): \(chatJson)
        """
    }

    // MARK: - Response extraction

    static func extractResponse(from cliOutput: String) -> Result<ClawdResponse, ClawdChatError> {
        guard let data = cliOutput.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(.parseFailed(raw: cliOutput))
        }
        let assistantText: String
        if let s = root["result"] as? String {
            assistantText = s
        } else if let msgs = root["messages"] as? [[String: Any]],
                  let last = msgs.last,
                  let content = last["content"] as? String {
            assistantText = content
        } else {
            return .failure(.parseFailed(raw: cliOutput))
        }

        let cleaned = stripFences(assistantText)
        guard let body = cleaned.data(using: .utf8),
              let response = try? JSONDecoder().decode(ClawdResponse.self, from: body) else {
            return .failure(.parseFailed(raw: assistantText))
        }
        return .success(response)
    }

    private static func stripFences(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            if let firstNL = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: firstNL)...])
            }
            if t.hasSuffix("```") {
                t = String(t.dropLast(3))
            }
            t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return t
    }
}
