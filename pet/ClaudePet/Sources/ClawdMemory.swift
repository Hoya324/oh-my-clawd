import Foundation

// ============================================================================
// MARK: - Model types
// ============================================================================

struct ReminderConfig: Codable, Equatable {
    var enabled: Bool
    var intervalMin: Int?     // water / stretch
    var timeOfDay: String?    // diary, "HH:mm" local
    var lastAt: Double        // unix millis; 0 = never
    var lastDate: String?     // diary only, "YYYY-MM-DD" local

    init(enabled: Bool, intervalMin: Int?, timeOfDay: String?, lastAt: Double, lastDate: String?) {
        self.enabled = enabled
        self.intervalMin = intervalMin
        self.timeOfDay = timeOfDay
        self.lastAt = lastAt
        self.lastDate = lastDate
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = (try? c.decode(Bool.self, forKey: .enabled)) ?? true
        intervalMin = try? c.decodeIfPresent(Int.self, forKey: .intervalMin)
        timeOfDay = try? c.decodeIfPresent(String.self, forKey: .timeOfDay)
        lastAt = (try? c.decode(Double.self, forKey: .lastAt)) ?? 0
        lastDate = try? c.decodeIfPresent(String.self, forKey: .lastDate)
    }
}

struct ClawdReminders: Codable, Equatable {
    var water: ReminderConfig
    var stretch: ReminderConfig
    var diary: ReminderConfig

    static let `default` = ClawdReminders(
        water:   ReminderConfig(enabled: true, intervalMin: 60, timeOfDay: nil, lastAt: 0, lastDate: nil),
        stretch: ReminderConfig(enabled: true, intervalMin: 90, timeOfDay: nil, lastAt: 0, lastDate: nil),
        diary:   ReminderConfig(enabled: true, intervalMin: nil, timeOfDay: "22:00", lastAt: 0, lastDate: nil)
    )

    init(water: ReminderConfig, stretch: ReminderConfig, diary: ReminderConfig) {
        self.water = water
        self.stretch = stretch
        self.diary = diary
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ClawdReminders.default
        water = (try? c.decode(ReminderConfig.self, forKey: .water)) ?? d.water
        stretch = (try? c.decode(ReminderConfig.self, forKey: .stretch)) ?? d.stretch
        diary = (try? c.decode(ReminderConfig.self, forKey: .diary)) ?? d.diary
    }
}

struct ClawdMemo: Codable, Identifiable, Equatable {
    let id: String
    var text: String
    let createdAt: String         // ISO8601
    var dueAt: String?            // ISO8601 or nil
    var tags: [String]
    var done: Bool
    var completedAt: String?

    init(id: String, text: String, createdAt: String, dueAt: String?,
         tags: [String], done: Bool, completedAt: String?) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.dueAt = dueAt
        self.tags = tags
        self.done = done
        self.completedAt = completedAt
    }

    /// Only id and text are required; everything else has a safe default,
    /// so one odd field never makes a memo disappear.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ClawdMemoryStore.isoNow()
        dueAt = try? c.decodeIfPresent(String.self, forKey: .dueAt)
        tags = (try? c.decode([String].self, forKey: .tags)) ?? []
        done = (try? c.decode(Bool.self, forKey: .done)) ?? false
        completedAt = try? c.decodeIfPresent(String.self, forKey: .completedAt)
    }
}

enum ChatRole: String, Codable { case user, clawd, system }

struct ChatTurn: Codable, Equatable {
    let role: ChatRole
    let text: String
    let ts: Double                // unix millis
}

/// Decodes an element if possible, otherwise yields nil instead of failing
/// the whole array.
private struct Lossy<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

struct ClawdMemoryFile: Codable, Equatable {
    var version: Int
    var reminders: ClawdReminders
    var memos: [ClawdMemo]
    var chatLog: [ChatTurn]
    var aiEnabled: Bool?        // nil = default true; false = memo-only mode

    static let empty = ClawdMemoryFile(
        version: 1,
        reminders: .default,
        memos: [],
        chatLog: [],
        aiEnabled: true
    )

    init(version: Int, reminders: ClawdReminders, memos: [ClawdMemo],
         chatLog: [ChatTurn], aiEnabled: Bool?) {
        self.version = version
        self.reminders = reminders
        self.memos = memos
        self.chatLog = chatLog
        self.aiEnabled = aiEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? c.decode(Int.self, forKey: .version)) ?? 1
        reminders = (try? c.decode(ClawdReminders.self, forKey: .reminders)) ?? .default
        memos = ((try? c.decode([Lossy<ClawdMemo>].self, forKey: .memos)) ?? []).compactMap { $0.value }
        chatLog = ((try? c.decode([Lossy<ChatTurn>].self, forKey: .chatLog)) ?? []).compactMap { $0.value }
        aiEnabled = try? c.decodeIfPresent(Bool.self, forKey: .aiEnabled)
    }
}

// ============================================================================
// MARK: - Store
// ============================================================================

final class ClawdMemoryStore {
    /// One store per process so every caller shares the same serial queue.
    static let shared = ClawdMemoryStore()

