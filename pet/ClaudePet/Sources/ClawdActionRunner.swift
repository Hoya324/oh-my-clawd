import Foundation

final class ClawdActionRunner {
    private let memory: ClawdMemoryStore

    init(memory: ClawdMemoryStore) {
        self.memory = memory
    }

    /// Apply all actions and append the user/clawd turns to chatLog.
    @discardableResult
    func apply(userText: String, response: ClawdResponse) -> [String] {
        var summary: [String] = []
        memory.update { file in
            let ts = Date().timeIntervalSince1970 * 1000
            file.chatLog.append(ChatTurn(role: .user, text: userText, ts: ts))

            for action in response.actions {
                switch action.typed {
                case .addMemo:
                    guard let text = Self.cleanText(action.text) else {
                        summary.append("add_memo: missing text"); continue
                    }
                    // Skip exact duplicates of an open memo (the model
                    // sometimes repeats the action on a retry).
                    if file.memos.contains(where: { !$0.done && $0.text == text && $0.dueAt == Self.validDueAt(action.dueAt) }) {
                        summary.append("add_memo: duplicate"); continue
                    }
                    let memo = ClawdMemo(
                        id: ClawdMemoryStore.newMemoId(),
                        text: text,
                        createdAt: ClawdMemoryStore.isoNow(),
                        dueAt: Self.validDueAt(action.dueAt),
                        tags: Self.cleanTags(action.tags),
                        done: false,
                        completedAt: nil
                    )
                    file.memos.append(memo)
                    summary.append("add_memo: \(memo.id)")

                case .completeMemo:
                    guard let id = action.id,
                          let idx = file.memos.firstIndex(where: { $0.id == id }) else {
                        summary.append("complete_memo: id not found"); continue
                    }
                    file.memos[idx].done = true
                    file.memos[idx].completedAt = ClawdMemoryStore.isoNow()
                    summary.append("complete_memo: \(id)")

                case .deleteMemo:
                    guard let id = action.id else {
                        summary.append("delete_memo: missing id"); continue
                    }
                    let before = file.memos.count
                    file.memos.removeAll { $0.id == id }
                    summary.append(before == file.memos.count
                                   ? "delete_memo: id not found"
                                   : "delete_memo: \(id)")

                case .setReminder:
                    guard let kind = action.kind else {
                        summary.append("set_reminder: missing kind"); continue
                    }
                    switch kind {
                    case "water":   applyReminder(config: &file.reminders.water, action: action)
                    case "stretch": applyReminder(config: &file.reminders.stretch, action: action)
                    case "diary":   applyReminder(config: &file.reminders.diary, action: action)
                    default: summary.append("set_reminder: unknown kind \(kind)"); continue
                    }
                    summary.append("set_reminder: \(kind)")

                case .unknown:
                    summary.append("unknown action: \(action.type)")
                }
            }

            let reply = response.reply.trimmingCharacters(in: .whitespacesAndNewlines)
            file.chatLog.append(ChatTurn(role: .clawd, text: String(reply.prefix(Self.maxReplyLength)), ts: ts))
        }
        return summary
    }

    /// Local-only reminder mutation (used by UI toggles, no LLM round-trip).
    func setReminderDirect(kind: String,
                           enabled: Bool? = nil,
                           intervalMin: Int? = nil,
                           timeOfDay: String? = nil) {
        memory.update { file in
            let action = ClawdAction(
                type: ClawdActionType.setReminder.rawValue,
                text: nil, dueAt: nil, tags: nil, id: nil,
                kind: kind, enabled: enabled,
                intervalMin: intervalMin, timeOfDay: timeOfDay
            )
            switch kind {
            case "water":   applyReminder(config: &file.reminders.water, action: action)
            case "stretch": applyReminder(config: &file.reminders.stretch, action: action)
            case "diary":   applyReminder(config: &file.reminders.diary, action: action)
            default: break
            }
        }
    }

    func deleteMemo(id: String) {
        memory.update { file in
            file.memos.removeAll { $0.id == id }
        }
    }

    func completeMemo(id: String) {
        memory.update { file in
            if let idx = file.memos.firstIndex(where: { $0.id == id }) {
                file.memos[idx].done = true
                file.memos[idx].completedAt = ClawdMemoryStore.isoNow()
            }
        }
    }

    // MARK: - Private

    static let maxMemoLength = 500
    static let maxReplyLength = 600
    static let maxTags = 5
    static let intervalRange = 30...(24 * 60)

    private func applyReminder(config: inout ReminderConfig, action: ClawdAction) {
        if let e = action.enabled { config.enabled = e }
        if let m = action.intervalMin, Self.intervalRange.contains(m) { config.intervalMin = m }
        if let t = Self.validTimeOfDay(action.timeOfDay) { config.timeOfDay = t }
    }

    // MARK: - Validation

    static func cleanText(_ raw: String?) -> String? {
        guard let t = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        return String(t.prefix(maxMemoLength))
    }

    static func cleanTags(_ raw: [String]?) -> [String] {
        var seen = Set<String>()
        return (raw ?? [])
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20)) }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
            .prefix(maxTags)
            .map { $0 }
    }

    /// Only keep a dueAt that parses and is not absurdly far away; an
    /// unparsable value used to be stored and then silently never fire.
    static func validDueAt(_ raw: String?) -> String? {
        guard let raw = raw, let date = ClawdMemoryStore.parseIso(raw) else { return nil }
        let now = Date()
        guard date > now.addingTimeInterval(-24 * 3600),
              date < now.addingTimeInterval(400 * 24 * 3600) else { return nil }
        return raw
    }

    /// "9:5", "09:05", "21:00" → "HH:mm"; anything else → nil.
    static func validTimeOfDay(_ raw: String?) -> String? {
        guard let parts = raw?.split(separator: ":"), parts.count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]),
              (0...23).contains(h), (0...59).contains(m) else { return nil }
        return String(format: "%02d:%02d", h, m)
    }
}
