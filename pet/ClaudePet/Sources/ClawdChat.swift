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

    private static func resolveClaudePath() -> String? {
        let candidates = [
            NSHomeDirectory() + "/.claude/local/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
        ]
        for p in candidates where FileManager.default.isExecutableFile(atPath: p) {
            return p
        }
        let which = Process()
        which.launchPath = "/bin/sh"
        which.arguments = ["-lc", "command -v claude"]
        let pipe = Pipe()
        which.standardOutput = pipe
        which.standardError = Pipe()
        do { try which.run() } catch { return nil }
        which.waitUntilExit()
        guard which.terminationStatus == 0 else { return nil }
        let out = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (out?.isEmpty == false) ? out : nil
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
