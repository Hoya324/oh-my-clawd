import Cocoa

/// Detects Claude use outside Claude Code (claude.ai, the desktop app,
/// mobile, remote agent sessions) from two signals that need no private
/// data:
///
///  1. The Claude desktop app is the frontmost application.
///  2. The account's 5-hour usage went up since the previous poll. Usage is
///     account-wide, so this fires no matter where Claude is being used.
///
/// It cannot tell which conversation is open or whether a reply is being
/// generated, and it never reads the Claude app's files or browser data.
final class ChatActivityMonitor: NSObject {
    enum Source: Equatable {
        case none
        case claudeApp
        case usageRising
    }

    /// How long a usage increase keeps Clawd in the "chatting" state.
    static let usageActivityWindow: TimeInterval = 6 * 60

    private(set) var isClaudeAppFrontmost = false
    private(set) var lastUsageIncreaseAt: Date?
    private var lastFiveHour: Double?
    private var lastWindowReset: Date?

    var onChange: (() -> Void)?

    func start() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(self, selector: #selector(appActivated(_:)),
                           name: NSWorkspace.didActivateApplicationNotification, object: nil)
        isClaudeAppFrontmost = Self.isClaudeApp(NSWorkspace.shared.frontmostApplication)
    }

    func source(now: Date = Date()) -> Source {
        if isClaudeAppFrontmost { return .claudeApp }
        if let t = lastUsageIncreaseAt, now.timeIntervalSince(t) < Self.usageActivityWindow {
            return .usageRising
        }
        return .none
    }

    var isChatting: Bool { source() != .none }

    /// Feed every usage snapshot here.
    func observe(usage: UsageSnapshot?) {
        guard let pct = usage?.fiveHourPercent else { return }
        let reset = usage?.fiveHourResetsAt
        defer {
            lastFiveHour = pct
            lastWindowReset = reset
        }
        // A new 5h window resets the counter; that is not activity. Reset
        // times can jitter by seconds between responses, so compare loosely.
        guard let prev = lastFiveHour, Self.sameWindow(reset, lastWindowReset) else { return }
        if pct > prev + 0.01 {
            lastUsageIncreaseAt = Date()
            onChange?()
        }
    }

    private static func sameWindow(_ a: Date?, _ b: Date?) -> Bool {
        guard let a = a, let b = b else { return a == nil && b == nil }
        return abs(a.timeIntervalSince(b)) < 10 * 60
    }

    @objc private func appActivated(_ note: Notification) {
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        let isClaude = Self.isClaudeApp(app)
        if isClaude != isClaudeAppFrontmost {
            isClaudeAppFrontmost = isClaude
            onChange?()
        }
    }

    /// The Claude desktop app. Claude Code runs inside terminals/IDEs and is
    /// tracked by the aggregator instead.
    static func isClaudeApp(_ app: NSRunningApplication?) -> Bool {
        guard let app = app else { return false }
        if let id = app.bundleIdentifier?.lowercased(), id.hasPrefix("com.anthropic.") {
            return true
        }
        return app.localizedName == "Claude"
    }
}
