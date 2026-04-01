import Cocoa
import UserNotifications

class NotificationManager {
    private var lastNotificationTime: Date?
    private let cooldownSeconds: TimeInterval = 300 // 5 minutes

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func checkAndNotify(rateLimit: RateLimitData) {
        guard let percent = rateLimit.fiveHourPercent, percent >= 80 else { return }

        // Dedup: don't send again within 5 minutes
        if let last = lastNotificationTime,
           Date().timeIntervalSince(last) < cooldownSeconds {
            return
        }

        sendNotification(percent: percent)
        lastNotificationTime = Date()
    }

    private func sendNotification(percent: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Claude Pet - Rate Limit Warning"
        content.body = "5-hour rate limit at \(Int(percent))%. Consider taking a break!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "rate-limit-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil // immediate
        )
        UNUserNotificationCenter.current().add(request)
    }
}
