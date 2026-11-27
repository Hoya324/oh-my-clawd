import Foundation

// ============================================================================
// MARK: - Progress (read-only: owned by the aggregator)
// ============================================================================

struct UnlockProgress: Codable, Equatable {
    var metric: String
    var current: Int
    var target: Int
}

struct ProgressData {
    var stats: [String: Int]
    var unlockedAccessories: [String]
    var unlockedAt: [String: String]
    var unlockProgress: [String: UnlockProgress]
}

/// Reads ~/.claude/pet/progress.json. The app never writes this file; the
/// aggregator is its only writer, which removes the read-modify-write race
/// that used to drop accessory selections.
final class ProgressTracker {
    private let filePath: String

    init(filePath: String = Paths.progress) {
        self.filePath = filePath
    }

    func read() -> ProgressData? {
        guard let root = JSONFile.readObject(filePath) else { return nil }

        var stats: [String: Int] = [:]
        if let raw = root["stats"] as? [String: Any] {
            for (k, v) in raw {
                if let n = v as? NSNumber { stats[k] = n.intValue }
            }
        }

        var progress: [String: UnlockProgress] = [:]
        if let raw = root["unlockProgress"] as? [String: Any] {
            for (id, value) in raw {
                guard let obj = value as? [String: Any],
                      let current = (obj["current"] as? NSNumber)?.intValue,
                      let target = (obj["target"] as? NSNumber)?.intValue else { continue }
                progress[id] = UnlockProgress(
                    metric: obj["metric"] as? String ?? "",
                    current: current,
                    target: target
                )
            }
        }

        return ProgressData(
            stats: stats,
            unlockedAccessories: root["unlockedAccessories"] as? [String] ?? [],
            unlockedAt: root["unlockedAt"] as? [String: String] ?? [:],
            unlockProgress: progress
        )
    }

    func isUnlocked(_ accessory: AccessoryType) -> Bool {
        read()?.unlockedAccessories.contains(accessory.rawValue) ?? false
    }

    func unlockProgress(for accessory: AccessoryType) -> UnlockProgress? {
        read()?.unlockProgress[accessory.rawValue]
    }

    /// The locked accessory closest to unlocking.
    func nextUnlock(in progress: ProgressData? = nil) -> (AccessoryType, UnlockProgress)? {
        guard let progress = progress ?? read() else { return nil }
        var best: (AccessoryType, UnlockProgress)?
        var bestRatio = -1.0
        for accessory in AccessoryType.allCases {
            guard !progress.unlockedAccessories.contains(accessory.rawValue),
                  let p = progress.unlockProgress[accessory.rawValue],
                  p.target > 0 else { continue }
            let ratio = Double(p.current) / Double(p.target)
            if ratio > bestRatio {
                bestRatio = ratio
                best = (accessory, p)
            }
        }
        return best
    }
}

// ============================================================================
// MARK: - Selection (owned by the app)
// ============================================================================

struct AccessorySelection: Codable, Equatable {
    var selectedHat: String?
    var selectedGlasses: String?
    var selectedPants: String?

    static let none = AccessorySelection()

    var hat: AccessoryType? { selectedHat.flatMap(AccessoryType.init(rawValue:)) }
    var glasses: AccessoryType? { selectedGlasses.flatMap(AccessoryType.init(rawValue:)) }
    var pants: AccessoryType? { selectedPants.flatMap(AccessoryType.init(rawValue:)) }
}

/// ~/.claude/pet/selection.json — written only by the app.
/// Falls back to the selection fields of a pre-v3 progress.json until the
/// aggregator (or the first user change) migrates them.
final class SelectionStore {
    private let filePath: String
    private let legacyProgressPath: String
    private var cache: AccessorySelection?
    private var cacheMTime: Date?

    init(filePath: String = Paths.selection, legacyProgressPath: String = Paths.progress) {
        self.filePath = filePath
        self.legacyProgressPath = legacyProgressPath
    }

    func read() -> AccessorySelection {
        let mtime = (try? FileManager.default.attributesOfItem(atPath: filePath))?[.modificationDate] as? Date
        if let cache = cache, mtime != nil, mtime == cacheMTime { return cache }

        if let data = JSONFile.read(filePath),
           let decoded = try? JSONDecoder().decode(AccessorySelection.self, from: data) {
            cache = decoded
            cacheMTime = mtime
            return decoded
        }
        // Legacy: selection still lives inside progress.json.
        if let root = JSONFile.readObject(legacyProgressPath) {
            return AccessorySelection(
                selectedHat: root["selectedHat"] as? String,
                selectedGlasses: root["selectedGlasses"] as? String,
                selectedPants: root["selectedPants"] as? String
            )
        }
        return .none
    }

    func update(_ mutate: (inout AccessorySelection) -> Void) {
        var selection = read()
        mutate(&selection)
        guard let data = try? JSONEncoder().encode(selection) else { return }
        if JSONFile.writeAtomic(data, to: filePath) {
            cache = selection
            cacheMTime = (try? FileManager.default.attributesOfItem(atPath: filePath))?[.modificationDate] as? Date
        }
    }

    func select(_ accessory: AccessoryType?, category: AccessoryCategory) {
        update { s in
            switch category {
            case .hat:     s.selectedHat = accessory?.rawValue
            case .glasses: s.selectedGlasses = accessory?.rawValue
            case .pants:   s.selectedPants = accessory?.rawValue
            }
        }
    }
}
