import Foundation

/// A per-model weekly limit (e.g. Opus), when the account has one.
struct ModelLimit: Equatable {
    var model: String          // "opus", "sonnet"
    var percent: Double
    var resetsAt: Date?

    var label: String { model.prefix(1).uppercased() + model.dropFirst() }
}

/// A point-in-time view of the account's rate limits, as Claude Code last
/// reported them.
struct UsageSnapshot: Equatable {
    var fiveHourPercent: Double?
    var weeklyPercent: Double?
    var fiveHourResetsAt: Date?
    var weeklyResetsAt: Date?
    /// When Claude Code last reported these numbers.
    var fetchedAt: Date
    var modelLimits: [ModelLimit] = []
    /// The window reset after the last report: the old percentage no longer
    /// applies and the new one is unknown until Claude Code reports again.
    var fiveHourResetSinceUpdate = false
    var weeklyResetSinceUpdate = false
    /// "statusline" when the HUD recorded it from Claude Code. Anything else
    /// is a leftover from v2.2.0, which fetched usage itself.
    var source: String = "statusline"

    var isFromClaudeCode: Bool { source == "statusline" }

    var rateLimit: RateLimitData {
        let iso = ISO8601DateFormatter()
        return RateLimitData(
            fiveHourPercent: fiveHourResetSinceUpdate ? nil : fiveHourPercent,
            weeklyPercent: weeklyResetSinceUpdate ? nil : weeklyPercent,
            fiveHourResetsAt: fiveHourResetsAt.map { iso.string(from: $0) },
            weeklyResetsAt: weeklyResetsAt.map { iso.string(from: $0) }
        )
    }

    var age: TimeInterval { Date().timeIntervalSince(fetchedAt) }
}

enum UsageStatus: Equatable {
    case loading
    /// Recent numbers from Claude Code.
    case ok
    /// Numbers exist but Claude Code has not reported for a while.
    case stale
    /// The HUD is installed but nothing has been reported yet: Claude Code
    /// sends usage after a session's first reply, and only to Pro / Max.
    case waitingForData
    /// The HUD (status line) is off, so Claude Code has nowhere to send it.
    case hudOff
}

/// Shows account usage without touching Claude Code's login.
///
/// Anthropic's terms reserve subscription OAuth tokens for Claude Code and
/// Claude.ai, so this app never reads, uses or refreshes them. Instead the
/// HUD (runtime/hud.mjs) records the `rate_limits` that Claude Code passes
/// to the status line, in ~/.claude/pet/usage-cache.json, and this service
/// only reads that file. Usage therefore updates while Claude Code is used.
final class UsageService {
    static let pollInterval: TimeInterval = 10
    /// Older than this, the numbers are shown as "n분 전".
    static let staleAfter: TimeInterval = 30 * 60
    /// Official usage page for people who do not use Claude Code.
    static let usagePageURL = URL(string: "https://claude.ai/settings/usage")!

    private(set) var snapshot: UsageSnapshot?
    private(set) var status: UsageStatus = .loading

    /// Called on the main queue whenever the snapshot or status changes.
    var onUpdate: ((UsageSnapshot?, UsageStatus) -> Void)?

    private var timer: Timer?

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer!, forMode: .common)
        refresh()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Re-read the shared cache. Cheap (one small file); main thread is fine.
    func refresh(force: Bool = false) {
        let now = Date()
        let snap = Self.readCache(now: now)
        let newStatus: UsageStatus
        if let s = snap {
            // A value not recorded from Claude Code is never "live".
            newStatus = (!s.isFromClaudeCode || now.timeIntervalSince(s.fetchedAt) > Self.staleAfter) ? .stale : .ok
        } else {
            newStatus = HudSettings.isEnabled() ? .waitingForData : .hudOff
        }
        let changed = force || snap != snapshot || newStatus != status
        snapshot = snap
        status = newStatus
        if changed { onUpdate?(snap, newStatus) }
    }

    // MARK: - Shared cache (written by runtime/lib/usage.mjs)

    static func readCache(now: Date = Date()) -> UsageSnapshot? {
        guard let root = JSONFile.readObject(Paths.usageCache),
              let ts = (root["timestamp"] as? NSNumber)?.doubleValue,
              let d = root["data"] as? [String: Any] else { return nil }
        let five = (d["fiveHourPercent"] as? NSNumber)?.doubleValue
        let week = (d["weeklyPercent"] as? NSNumber)?.doubleValue
        guard five != nil || week != nil else { return nil }

        let fiveReset = parseDate(d["fiveHourResetsAt"] as? String)
        let weekReset = parseDate(d["weeklyResetsAt"] as? String)
        let models = (d["models"] as? [[String: Any]] ?? []).compactMap { m -> ModelLimit? in
            guard let name = m["model"] as? String,
                  let pct = (m["percent"] as? NSNumber)?.doubleValue else { return nil }
            return ModelLimit(model: name, percent: pct, resetsAt: parseDate(m["resetsAt"] as? String))
        }
        return UsageSnapshot(
            fiveHourPercent: five,
            weeklyPercent: week,
            fiveHourResetsAt: fiveReset,
            weeklyResetsAt: weekReset,
            fetchedAt: Date(timeIntervalSince1970: ts / 1000),
            modelLimits: models,
            fiveHourResetSinceUpdate: fiveReset.map { $0 <= now } ?? false,
            weeklyResetSinceUpdate: weekReset.map { $0 <= now } ?? false,
            source: root["source"] as? String ?? "unknown"
        )
    }

    static func parseDate(_ s: String?) -> Date? {
        guard let s = s, !s.isEmpty else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }
}
