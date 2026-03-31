import Foundation

enum PetState: Int, CaseIterable {
    case idle = 0
    case normal = 1
    case busy = 2
    case bloated = 3
    case stressed = 4
    case tired = 5
    case collab = 6

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
        }
    }

    static func resolve(from data: PetStateData) -> PetState {
        guard data.activeSessions > 0 else { return .idle }
        let rl = data.rateLimit.fiveHourPercent ?? 0
        if rl >= 80 { return .stressed }
        if data.aggregate.maxContextPercent >= 70 { return .bloated }
        if data.aggregate.totalToolCalls > 50 { return .busy }
        if data.aggregate.totalRunningAgents > 1 { return .collab }
        if data.aggregate.longestSessionMinutes >= 45 { return .tired }
        return .normal
    }

    static func resolveMuscle(from data: PetStateData) -> MuscleStage {
        let agents = data.aggregate.totalRunningAgents
        return MuscleStage.resolve(agentCount: agents)
    }
}
