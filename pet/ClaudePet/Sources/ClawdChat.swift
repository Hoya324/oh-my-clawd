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
    /// Relative due time ("3분 뒤"); the app turns it into an absolute time.
    let dueInMinutes: Int?

    var typed: ClawdActionType {
        ClawdActionType(rawValue: type) ?? .unknown
    }

    enum CodingKeys: String, CodingKey {
        case type, text, dueAt, tags, id, kind, enabled, intervalMin, timeOfDay, dueInMinutes
    }

    init(type: String, text: String?, dueAt: String?, tags: [String]?, id: String?,
         kind: String?, enabled: Bool?, intervalMin: Int?, timeOfDay: String?,
         dueInMinutes: Int? = nil) {
        self.type = type
        self.text = text
        self.dueAt = dueAt
        self.tags = tags
        self.id = id
        self.kind = kind
        self.enabled = enabled
        self.intervalMin = intervalMin
        self.timeOfDay = timeOfDay
        self.dueInMinutes = dueInMinutes
    }

    /// The model is not a schema validator: accept the shapes it actually
    /// emits ("tags": "점심", "intervalMin": "120", "enabled": "true",
    /// "dueAt": "") instead of rejecting the whole reply.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(String.self, forKey: .type)
        text = Self.string(c, .text)
        let due = Self.string(c, .dueAt)
        dueAt = (due?.isEmpty ?? true) ? nil : due
        id = Self.string(c, .id)
        kind = Self.string(c, .kind)?.lowercased()
        timeOfDay = Self.string(c, .timeOfDay)

        if let arr = try? c.decode([String].self, forKey: .tags) {
            tags = arr
        } else if let one = Self.string(c, .tags), !one.isEmpty {
            tags = one.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        } else {
            tags = nil
        }

        if let b = try? c.decode(Bool.self, forKey: .enabled) {
            enabled = b
        } else if let s = Self.string(c, .enabled)?.lowercased() {
            enabled = ["true", "on", "yes", "1"].contains(s) ? true
                : (["false", "off", "no", "0"].contains(s) ? false : nil)
        } else {
            enabled = nil
        }

        if let n = try? c.decode(Int.self, forKey: .intervalMin) {
            intervalMin = n
        } else if let d = try? c.decode(Double.self, forKey: .intervalMin) {
            intervalMin = Int(d.rounded())
        } else if let s = Self.string(c, .intervalMin), let n = Int(s) {
            intervalMin = n
        } else {
            intervalMin = nil
        }

        dueInMinutes = Self.integer(c, .dueInMinutes)
    }

    private static func integer(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int? {
        if let n = try? c.decode(Int.self, forKey: key) { return n }
        if let d = try? c.decode(Double.self, forKey: key) { return Int(d.rounded()) }
        if let s = try? c.decode(String.self, forKey: key) { return Int(s.trimmingCharacters(in: .whitespaces)) }
        return nil
    }

    private static func string(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
        if let s = try? c.decode(String.self, forKey: key) { return s }
        if let n = try? c.decode(Int.self, forKey: key) { return String(n) }
        return nil
    }
}

private struct LossyAction: Decodable {
    let value: ClawdAction?
    init(from decoder: Decoder) throws { value = try? ClawdAction(from: decoder) }
}

struct ClawdResponse: Codable {
    let actions: [ClawdAction]
    let reply: String

    init(actions: [ClawdAction], reply: String) {
        self.actions = actions
        self.reply = reply
    }

