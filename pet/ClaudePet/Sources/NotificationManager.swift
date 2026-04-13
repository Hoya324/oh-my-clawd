import Cocoa
import UserNotifications

final class NotificationManager {
    private var lastByKey: [String: Date] = [:]
    private let rateLimitCooldown: TimeInterval = 300   // 5 min for rate-limit warnings
    private let clawdCooldown: TimeInterval = 60        // 1 min between any two Clawd pings

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { _, _ in }
    }

    // MARK: - Rate limit (existing behavior)

    func checkAndNotify(rateLimit: RateLimitData) {
        guard let percent = rateLimit.fiveHourPercent, percent >= 80 else { return }
        if let last = lastByKey["rateLimit"],
           Date().timeIntervalSince(last) < rateLimitCooldown { return }
        sendRaw(
            id: "rate-limit-\(Int(Date().timeIntervalSince1970))",
            title: "oh-my-clawd - Rate Limit Warning",
            body: "5-hour rate limit at \(Int(percent))%. Consider taking a break!"
        )
        lastByKey["rateLimit"] = Date()
    }

    // MARK: - Clawd messages (reminders + memos)

    /// Fire a Clawd notification. `key` dedupes within `clawdCooldown`; pass a
    /// unique key per event (e.g. `"water"`, `"memo:<id>"`).
    func sendClawdMessage(key: String, title: String, body: String) {
        if let last = lastByKey[key],
           Date().timeIntervalSince(last) < clawdCooldown { return }
        sendRaw(
            id: "clawd-\(key)-\(Int(Date().timeIntervalSince1970))",
            title: title,
            body: body
        )
        lastByKey[key] = Date()
    }

    // MARK: - Private

    private func sendRaw(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }
}
