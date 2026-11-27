import Foundation

final class ReminderScheduler {
    private let memory: ClawdMemoryStore
    private let notifications: NotificationManager
    /// True while the user is using Claude anywhere: a Claude Code session
    /// or chat activity (desktop app, web, mobile). Water/stretch reminders
    /// only fire while active.
    private let isUserActive: () -> Bool
    private var timer: Timer?

    init(memory: ClawdMemoryStore,
         notifications: NotificationManager,
         isUserActive: @escaping () -> Bool) {
        self.memory = memory
        self.notifications = notifications
        self.isUserActive = isUserActive
    }

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = Date()
        let nowMs = now.timeIntervalSince1970 * 1000
        let activeSessions = isUserActive() ? 1 : 0

        memory.update { file in
            fireInterval(key: "water",
                         title: "Clawd",
                         body: "물 한 잔 마실 시간이에요 💧",
                         config: &file.reminders.water,
                         nowMs: nowMs,
                         activeSessions: activeSessions)
            fireInterval(key: "stretch",
                         title: "Clawd",
                         body: "잠깐 스트레칭 해볼까요? 🧘",
                         config: &file.reminders.stretch,
                         nowMs: nowMs,
                         activeSessions: activeSessions)

            fireDiary(config: &file.reminders.diary, now: now)

            let dueIndices = file.memos.indices.filter { i in
                guard !file.memos[i].done,
                      let due = ClawdMemoryStore.parseIso(file.memos[i].dueAt) else { return false }
                return due <= now
            }
            // After a long sleep many memos can be due at once: one summary
            // notification instead of a burst.
            if dueIndices.count > 3 {
                let first = file.memos[dueIndices[0]].text
                notifications.sendClawdMessage(
                    key: "memo:batch:\(Int(nowMs))",
                    title: "Clawd 알림",
                    body: "놓친 메모 \(dueIndices.count)개가 있어요: \(first) 외"
                )
            } else {
                for i in dueIndices {
                    notifications.sendClawdMessage(
                        key: "memo:\(file.memos[i].id)",
                        title: "Clawd 알림",
                        body: file.memos[i].text
                    )
                }
            }
            for i in dueIndices {
                file.memos[i].done = true
                file.memos[i].completedAt = ClawdMemoryStore.isoNow()
            }
        }
    }

    private func fireInterval(key: String,
                              title: String,
                              body: String,
                              config: inout ReminderConfig,
                              nowMs: Double,
                              activeSessions: Int) {
        guard config.enabled,
              activeSessions > 0,
              let interval = config.intervalMin,
              interval >= 30 else { return }
        if config.lastAt == 0 {
            config.lastAt = nowMs
            return
        }
        let elapsedMin = (nowMs - config.lastAt) / 60_000
        if elapsedMin >= Double(interval) {
            notifications.sendClawdMessage(key: key, title: title, body: body)
            config.lastAt = nowMs
        }
    }

    private func fireDiary(config: inout ReminderConfig, now: Date) {
        guard config.enabled,
              let timeStr = config.timeOfDay else { return }
        let cal = Calendar.current
        let today = Self.localDateString(now)
        if config.lastDate == today { return }

        let parts = timeStr.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return }
        let comps = cal.dateComponents([.hour, .minute], from: now)
        guard let nowH = comps.hour, let nowM = comps.minute else { return }
        let nowMinutes = nowH * 60 + nowM
        let targetMinutes = hour * 60 + minute
        guard nowMinutes >= targetMinutes else { return }

        notifications.sendClawdMessage(
            key: "diary",
            title: "Clawd",
            body: "오늘 하루 일기 어떠세요? 📝"
        )
        config.lastDate = today
        config.lastAt = now.timeIntervalSince1970 * 1000
    }

    private static func localDateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        return fmt.string(from: date)
    }
}
