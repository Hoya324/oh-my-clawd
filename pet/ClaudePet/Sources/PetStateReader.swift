import Foundation

struct RateLimitData: Codable {
    let fiveHourPercent: Double?
    let weeklyPercent: Double?
    let fiveHourResetsAt: String?
    let weeklyResetsAt: String?
}

struct AggregateData: Codable {
    let maxContextPercent: Double
    let totalToolCalls: Int
    let totalRunningAgents: Int
    let longestSessionMinutes: Int
    let dominantModel: String
}

struct SessionData: Codable {
    let pid: Int
    let project: String
    let model: String
    let contextPercent: Double
    let toolCalls: Int
    let runningAgents: Int
    let sessionMinutes: Int
}

struct PetStateData: Codable {
    let timestamp: Double
    let activeSessions: Int
    let rateLimit: RateLimitData
    let aggregate: AggregateData
    let sessions: [SessionData]
}

class PetStateReader {
    private let filePath: String

    init() {
        filePath = NSHomeDirectory() + "/.claude/pet/pet-state.json"
    }

    func read() -> PetStateData? {
        guard let data = FileManager.default.contents(atPath: filePath) else { return nil }
        return try? JSONDecoder().decode(PetStateData.self, from: data)
    }
}
