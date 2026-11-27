import Cocoa

/// What the menu bar shows next to Clawd.
enum UsageDisplayMode: String, CaseIterable {
    case off
    case fiveHour
    case both

    private static let defaultsKey = "usageDisplayMode"

    var label: String {
        switch self {
        case .off:      return "끔"
        case .fiveHour: return "5h"
        case .both:     return "5h+주"
        }
    }

    static func load() -> UsageDisplayMode {
        UserDefaults.standard.string(forKey: defaultsKey).flatMap(UsageDisplayMode.init(rawValue:)) ?? .fiveHour
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.defaultsKey)
    }
}

/// Builds the status item's title and tooltip from a usage snapshot.
enum StatusBarUsage {
    static func color(for percent: Double) -> NSColor {
        if percent >= 90 { return .systemRed }
        if percent >= 70 { return .systemOrange }
        return .labelColor
    }

    /// Menu bar text. Values that are old (no Claude Code reply for a while)
    /// or whose window has reset since are drawn dimmed, so a stale number
    /// never looks live.
    static func title(_ usage: UsageSnapshot?, mode: UsageDisplayMode,
                      stale: Bool = false) -> NSAttributedString? {
        guard mode != .off, let usage = usage else { return nil }
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        let out = NSMutableAttributedString()

        func append(_ text: String, _ color: NSColor) {
            out.append(NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color]))
        }
        func part(_ percent: Double?, resetSince: Bool) -> (String, NSColor)? {
            if resetSince { return ("0%", .tertiaryLabelColor) }
            guard let p = percent else { return nil }
            return ("\(Int(p.rounded()))%", stale ? .secondaryLabelColor : color(for: p))
        }

        let five = part(usage.fiveHourPercent, resetSince: usage.fiveHourResetSinceUpdate)
        let week = part(usage.weeklyPercent, resetSince: usage.weeklyResetSinceUpdate)
        guard let first = five ?? week else { return nil }
        append(" " + first.0, first.1)
        if mode == .both, five != nil, let w = week {
            append(" / ", .secondaryLabelColor)
            append(w.0, w.1)
        }
        return out
    }

    static func tooltip(_ usage: UsageSnapshot?, status: UsageStatus) -> String {
        guard let u = usage else {
            switch status {
            case .hudOff:         return "사용량을 보려면 Clawd 팝오버에서 HUD를 켜 주세요"
            case .waitingForData: return "Claude Code에서 메시지를 한 번 보내면 사용량이 표시돼요 (Pro, Max)"
            default:              return "oh-my-clawd"
            }
        }
        var lines: [String] = []
        if u.fiveHourResetSinceUpdate {
            lines.append("5시간: 초기화됨 (다음 Claude Code 응답 때 갱신)")
        } else if let p = u.fiveHourPercent {
            lines.append("5시간 \(Int(p.rounded()))%" + reset(u.fiveHourResetsAt))
        }
        if u.weeklyResetSinceUpdate {
            lines.append("주간: 초기화됨 (다음 Claude Code 응답 때 갱신)")
        } else if let p = u.weeklyPercent {
            lines.append("주간 \(Int(p.rounded()))%" + reset(u.weeklyResetsAt))
        }
        for m in u.modelLimits {
            lines.append("주간 \(m.label) \(Int(m.percent.rounded()))%" + reset(m.resetsAt))
        }
        if status == .stale {
            lines.append("\(Int(u.age / 60))분 전 Claude Code 기준 값이에요")
        } else if let pace = UsagePace.summary(u) {
            lines.append(pace)
        }
        return lines.joined(separator: "\n")
    }

    private static func reset(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let diff = date.timeIntervalSinceNow
        guard diff > 0 else { return "" }
        let m = Int(diff / 60), h = m / 60, d = h / 24
        if d > 0 { return " (\(d)일 \(h % 24)시간 후 초기화)" }
        if h > 0 { return " (\(h)시간 \(m % 60)분 후 초기화)" }
        return " (\(m)분 후 초기화)"
    }
}
