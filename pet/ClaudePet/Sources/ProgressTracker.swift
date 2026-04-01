import Foundation

struct ProgressStats: Codable {
    var totalSessions: Int
    var totalTimeMinutes: Int
    var totalTokens: Int
    var totalAgentRuns: Int
    var maxConcurrentSessions: Int
    var maxConcurrentAgents: Int
    var rateLimitHits: Int
    var longSessions: Int
    var opusTimeMinutes: Int
}

struct ProgressData: Codable {
    var stats: ProgressStats
    var unlocked: [String]
    var selectedPet: String
    var unlockedAt: [String: String]
}

class ProgressTracker {
    private let filePath: String

    init() {
        filePath = NSHomeDirectory() + "/.claude/pet/progress.json"
    }

    func read() -> ProgressData? {
        guard let data = FileManager.default.contents(atPath: filePath) else { return nil }
        return try? JSONDecoder().decode(ProgressData.self, from: data)
    }

    func isUnlocked(_ pet: PetType) -> Bool {
        guard let progress = read() else { return pet == .cat }
        return progress.unlocked.contains(pet.rawValue)
    }

    func selectedPet() -> PetType {
        guard let progress = read(),
              let pet = PetType(rawValue: progress.selectedPet) else { return .cat }
        return pet
    }

    func selectPet(_ pet: PetType) {
        guard var progress = read() else { return }
        progress.selectedPet = pet.rawValue
        guard let data = try? JSONEncoder().encode(progress) else { return }
        let tmpPath = filePath + ".tmp"
        FileManager.default.createFile(atPath: tmpPath, contents: data)
        try? FileManager.default.moveItem(atPath: tmpPath, toPath: filePath)
    }

    func unlockProgress(for pet: PetType) -> (current: Int, target: Int)? {
        guard let progress = read() else { return nil }
        let stats = progress.stats

        switch pet {
        case .cat:      return nil
        case .hamster:  return (stats.totalSessions, 10)
        case .chick:    return (stats.totalTimeMinutes, 300)
        case .penguin:  return (stats.totalTokens, 500_000)
        case .fox:      return (stats.totalAgentRuns, 50)
        case .rabbit:   return (stats.maxConcurrentSessions, 3)
        case .goose:    return (stats.totalTimeMinutes, 1800)
        case .capybara: return (stats.rateLimitHits, 10)
        case .sloth:    return (stats.longSessions, 20)
        case .owl:      return (stats.opusTimeMinutes, 600)
        case .dragon:   return (stats.maxConcurrentAgents, 5)
        case .unicorn:
            let allPets = PetType.allCases.filter { $0 != .unicorn }
            let unlocked = allPets.filter { progress.unlocked.contains($0.rawValue) }.count
            return (unlocked, allPets.count)
        }
    }

    func nextUnlock() -> PetType? {
        guard let progress = read() else { return nil }
        var bestPet: PetType?
        var bestRatio: Double = -1

        for pet in PetType.allCases {
            guard !progress.unlocked.contains(pet.rawValue) else { continue }
            guard let (current, target) = unlockProgress(for: pet), target > 0 else { continue }
            let ratio = Double(current) / Double(target)
            if ratio > bestRatio {
                bestRatio = ratio
                bestPet = pet
            }
        }
        return bestPet
    }
}
