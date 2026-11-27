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

    static func title(_ usage: UsageSnapshot?, mode: UsageDisplayMode) -> NSAttributedString? {
        guard mode != .off, let usage = usage else { return nil }
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        let out = NSMutableAttributedString()

        func append(_ text: String, _ color: NSColor) {
            out.append(NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color]))
        }

        guard let five = usage.fiveHourPercent ?? usage.weeklyPercent else { return nil }
        append(" \(Int(five.rounded()))%", color(for: five))

        if mode == .both, usage.fiveHourPercent != nil, let week = usage.weeklyPercent {
            append(" / ", .secondaryLabelColor)
            append("\(Int(week.rounded()))%", color(for: week))
        }
        return out
    }

    static func tooltip(_ usage: UsageSnapshot?, status: UsageStatus) -> String {
        guard let u = usage else {
            switch status {
            case .noCredentials: return "Claude Code 로그인 시 사용량이 표시돼요"
            case .tokenExpired:  return "로그인 만료: Claude Code를 실행하면 갱신돼요"
            default:             return "oh-my-clawd"
            }
        }
        var lines: [String] = []
        if let p = u.fiveHourPercent {
            lines.append("5시간 \(Int(p.rounded()))%" + reset(u.fiveHourResetsAt))
        }
        if let p = u.weeklyPercent {
            lines.append("주간 \(Int(p.rounded()))%" + reset(u.weeklyResetsAt))
        }
        for m in u.modelLimits {
            lines.append("주간 \(m.label) \(Int(m.percent.rounded()))%" + reset(m.resetsAt))
        }
        if let pace = UsagePace.summary(u) {
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
