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
                    guard let text = action.text, !text.isEmpty else {
                        summary.append("add_memo: missing text"); continue
                    }
                    let memo = ClawdMemo(
                        id: ClawdMemoryStore.newMemoId(),
                        text: text,
                        createdAt: ClawdMemoryStore.isoNow(),
                        dueAt: action.dueAt,
                        tags: action.tags ?? [],
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

            file.chatLog.append(ChatTurn(role: .clawd, text: response.reply, ts: ts))
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

    private func applyReminder(config: inout ReminderConfig, action: ClawdAction) {
        if let e = action.enabled { config.enabled = e }
        if let m = action.intervalMin, m >= 30 { config.intervalMin = m }
        if let t = action.timeOfDay, t.count == 5, t.contains(":") {
            config.timeOfDay = t
        }
    }
}
