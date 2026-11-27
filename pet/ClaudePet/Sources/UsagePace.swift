import Foundation

/// "Am I on track?" — compares how much of a limit is used with how much
/// of its window has passed, the way claude.ai's usage page summarizes it.
/// Purely local arithmetic on the usage snapshot.
enum UsagePace {
    static let fiveHourWindow: TimeInterval = 5 * 3600
    static let weeklyWindow: TimeInterval = 7 * 24 * 3600

    enum Verdict: Equatable {
        /// Projected to end the window under 80%.
        case comfortable
        /// Projected to end between 80% and 100%.
        case tight
        /// Projected to run out before the reset, at roughly this time.
        case fast(Date)
        case limitReached
    }

    static func assess(percent: Double?, resetsAt: Date?, window: TimeInterval,
                       now: Date = Date()) -> Verdict? {
        guard let used = percent, let reset = resetsAt else { return nil }
        let remaining = reset.timeIntervalSince(now)
        guard remaining > 0, remaining <= window * 1.05 else { return nil }
        if used >= 99.5 { return .limitReached }

        let elapsed = max(0, window - remaining)
        // Too early in the window to extrapolate meaningfully.
        guard elapsed >= window * 0.05, used > 0 else { return .comfortable }

        let ratePerSecond = used / elapsed
        let projected = used + ratePerSecond * remaining
        if projected <= 80 { return .comfortable }
        if projected <= 100 { return .tight }
        let secondsToLimit = (100 - used) / ratePerSecond
        return .fast(now.addingTimeInterval(secondsToLimit))
    }

    /// One-line Korean summary. A 5-hour problem wins over the weekly view
    /// because it bites first.
    static func summary(_ u: UsageSnapshot, now: Date = Date()) -> String? {
        let five = assess(percent: u.fiveHourPercent, resetsAt: u.fiveHourResetsAt,
                          window: fiveHourWindow, now: now)
        let week = assess(percent: u.weeklyPercent, resetsAt: u.weeklyResetsAt,
                          window: weeklyWindow, now: now)

        switch five {
        case .limitReached?:
            return "현재 세션 한도에 도달했어요. \(resetPhrase(u.fiveHourResetsAt, now: now))에 다시 쓸 수 있어요."
        case .fast(let at)?:
            return "현재 세션 사용이 빠른 편이에요. 이 속도면 \(clock(at, now: now))쯤 한도에 닿아요."
        default:
            break
        }

        switch week {
        case .limitReached?:
            return "이번 주 한도에 도달했어요. \(resetPhrase(u.weeklyResetsAt, now: now))에 초기화돼요."
        case .fast(let at)?:
            return "이번 주 사용이 빠른 편이에요. 이 속도면 \(clock(at, now: now))쯤 한도에 닿아요."
        case .tight?:
            return "조금 빠듯해요. \(resetPhrase(u.weeklyResetsAt, now: now)) 초기화 직전까지 쓸 수 있을 것 같아요."
        case .comfortable?:
            return "순조로워요. \(resetPhrase(u.weeklyResetsAt, now: now))에 초기화될 때까지 여유 있게 쓸 수 있어요."
        case nil:
            return five == .tight ? "현재 세션이 조금 빠듯해요." : nil
        }
    }

    // MARK: - Date phrases

    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.timeZone = .current
        f.dateFormat = format
        return f
    }

    /// "오후 7:50", "내일 오전 1:00", "일요일 오전 1:00"
    static func clock(_ date: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        let time = formatter("a h:mm").string(from: date)
        if cal.isDate(date, inSameDayAs: now) { return time }
        if let tomorrow = cal.date(byAdding: .day, value: 1, to: now),
           cal.isDate(date, inSameDayAs: tomorrow) {
            return "내일 \(time)"
        }
        return "\(formatter("EEEE").string(from: date)) \(time)"
    }

    /// Weekday only for far resets ("일요일"), clock time for near ones.
    static func resetPhrase(_ date: Date?, now: Date = Date()) -> String {
        guard let date = date else { return "초기화 시점" }
        if date.timeIntervalSince(now) > 24 * 3600 {
            return formatter("EEEE").string(from: date)
        }
        return clock(date, now: now)
    }

    /// "오후 7:50에 초기화", "(일요일) 오전 1:00에 초기화"
    static func resetLabel(_ date: Date?, now: Date = Date()) -> String? {
        guard let date = date, date > now else { return nil }
        let cal = Calendar.current
        let time = formatter("a h:mm").string(from: date)
        if cal.isDate(date, inSameDayAs: now) { return "\(time)에 초기화" }
        return "(\(formatter("EEEE").string(from: date))) \(time)에 초기화"
    }
}
