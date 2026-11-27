import Foundation

enum PetState: Int, CaseIterable {
    case idle = 0
    case normal = 1
    case busy = 2
    case bloated = 3
    case stressed = 4
    case tired = 5
    case collab = 6
    case wakeUp = 7
    /// Claude is in use outside Claude Code (desktop app, web, mobile).
    case chatting = 8

    var spriteRow: Int { rawValue }

    var frameInterval: TimeInterval {
        switch self {
        case .idle:     return 0.8
        case .normal:   return 0.2
        case .busy:     return 0.1
        case .bloated:  return 0.5
        case .stressed: return 0.15
        case .tired:    return 0.6
        case .collab:   return 0.2
        case .wakeUp:   return 0.3
        case .chatting: return 0.35
        }
    }

    var displayName: String {
        switch self {
        case .idle:     return "Sleeping..."
        case .normal:   return "Walking happily"
        case .busy:     return "Working hard!"
        case .bloated:  return "Context is full..."
        case .stressed: return "Rate limit warning!"
        case .tired:    return "Getting tired..."
        case .collab:   return "Working together!"
        case .wakeUp:   return "Waking up!"
        case .chatting: return "Chatting with Claude"
        }
    }

    var displayNameKO: String {
        switch self {
        case .idle:     return "자고 있어요..."
        case .normal:   return "신나게 걷는 중"
        case .busy:     return "열심히 일하는 중!"
        case .bloated:  return "컨텍스트가 가득..."
        case .stressed: return "사용량 경고!"
        case .tired:    return "피곤해요..."
        case .collab:   return "함께 일하는 중!"
        case .wakeUp:   return "깨어나는 중!"
        case .chatting: return "Claude랑 대화 중"
        }
    }

    /// Resolve the pet state from every available signal.
    /// - data: fresh aggregator state (Claude Code sessions), if any
    /// - usage: account usage from UsageService (covers every surface)
    /// - chatting: Claude used outside Claude Code (see ChatActivityMonitor)
    static func resolve(data: PetStateData?, usage: UsageSnapshot?, chatting: Bool) -> PetState {
        let fiveHour = usage?.fiveHourPercent ?? data?.rateLimit.fiveHourPercent ?? 0

        if let data = data, data.activeSessions > 0 {
            if fiveHour >= 80 { return .stressed }
            if data.aggregate.maxContextPercent >= 70 { return .bloated }
            if data.aggregate.totalToolCalls > 50 { return .busy }
            if data.aggregate.totalRunningAgents > 1 { return .collab }
            if data.aggregate.longestSessionMinutes >= 45 { return .tired }
            return .normal
        }
        if chatting {
            return fiveHour >= 80 ? .stressed : .chatting
        }
        return .idle
    }

    /// Kept for callers that only have aggregator data.
    static func resolve(from data: PetStateData) -> PetState {
        resolve(data: data, usage: nil, chatting: false)
    }

    static func resolveActivityLevel(from data: PetStateData?) -> ActivityLevel {
        ActivityLevel.resolve(agentCount: data?.aggregate.totalRunningAgents ?? 0)
    }
}
