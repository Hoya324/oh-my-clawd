import Cocoa
import UserNotifications

enum NotificationAuthState: Equatable {
    case unknown
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
    /// Allowed, but the user set alert style to None → notifications land in
    /// Notification Center silently without a banner on the screen edge.
    case authorizedNoBanner
}

final class NotificationManager {
    private var lastByKey: [String: Date] = [:]
    private let lock = NSLock()
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
            let base: NotificationAuthState
            switch settings.authorizationStatus {
            case .notDetermined: base = .notDetermined
            case .denied:        base = .denied
            case .authorized:    base = .authorized
            case .provisional:   base = .provisional
            case .ephemeral:     base = .ephemeral
            @unknown default:    base = .unknown
            }
            // Detect "alert style: None" — user allowed notifications but
            // told macOS not to show banners.
            let state: NotificationAuthState
            if base == .authorized && settings.alertStyle == .none {
                state = .authorizedNoBanner
            } else {
                state = base
            }
            DispatchQueue.main.async {
                guard let self = self else { return }
                let wasAuthorized = Self.isAuthorized(self.authState)
                let nowAuthorized = Self.isAuthorized(state)
                self.authState = state
                self.onAuthStateChange?(state)
                // Fire a welcome ping on the transition into "authorized".
                if !wasAuthorized && nowAuthorized {
                    self.fireWelcome()
                }
            }
        }
    }

    private static func isAuthorized(_ s: NotificationAuthState) -> Bool {
        s == .authorized || s == .provisional || s == .ephemeral
            || s == .authorizedNoBanner
    }

    private func fireWelcome() {
        let content = UNMutableNotificationContent()
        content.title = "Clawd"
        content.body = "알림이 켜졌어요. 이제 물·스트레칭·메모를 챙겨드릴게요 🐾"
        content.sound = .default
        let req = UNNotificationRequest(
            identifier: "clawd-welcome-\(Int(Date().timeIntervalSince1970))",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(req) { error in
            if let e = error {
                NSLog("[Clawd] welcome notification failed: \(e)")
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

    /// Thresholds already announced in the current 5-hour window. Notifies
    /// once per threshold per window instead of every 5 minutes while high.
    private var announcedWindow: Date?
    private var announcedThresholds: Set<Int> = []
    static let rateLimitThresholds = [80, 95]

    func checkAndNotify(rateLimit: RateLimitData) {
        guard let percent = rateLimit.fiveHourPercent else { return }
        let window = UsageService.parseDate(rateLimit.fiveHourResetsAt)
        lock.lock()
        // Reset times jitter by seconds between responses: same window if
        // within 10 minutes.
        let sameWindow: Bool = {
            guard let a = window, let b = self.announcedWindow else { return window == nil && self.announcedWindow == nil }
            return abs(a.timeIntervalSince(b)) < 600
        }()
        if !sameWindow {
            announcedThresholds = []
            announcedWindow = window
        }
        let crossed = Self.rateLimitThresholds.filter { Int(percent) >= $0 && !announcedThresholds.contains($0) }
        announcedThresholds.formUnion(crossed)
        lock.unlock()

        guard let level = crossed.max() else { return }
        let body = level >= 95
            ? "5시간 사용량이 \(Int(percent))%예요. 곧 한도에 닿아요."
            : "5시간 사용량이 \(Int(percent))%예요. 잠깐 쉬어가도 좋아요."
        sendRaw(id: "rate-limit-\(level)-\(Int(Date().timeIntervalSince1970))",
                title: "Clawd 사용량 알림", body: body)
    }

    // MARK: - Clawd messages (reminders + memos)

    /// Safe to call from any thread (the reminder scheduler calls it from
    /// the memory store's queue).
    func sendClawdMessage(key: String, title: String, body: String) {
        lock.lock()
        if let last = lastByKey[key], Date().timeIntervalSince(last) < clawdCooldown {
            lock.unlock()
            return
        }
        lastByKey[key] = Date()
        lock.unlock()
        sendRaw(
            id: "clawd-\(key)-\(Int(Date().timeIntervalSince1970))",
            title: title,
            body: body
        )
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
