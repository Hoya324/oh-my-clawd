import Foundation

/// Turns Clawd's model reply (requested as JSON) into a ClawdResponse,
/// tolerating code fences, prose around the JSON, and nested action shapes.
///
/// Clawd talks to Claude only through the Claude Code CLI (`claude -p`).
/// It used to call the API directly with Claude Code's OAuth token, which
/// Anthropic's terms do not allow for third-party tools.
enum ClawdResponseParser {
    /// Lenient parser for the model's reply.
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
