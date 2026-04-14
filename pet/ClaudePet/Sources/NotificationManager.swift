import Cocoa
import UserNotifications

enum NotificationAuthState: Equatable {
    case unknown
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
}

final class NotificationManager {
    private var lastByKey: [String: Date] = [:]
    private let rateLimitCooldown: TimeInterval = 300
    private let clawdCooldown: TimeInterval = 60

    /// Published-style callback invoked whenever auth state is refreshed.
    var onAuthStateChange: ((NotificationAuthState) -> Void)?
    private(set) var authState: NotificationAuthState = .unknown

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { [weak self] granted, error in
            if let error = error {
                NSLog("[Clawd] requestAuthorization error: \(error)")
            }
            NSLog("[Clawd] requestAuthorization granted=\(granted)")
            self?.refreshAuthState()
        }
    }

    func refreshAuthState() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let state: NotificationAuthState
            switch settings.authorizationStatus {
            case .notDetermined: state = .notDetermined
            case .denied:        state = .denied
            case .authorized:    state = .authorized
            case .provisional:   state = .provisional
            case .ephemeral:     state = .ephemeral
            @unknown default:    state = .unknown
            }
            DispatchQueue.main.async {
                self?.authState = state
                self?.onAuthStateChange?(state)
            }
        }
    }

    /// Fire an immediate test notification. If permission is missing, requests it.
    func sendTestNotification(completion: @escaping (Bool, String) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound]
                ) { granted, _ in
                    self.refreshAuthState()
                    if granted {
                        self.fireTest(completion: completion)
                    } else {
                        DispatchQueue.main.async {
                            completion(false, "알림 권한이 거부되었어요. 시스템 설정에서 켜주세요.")
                        }
                    }
                }
                return
            }
            if settings.authorizationStatus == .denied {
                DispatchQueue.main.async {
                    completion(false, "알림 권한이 꺼져 있어요. 시스템 설정 → 알림 → OhMyClawd에서 켜주세요.")
                }
                return
            }
            self.fireTest(completion: completion)
        }
    }

    private func fireTest(completion: @escaping (Bool, String) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = "Clawd"
        content.body = "테스트 알림이에요! 잘 들리시나요? 🐾"
        content.sound = .default
        let req = UNNotificationRequest(
            identifier: "clawd-test-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req) { error in
            DispatchQueue.main.async {
                if let e = error {
                    completion(false, "전송 실패: \(e.localizedDescription)")
                } else {
                    completion(true, "테스트 알림을 보냈어요")
                }
            }
        }
    }

    static func openSystemNotificationSettings() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.hoya324.oh-my-clawd"
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleID)") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Rate limit

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
        UNUserNotificationCenter.current().add(req) { error in
            if let e = error {
                NSLog("[Clawd] notification add failed (\(id)): \(e)")
            }
        }
    }
}
