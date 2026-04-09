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
    var version: Int
    var stats: ProgressStats
    var unlockedAccessories: [String]
    var selectedHat: String?
    var selectedGlasses: String?
    var unlockedAt: [String: String]
}

// v1 schema used before the single-character redesign
private struct ProgressDataV1: Codable {
    var stats: ProgressStats
    var unlocked: [String]
    var selectedPet: String
    var unlockedAt: [String: String]
}

// Maps old pet raw values → accessory raw values.
// Pets with no mapping (dragon, unicorn) are dropped.
// "cat" was the default and requires no mapping.
private let petToAccessoryMap: [String: String] = [
    "hamster":  "cap",
    "chick":    "partyHat",
    "penguin":  "santaHat",
    "fox":      "silkHat",
    "rabbit":   "hornRimmed",
    "goose":    "cowboyHat",
    "capybara": "sunglasses",
    "sloth":    "roundGlasses",
    "owl":      "starGlasses"
]

class ProgressTracker {
    private let filePath: String

    init() {
        filePath = NSHomeDirectory() + "/.claude/pet/progress.json"
    }

    // MARK: - Read / Migration

    func read() -> ProgressData? {
        guard let rawData = FileManager.default.contents(atPath: filePath) else { return nil }

        // Try decoding as v2 first
        if let v2 = try? JSONDecoder().decode(ProgressData.self, from: rawData),
           v2.version >= 2 {
            return v2
        }

        // Fall back to v1 and migrate
        guard let v1 = try? JSONDecoder().decode(ProgressDataV1.self, from: rawData) else {
            return nil
        }

        return migrateV1(v1)
    }

    private func migrateV1(_ v1: ProgressDataV1) -> ProgressData {
        // Convert old pet unlocks to accessory unlocks
        var accessories: [String] = []
        for petName in v1.unlocked {
            if let accessoryName = petToAccessoryMap[petName] {
                accessories.append(accessoryName)
            }
            // "cat" and unknown pets (dragon, unicorn) are silently dropped
        }

        // Convert selected pet to hat/glasses selection
        var selectedHat: String? = nil
        var selectedGlasses: String? = nil
        if let accessoryName = petToAccessoryMap[v1.selectedPet] {
            if let accessory = AccessoryType(rawValue: accessoryName) {
                if accessory.category == .hat {
                    selectedHat = accessoryName
                } else {
                    selectedGlasses = accessoryName
                }
            }
        }
        // If selected pet was cat, dragon, or unicorn there is no accessory to select

        // Build unlockedAt with remapped keys
        var newUnlockedAt: [String: String] = [:]
        for (petName, dateStr) in v1.unlockedAt {
            if let accessoryName = petToAccessoryMap[petName] {
                newUnlockedAt[accessoryName] = dateStr
            }
        }

        let v2 = ProgressData(
            version: 2,
            stats: v1.stats,
            unlockedAccessories: accessories,
            selectedHat: selectedHat,
            selectedGlasses: selectedGlasses,
            unlockedAt: newUnlockedAt
        )

        // Persist immediately so subsequent reads are fast
        writeBack(v2)
        return v2
    }

    // MARK: - Write helpers

    private func writeBack(_ data: ProgressData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        let tmpPath = filePath + ".tmp"
        FileManager.default.createFile(atPath: tmpPath, contents: encoded)
        let _ = try? FileManager.default.replaceItemAt(
            URL(fileURLWithPath: filePath),
            withItemAt: URL(fileURLWithPath: tmpPath)
        )
    }

    // MARK: - Unlock queries

    func isUnlocked(_ accessory: AccessoryType) -> Bool {
        guard let progress = read() else { return false }
        return progress.unlockedAccessories.contains(accessory.rawValue)
    }

    // MARK: - Selection queries

    func selectedHat() -> AccessoryType? {
        guard let progress = read(),
              let raw = progress.selectedHat else { return nil }
        return AccessoryType(rawValue: raw)
    }

    func selectedGlasses() -> AccessoryType? {
        guard let progress = read(),
              let raw = progress.selectedGlasses else { return nil }
        return AccessoryType(rawValue: raw)
    }

    // MARK: - Selection setters

    func selectHat(_ hat: AccessoryType?) {
        guard var progress = read() else { return }
        progress.selectedHat = hat?.rawValue
        writeBack(progress)
    }

    func selectGlasses(_ glasses: AccessoryType?) {
        guard var progress = read() else { return }
        progress.selectedGlasses = glasses?.rawValue
        writeBack(progress)
    }

    // MARK: - Unlock progress

    func unlockProgress(for accessory: AccessoryType) -> (current: Int, target: Int)? {
        guard let progress = read() else { return nil }
        let stats = progress.stats

        switch accessory {
        case .cap:          return (stats.totalSessions, 10)
        case .partyHat:     return (stats.totalTimeMinutes, 300)
        case .santaHat:     return (stats.totalTokens, 500_000)
        case .silkHat:      return (stats.totalAgentRuns, 50)
        case .cowboyHat:    return (stats.totalTimeMinutes, 1800)
        case .hornRimmed:   return (stats.maxConcurrentSessions, 3)
        case .sunglasses:   return (stats.rateLimitHits, 10)
        case .roundGlasses: return (stats.longSessions, 20)
        case .starGlasses:  return (stats.opusTimeMinutes, 600)
        case .jeans:        return (stats.totalTimeMinutes, 900)
        case .shorts:       return (stats.totalSessions, 100)
        case .slacks:       return (stats.totalTokens, 1_000_000)
        case .joggers:      return (stats.totalAgentRuns, 100)
        case .cargo:        return (stats.totalTimeMinutes, 3000)
        }
    }

    // MARK: - Next unlock

    func nextUnlock() -> AccessoryType? {
        guard let progress = read() else { return nil }
        var bestAccessory: AccessoryType?
        var bestRatio: Double = -1

        for accessory in AccessoryType.allCases {
            guard !progress.unlockedAccessories.contains(accessory.rawValue) else { continue }
            guard let (current, target) = unlockProgress(for: accessory), target > 0 else { continue }
            let ratio = Double(current) / Double(target)
            if ratio > bestRatio {
                bestRatio = ratio
                bestAccessory = accessory
            }
        }
        return bestAccessory
    }
}