    static let maxChatTurns = 20
    static let maxDoneMemos = 200
    static let dailyBackupsKept = 7

    private let filePath: String
    private let backupDir: String
    /// Serializes every read-modify-write. The old store read on the caller
    /// thread and wrote asynchronously, so two quick updates could read the
    /// same stale file and the second write silently dropped the first.
    private let queue = DispatchQueue(label: "clawd.memory", qos: .utility)
    private var cached: ClawdMemoryFile?
    private var cachedMTime: Date?

    init(filePath: String = Paths.memory, backupDir: String = Paths.memoryBackupDir) {
        self.filePath = filePath
        self.backupDir = backupDir
        try? FileManager.default.createDirectory(
            atPath: (filePath as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true
        )
    }

    func read() -> ClawdMemoryFile {
        queue.sync { loadLocked() }
    }

    /// Atomically mutate the file. The whole read-modify-write runs on the
    /// store's serial queue. Nothing is written when nothing changed.
    @discardableResult
    func update(_ mutator: (inout ClawdMemoryFile) -> Void) -> ClawdMemoryFile {
        queue.sync { () -> ClawdMemoryFile in
            let before = loadLocked()
            var file = before
            mutator(&file)
            Self.trim(&file)
            if file != before { saveLocked(file) }
            return file
        }
    }

    /// Replace the whole file (kept for callers that build a file themselves).
    func write(_ file: ClawdMemoryFile) {
        queue.sync {
            var f = file
            Self.trim(&f)
            saveLocked(f)
        }
    }

    // MARK: - Private (call on `queue` only)

    private func mtime() -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: filePath))?[.modificationDate] as? Date
    }

    private func loadLocked() -> ClawdMemoryFile {
        let m = mtime()
        if let cached = cached, m == cachedMTime { return cached }

        guard let data = FileManager.default.contents(atPath: filePath) else {
            // No file yet (first launch) — not an error.
            cached = .empty
            cachedMTime = m
            return .empty
        }
        if let decoded = try? JSONDecoder().decode(ClawdMemoryFile.self, from: data) {
            cached = decoded
            cachedMTime = m
            return decoded
        }

        // Unreadable: never overwrite it with an empty file (that used to
        // wipe every memo). Keep a copy aside and fall back to the newest
        // good backup.
        quarantineCorrupt(data)
        let restored = newestBackup() ?? .empty
        saveLocked(restored)
        return restored
    }

    private func saveLocked(_ file: ClawdMemoryFile) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(file),
              JSONFile.writeAtomic(data, to: filePath) else { return }
        cached = file
        cachedMTime = mtime()
        writeDailyBackup(data)
    }

    private static func trim(_ file: inout ClawdMemoryFile) {
        if file.chatLog.count > maxChatTurns {
            file.chatLog = Array(file.chatLog.suffix(maxChatTurns))
        }
        let done = file.memos.filter { $0.done }
        if done.count > maxDoneMemos {
            let drop = Set(done.prefix(done.count - maxDoneMemos).map { $0.id })
            file.memos.removeAll { drop.contains($0.id) }
        }
    }

    // MARK: Backups

    private static func dayString(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    private func writeDailyBackup(_ data: Data) {
        let fm = FileManager.default
        try? fm.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
        let path = backupDir + "/clawd-memory-\(Self.dayString()).json"
        JSONFile.writeAtomic(data, to: path)

        let backups = ((try? fm.contentsOfDirectory(atPath: backupDir)) ?? [])
            .filter { $0.hasPrefix("clawd-memory-") && $0.hasSuffix(".json") }
            .sorted()
        for old in backups.dropLast(Self.dailyBackupsKept) {
            try? fm.removeItem(atPath: backupDir + "/" + old)
        }
    }

    private func newestBackup() -> ClawdMemoryFile? {
        let fm = FileManager.default
        let backups = ((try? fm.contentsOfDirectory(atPath: backupDir)) ?? [])
            .filter { $0.hasPrefix("clawd-memory-") && $0.hasSuffix(".json") }
            .sorted()
            .reversed()
        for name in backups {
            if let data = fm.contents(atPath: backupDir + "/" + name),
               let decoded = try? JSONDecoder().decode(ClawdMemoryFile.self, from: data) {
                return decoded
            }
        }
        return nil
    }

    private func quarantineCorrupt(_ data: Data) {
        try? FileManager.default.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
        let ts = Int(Date().timeIntervalSince1970)
        JSONFile.writeAtomic(data, to: backupDir + "/corrupt-\(ts).json")
    }

    // MARK: - Memo helpers

    static func newMemoId() -> String {
        let ms = Int(Date().timeIntervalSince1970 * 1000)
        let rnd = String(UInt32.random(in: 0..<UInt32.max), radix: 36)
        return "mem_\(ms)_\(rnd)"
    }

    static func isoNow() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.string(from: Date())
    }

    static func parseIso(_ s: String?) -> Date? {
        guard let s, !s.isEmpty else { return nil }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }
}
