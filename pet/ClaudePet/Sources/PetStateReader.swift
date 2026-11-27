import Foundation

// All decoders below are lenient: a missing or mistyped field falls back to
// a default instead of failing the whole file. The aggregator and the app
// ship separately (DMG vs. runtime scripts), so the schema must tolerate
// version skew in both directions.

struct RateLimitData: Codable, Equatable {
    var fiveHourPercent: Double?
    var weeklyPercent: Double?
    var fiveHourResetsAt: String?
    var weeklyResetsAt: String?

    static let empty = RateLimitData()

    init(fiveHourPercent: Double? = nil, weeklyPercent: Double? = nil,
         fiveHourResetsAt: String? = nil, weeklyResetsAt: String? = nil) {
        self.fiveHourPercent = fiveHourPercent
        self.weeklyPercent = weeklyPercent
        self.fiveHourResetsAt = fiveHourResetsAt
        self.weeklyResetsAt = weeklyResetsAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fiveHourPercent = try? c.decodeIfPresent(Double.self, forKey: .fiveHourPercent)
        weeklyPercent = try? c.decodeIfPresent(Double.self, forKey: .weeklyPercent)
        fiveHourResetsAt = try? c.decodeIfPresent(String.self, forKey: .fiveHourResetsAt)
        weeklyResetsAt = try? c.decodeIfPresent(String.self, forKey: .weeklyResetsAt)
    }
}

struct AggregateData: Codable {
    var maxContextPercent: Double = 0
    var totalToolCalls: Int = 0
    var totalRunningAgents: Int = 0
    var longestSessionMinutes: Int = 0
    var dominantModel: String = "unknown"

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        maxContextPercent = (try? c.decode(Double.self, forKey: .maxContextPercent)) ?? 0
        totalToolCalls = (try? c.decode(Int.self, forKey: .totalToolCalls)) ?? 0
        totalRunningAgents = (try? c.decode(Int.self, forKey: .totalRunningAgents)) ?? 0
        longestSessionMinutes = (try? c.decode(Int.self, forKey: .longestSessionMinutes)) ?? 0
        dominantModel = (try? c.decode(String.self, forKey: .dominantModel)) ?? "unknown"
    }
}

struct SessionData: Codable {
    var pid: Int = 0
    var sessionId: String?
    var project: String = "unknown"
    var model: String = "unknown"
    var contextPercent: Double = 0
    var toolCalls: Int = 0
    var runningAgents: Int = 0
    var sessionMinutes: Int = 0
    var hasHud: Bool = false

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        pid = (try? c.decode(Int.self, forKey: .pid)) ?? 0
        sessionId = try? c.decodeIfPresent(String.self, forKey: .sessionId)
        project = (try? c.decode(String.self, forKey: .project)) ?? "unknown"
        model = (try? c.decode(String.self, forKey: .model)) ?? "unknown"
        contextPercent = (try? c.decode(Double.self, forKey: .contextPercent)) ?? 0
        toolCalls = (try? c.decode(Int.self, forKey: .toolCalls)) ?? 0
        runningAgents = (try? c.decode(Int.self, forKey: .runningAgents)) ?? 0
        sessionMinutes = (try? c.decode(Int.self, forKey: .sessionMinutes)) ?? 0
        hasHud = (try? c.decode(Bool.self, forKey: .hasHud)) ?? false
    }
}

struct ProjectGroup: Codable, Equatable {
    var name: String
    var count: Int
}

struct PetStateData: Codable {
    var timestamp: Double = 0
    var activeSessions: Int = 0
    var rateLimit: RateLimitData = .empty
    var aggregate: AggregateData = AggregateData()
    var sessions: [SessionData] = []
    var projects: [ProjectGroup] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = (try? c.decode(Double.self, forKey: .timestamp)) ?? 0
        rateLimit = (try? c.decode(RateLimitData.self, forKey: .rateLimit)) ?? .empty
        aggregate = (try? c.decode(AggregateData.self, forKey: .aggregate)) ?? AggregateData()
        sessions = (try? c.decode([SessionData].self, forKey: .sessions)) ?? []
        activeSessions = (try? c.decode(Int.self, forKey: .activeSessions)) ?? sessions.count
        if let groups = try? c.decode([ProjectGroup].self, forKey: .projects) {
            projects = groups
        } else {
            // Older aggregators: group the flat session list ourselves.
            projects = PetStateData.group(sessions.map { $0.project })
        }
    }

    static func group(_ names: [String]) -> [ProjectGroup] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        for n in names {
            if counts[n] == nil { order.append(n) }
            counts[n, default: 0] += 1
        }
        return order.map { ProjectGroup(name: $0, count: counts[$0] ?? 1) }
    }
}

final class PetStateReader {
    /// The aggregator rewrites the file at least every 15 s. Anything older
    /// than this means the daemon is not running, so the data is stale and
    /// must not keep Clawd "awake" forever.
    static let staleAfter: TimeInterval = 60

    private let filePath: String

    init(filePath: String = Paths.petState) {
        self.filePath = filePath
    }

    /// Fresh aggregator data, or nil when missing, unreadable or stale.
    func read() -> PetStateData? {
        guard let data = JSONFile.read(filePath),
              let decoded = try? JSONDecoder().decode(PetStateData.self, from: data) else {
            return nil
        }
        let ageSeconds = Date().timeIntervalSince1970 - decoded.timestamp / 1000
        guard ageSeconds <= Self.staleAfter else { return nil }
        return decoded
    }

    /// True when the aggregator has written recently (used for diagnostics).
    func isAggregatorAlive() -> Bool {
        read() != nil
    }
}
