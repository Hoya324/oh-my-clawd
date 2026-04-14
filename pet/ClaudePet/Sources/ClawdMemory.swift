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
}

struct ClawdMemo: Codable, Identifiable, Equatable {
    let id: String
    var text: String
    let createdAt: String         // ISO8601
    var dueAt: String?            // ISO8601 or nil
    var tags: [String]
    var done: Bool
    var completedAt: String?
}

enum ChatRole: String, Codable { case user, clawd, system }

struct ChatTurn: Codable, Equatable {
    let role: ChatRole
    let text: String
    let ts: Double                // unix millis
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
}

// ============================================================================
// MARK: - Store
// ============================================================================

final class ClawdMemoryStore {
    private let filePath: String
    private let queue = DispatchQueue(label: "clawd.memory", qos: .utility)

    init() {
        let dir = NSHomeDirectory() + "/.claude/pet"
        try? FileManager.default.createDirectory(
            atPath: dir, withIntermediateDirectories: true
        )
        filePath = dir + "/clawd-memory.json"
    }

    func read() -> ClawdMemoryFile {
        guard let data = FileManager.default.contents(atPath: filePath),
              let decoded = try? JSONDecoder().decode(ClawdMemoryFile.self, from: data) else {
            return .empty
        }
        return decoded
    }

    /// Atomic write. Safe to call from the main thread; serializes to a
    /// background queue.
    func write(_ file: ClawdMemoryFile) {
        queue.async { [filePath] in
            guard let data = try? JSONEncoder().encode(file) else { return }
            let tmp = filePath + ".tmp"
            FileManager.default.createFile(atPath: tmp, contents: data)
            _ = try? FileManager.default.replaceItemAt(
                URL(fileURLWithPath: filePath),
                withItemAt: URL(fileURLWithPath: tmp)
            )
        }
    }

    /// Atomically mutate the file. Closure receives a mutable copy and
    /// returns the new file to persist. Reads are on the caller thread;
    /// writes are serialized on the store's queue.
    @discardableResult
    func update(_ mutator: (inout ClawdMemoryFile) -> Void) -> ClawdMemoryFile {
        var file = read()
        mutator(&file)
        // Cap chat log at last 20 turns
        if file.chatLog.count > 20 {
            file.chatLog = Array(file.chatLog.suffix(20))
        }
        write(file)
        return file
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