    /// One malformed action no longer discards the reply and the others.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        actions = ((try? c.decode([LossyAction].self, forKey: .actions)) ?? []).compactMap { $0.value }
        reply = (try? c.decode(String.self, forKey: .reply)) ?? ""
    }
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
    private let timeoutSeconds: TimeInterval = 30
    private let memory: ClawdMemoryStore

    init(memory: ClawdMemoryStore) {
        self.memory = memory
    }

    /// Runs the request through the Claude Code CLI (`claude -p`), i.e.
    /// Claude Code itself with the user's own login. Clawd never uses Claude
    /// Code's OAuth token directly: Anthropic's terms reserve it for Claude
    /// Code and Claude.ai. Failures bubble up; the UI explains what to do.
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
        task.environment = Self.cliEnvironment(claudePath: claudePath)

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
            return .failure(.processFailed(Self.cliErrorDetail(status: task.terminationStatus,
                                                               stdout: outStr, stderr: errStr)))
        }

        return Self.extractResponse(from: outStr)
    }

    /// GUI-launched apps get a minimal environment. Give claude a PATH that
    /// covers the common install locations so it (and user hooks) can find
    /// node and other helpers.
    static func cliEnvironment(claudePath: String) -> [String: String] {
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
        return env
    }

    /// With --output-format json, `claude -p` reports failures on stdout
    /// ({"is_error":true,"result":"…"}) and leaves stderr empty, which used
    /// to surface as a bare "exit 1:".
    static func cliErrorDetail(status: Int32, stdout: String, stderr: String) -> String {
        var detail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if detail.isEmpty,
           let data = stdout.data(using: .utf8),
           let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
           let result = obj["result"] as? String {
            detail = result
        }
        if detail.isEmpty {
            detail = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let lower = detail.lowercased()
        if lower.contains("login") || lower.contains("api key") || lower.contains("authenticat") || lower.contains("401") {
            return "Claude 로그인이 필요해요. 아래 로그인 버튼을 누르면 브라우저에서 로그인할 수 있어요."
        }
        return "exit \(status): \(detail.prefix(200))"
    }

    private static let cachePath = NSHomeDirectory() + "/.claude/pet/clawd-cli-path.txt"
    private static let resolveLock = NSLock()
    private static var cachedPath: String?

    /// The transport Clawd will use for the next request.
    enum Connection {
        case cli(String)  // claude CLI binary path
        case none         // nothing found
    }

    /// Public: call once at app launch. Resolves the fastest available
    /// connection in the background without blocking the UI.
    static func warmUpConnection(completion: ((Connection) -> Void)? = nil) {
        DispatchQueue.global(qos: .utility).async {
            if let p = resolveClaudePath() {
                DispatchQueue.main.async { completion?(.cli(p)) }
                return
            }
            DispatchQueue.main.async { completion?(.none) }
        }
    }

    /// Legacy alias kept for callers that only care about the CLI path.
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
        let tz = TimeZone.current
        // Local wall-clock time WITH its offset. Giving the model a UTC
        // timestamp ("…09:52Z") next to "Asia/Seoul" made it add minutes to
        // the UTC clock and then stamp "+09:00" on it: 9 hours early.
        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime]
        isoFmt.timeZone = tz
        let nowIso = isoFmt.string(from: now)
        let human = DateFormatter()
        human.locale = Locale(identifier: "ko_KR")
        human.timeZone = tz
        human.dateFormat = "yyyy년 M월 d일 EEEE a h:mm"
        let nowHuman = human.string(from: now)

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
        Each action is a flat object with a "type" field, e.g.
        {"type": "add_memo", "text": "회의", "dueInMinutes": 30, "tags": []}

        Supported actions (emit none if not needed):
          - add_memo      { "type": "add_memo", "text": string,
                            "dueInMinutes": number | null,
                            "dueAt": ISO8601 with offset | null, "tags": string[] }
          - complete_memo { "type": "complete_memo", "id": string }
          - delete_memo   { "type": "delete_memo", "id": string }
          - set_reminder  { "type": "set_reminder", "kind": "water"|"stretch"|"diary",
                            "enabled": bool?, "intervalMin": number?, "timeOfDay": "HH:mm"? }

        Times:
          - Relative times ("3분 뒤", "1시간 후", "30 minutes later"): set dueInMinutes \
            to the number of minutes from now and leave dueAt null. The app computes the time.
          - Clock times ("3시", "내일 오전 10시"): set dueAt to an absolute ISO8601 time \
            WITH the local offset shown below. "3시" means the next 3 o'clock that is in \
            the future (15:00 if it is already past 3 AM).
          - Never return a time in the past. If unclear, leave both null and ask in `reply`.

        If the user asks a general question (weather, news, facts), you may \
        use your web tools and put the answer in `reply` with actions: []. \
        Do not create memos the user did not ask for. Keep `reply` to 1–2 \
        warm sentences. Do not state the exact clock time in `reply`; the app shows it.

        Now (local): \(nowHuman)
        Now (ISO8601, local offset): \(nowIso)  [\(tz.identifier)]

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

        // Try direct, fenced, embedded-JSON, then fall back to plain text reply.
        if let parsed = parseLenient(assistantText) {
            return .success(parsed)
        }
        let trimmed = assistantText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return .success(ClawdResponse(actions: [], reply: trimmed))
        }
        return .failure(.parseFailed(raw: assistantText))
    }

    private static func parseLenient(_ text: String) -> ClawdResponse? {
        ClawdResponseParser.parseLenient(text)
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
