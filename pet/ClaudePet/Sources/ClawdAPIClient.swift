import Foundation

/// Direct Anthropic API client. Much faster than spawning `claude -p`
/// because it avoids the Node + CLI startup cost. Reuses the OAuth token
/// that Claude Code stores in the user's macOS keychain, so it works on
/// any Mac where the user has signed into Claude Code at least once.
final class ClawdAPIClient {
    static let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    static let modelId = "claude-haiku-4-5"
    static let anthropicBeta = "oauth-2025-04-20"
    static let anthropicVersion = "2023-06-01"
    static let keychainService = "Claude Code-credentials"

    private let timeout: TimeInterval = 30
    private let memory: ClawdMemoryStore

    init(memory: ClawdMemoryStore) {
        self.memory = memory
    }

    func send(userText: String,
              completion: @escaping (Result<ClawdResponse, ClawdChatError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.run(userText: userText) { result in
                DispatchQueue.main.async { completion(result) }
            }
        }
    }

    private func run(userText: String,
                     completion: @escaping (Result<ClawdResponse, ClawdChatError>) -> Void) {
        guard let token = Self.readOAuthToken() else {
            completion(.failure(.cliNotFound))
            return
        }

        let file = memory.read()
        let systemPrompt = Self.buildSystemPrompt(file: file)

        let body: [String: Any] = [
            "model": Self.modelId,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userText]
            ]
        ]
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(.parseFailed(raw: "payload encode failed")))
            return
        }

        var req = URLRequest(url: Self.apiURL)
        req.httpMethod = "POST"
        req.timeoutInterval = timeout
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue(Self.anthropicVersion, forHTTPHeaderField: "anthropic-version")
        req.setValue(Self.anthropicBeta, forHTTPHeaderField: "anthropic-beta")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        req.httpBody = payload

        let task = URLSession.shared.dataTask(with: req) { data, response, error in
            if let error = error {
                completion(.failure(.processFailed("http: \(error.localizedDescription)")))
                return
            }
            guard let data = data else {
                completion(.failure(.processFailed("no data")))
                return
            }
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                let err = String(data: data, encoding: .utf8)?.prefix(200) ?? ""
                completion(.failure(.processFailed("http \(http.statusCode): \(err)")))
                return
            }
            completion(Self.extractResponse(from: data))
        }
        task.resume()
    }

    // MARK: - Keychain

    /// Reads the Claude Code OAuth access token from the login keychain.
    /// Uses `security find-generic-password -w` which prompts once for
    /// permission (Always Allow persists the grant).
    static func readOAuthToken() -> String? {
        let proc = Process()
        proc.launchPath = "/usr/bin/security"
        proc.arguments = ["find-generic-password", "-s", keychainService, "-w"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        do { try proc.run() } catch { return nil }
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        let raw = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let jsonData = raw.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let oauth = root["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String,
              !token.isEmpty else {
            return nil
        }
        return token
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

        You MUST respond with a single JSON object, no prose, no code fences, \
        no markdown. The response must exactly match this shape:

          {"actions": [ { "type": "<action_name>", ...fields }, ... ],
           "reply":   "<1-2 sentence reply to the user>"}

        Each action object MUST be flat — `type` is a sibling of the fields, \
        NOT a wrapping key. Example of the CORRECT shape:

          {"type": "add_memo", "text": "점심 먹기",
           "dueAt": "2026-04-14T12:40:00+09:00", "tags": ["점심"]}

        WRONG (do not nest the type as a key):
          {"add_memo": {"text": "점심 먹기", "dueAt": "..."}}

        Supported action types:
          - add_memo      { type:"add_memo",      text:string, dueAt:ISO8601|null, tags:string[] }
          - complete_memo { type:"complete_memo", id:string }
          - delete_memo   { type:"delete_memo",   id:string }
          - set_reminder  { type:"set_reminder",  kind:"water"|"stretch"|"diary",
                            enabled?:bool, intervalMin?:number, timeOfDay?:"HH:mm" }

        For general questions (weather, news, facts) answer briefly in `reply` \
        with actions: []. Do not create memos the user did not ask for. \
        Keep `reply` to 1–2 warm sentences.

        Current time: \(nowIso) (\(tz)).
        Resolve relative times ("3시", "내일 오전 10시", "30분 뒤") to absolute ISO8601 \
        in the user's timezone. If ambiguous, leave dueAt null and ask in `reply`.

        Current reminders: \(remindersJson)
        Open memos (newest last, up to 10): \(memosJson)
        Recent chat (last 6, oldest first): \(chatJson)
        """
    }

    // MARK: - Response extraction

    static func extractResponse(from data: Data) -> Result<ClawdResponse, ClawdChatError> {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = root["content"] as? [[String: Any]] else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            return .failure(.parseFailed(raw: raw))
        }
        let text = content.compactMap { block -> String? in
            if (block["type"] as? String) == "text",
               let t = block["text"] as? String { return t }
            return nil
        }.joined()

        if let parsed = parseLenient(text) {
            return .success(parsed)
        }
        // Fallback: treat any free-form text as a plain reply with no actions.
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return .success(ClawdResponse(actions: [], reply: trimmed))
        }
        return .failure(.parseFailed(raw: text))
    }

    /// Shared lenient parser used by both the API path and the CLI fallback.
    /// Try several decode strategies in order:
    /// 1. Raw text is already a clean JSON object.
    /// 2. Wrapped in ```json ... ``` fences.
    /// 3. JSON object embedded somewhere inside prose.
    /// Each candidate is also passed through an action-shape normalizer
    /// so both {"type":"add_memo",...} and {"add_memo":{...}} are accepted.
    static func parseLenient(_ text: String) -> ClawdResponse? {
        let candidates = [
            text,
            stripFences(text),
            firstJSONObject(in: text) ?? "",
        ]
        for c in candidates where !c.isEmpty {
            if let r = decodeWithNormalization(c) { return r }
        }
        return nil
    }

    private static func decodeWithNormalization(_ jsonText: String) -> ClawdResponse? {
        guard let data = jsonText.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let reply = (root["reply"] as? String) ?? ""
        let rawActions = (root["actions"] as? [[String: Any]]) ?? []
        let normalized = rawActions.map(normalizeAction)
        guard let normData = try? JSONSerialization.data(
                withJSONObject: ["actions": normalized, "reply": reply]
              ),
              let response = try? JSONDecoder().decode(ClawdResponse.self, from: normData) else {
            return nil
        }
        return response
    }

    /// Accept both the canonical flat form `{"type":"add_memo", ...}` and the
    /// nested form `{"add_memo": {...}}` that Haiku occasionally emits.
    private static func normalizeAction(_ raw: [String: Any]) -> [String: Any] {
        if raw["type"] is String { return raw }
        let knownTypes: Set<String> = [
            "add_memo", "complete_memo", "delete_memo", "set_reminder"
        ]
        for (key, value) in raw where knownTypes.contains(key) {
            var flat: [String: Any] = ["type": key]
            if let inner = value as? [String: Any] {
                for (k, v) in inner { flat[k] = v }
            } else {
                flat["value"] = value
            }
            return flat
        }
        return raw
    }

    private static func stripFences(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            if let firstNL = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: firstNL)...])
            }
            if t.hasSuffix("```") { t = String(t.dropLast(3)) }
            t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return t
    }

    /// Scan for the first balanced `{...}` block, respecting string
    /// literals and escapes. Returns nil if none found.
    private static func firstJSONObject(in text: String) -> String? {
        var depth = 0
        var inString = false
        var escape = false
        var startIdx: String.Index?
        for idx in text.indices {
            let ch = text[idx]
            if escape { escape = false; continue }
            if inString {
                if ch == "\\" { escape = true }
                else if ch == "\"" { inString = false }
                continue
            }
            if ch == "\"" { inString = true; continue }
            if ch == "{" {
                if depth == 0 { startIdx = idx }
                depth += 1
            } else if ch == "}" {
                depth -= 1
                if depth == 0, let start = startIdx {
                    return String(text[start...idx])
                }
            }
        }
        return nil
    }
}
