import Foundation

/// A point-in-time view of the account's rate limits.
/// A per-model weekly limit (e.g. Opus), when the account has one.
struct ModelLimit: Equatable {
    var model: String          // "opus", "sonnet"
    var percent: Double
    var resetsAt: Date?

    var label: String { model.prefix(1).uppercased() + model.dropFirst() }
}

struct UsageSnapshot: Equatable {
    var fiveHourPercent: Double?
    var weeklyPercent: Double?
    var fiveHourResetsAt: Date?
    var weeklyResetsAt: Date?
    var fetchedAt: Date
    var modelLimits: [ModelLimit] = []

    var rateLimit: RateLimitData {
        let iso = ISO8601DateFormatter()
        return RateLimitData(
            fiveHourPercent: fiveHourPercent,
            weeklyPercent: weeklyPercent,
            fiveHourResetsAt: fiveHourResetsAt.map { iso.string(from: $0) },
            weeklyResetsAt: weeklyResetsAt.map { iso.string(from: $0) }
        )
    }
}

enum UsageStatus: Equatable {
    case loading
    case ok
    /// No Claude Code credentials on this Mac (claude.ai-only users).
    case noCredentials
    /// Token expired; Claude Code refreshes it the next time it runs.
    case tokenExpired
    case failed
}

/// Fetches account usage directly so the menu bar shows it even when no
/// Claude Code session or HUD is running. Shares
/// ~/.claude/pet/usage-cache.json with the HUD (runtime/lib/usage.mjs):
/// whichever fetches first serves the other.
///
/// Never refreshes OAuth tokens — see runtime/lib/usage.mjs for why.
final class UsageService {
    static let ttl: TimeInterval = 90
    static let failureTTL: TimeInterval = 30
    static let rateLimitBackoff: TimeInterval = 300
    static let pollInterval: TimeInterval = 30

    private(set) var snapshot: UsageSnapshot?
    private(set) var status: UsageStatus = .loading

    /// Called on the main queue whenever the snapshot or status changes.
    var onUpdate: ((UsageSnapshot?, UsageStatus) -> Void)?

    private var timer: Timer?
    private var inFlight = false
    private let refresher = CredentialRefresher()
    private let queue = DispatchQueue(label: "clawd.usage", qos: .utility)

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer!, forMode: .common)
        refresh()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Serve the shared cache when fresh, otherwise call the API.
    func refresh(force: Bool = false) {
        guard !inFlight else { return }
        inFlight = true
        let current = snapshot
        let needPlan = !planChecked
        planChecked = true
        queue.async { [weak self] in
            guard let self = self else { return }
            let now = Date()
            let cache = Self.readCache()

            if needPlan, let raw = Self.readCredentials()?.subscriptionType,
               let plan = Self.planName(raw) {
                DispatchQueue.main.async { self.plan = plan }
            }

            if !force, let cache = cache, Self.isFresh(cache, now: now) {
                self.finish(snapshot: cache.snapshot ?? current,
                            status: cache.error && cache.snapshot == nil ? .failed : .ok)
                return
            }

            guard var creds = Self.readCredentials() else {
                self.finish(snapshot: cache?.snapshot, status: .noCredentials)
                return
            }
            if let exp = creds.expiresAt, exp <= now {
                // Expired and Claude Code is not around to refresh it:
                // refresh safely ourselves (see CredentialRefresher).
                guard case .refreshed(let fresh) = self.refresher.refreshIfPossible(now: now) else {
                    self.finish(snapshot: cache?.snapshot, status: .tokenExpired)
                    return
                }
                creds = fresh
            }

            self.fetch(token: creds.token) { result in
                switch result {
                case .success(let snap):
                    Self.writeCache(snapshot: snap, error: false, retryAfter: nil, now: now)
                    self.finish(snapshot: snap, status: .ok)
                case .failure(let httpStatus):
                    let keep = cache?.snapshot ?? current
                    let retry = httpStatus.code == 429 ? now.addingTimeInterval(Self.rateLimitBackoff) : nil
                    Self.writeCache(snapshot: keep, error: true, retryAfter: retry, now: now)
                    self.finish(snapshot: keep, status: keep == nil ? .failed : .ok)
                }
            }
        }
    }

    private func finish(snapshot: UsageSnapshot?, status: UsageStatus) {
        DispatchQueue.main.async {
            self.inFlight = false
            let changed = snapshot != self.snapshot || status != self.status
            self.snapshot = snapshot
            self.status = status
            if changed { self.onUpdate?(snapshot, status) }
        }
    }

    // MARK: - API

    private func fetch(token: String, completion: @escaping (Result<UsageSnapshot, HTTPStatus>) -> Void) {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        req.httpMethod = "GET"
        req.timeoutInterval = 10
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: req) { data, response, _ in
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard code == 200, let data = data,
                  let snap = Self.parseAPI(data, now: Date()) else {
                completion(.failure(HTTPStatus(code: code)))
                return
            }
            completion(.success(snap))
        }.resume()
    }

    struct HTTPStatus: Error, Equatable {
        let code: Int
    }

    static func parseAPI(_ data: Data, now: Date) -> UsageSnapshot? {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        let five = root["five_hour"] as? [String: Any]
        let week = root["seven_day"] as? [String: Any]
        let fivePct = clamp((five?["utilization"] as? NSNumber)?.doubleValue)
        let weekPct = clamp((week?["utilization"] as? NSNumber)?.doubleValue)
        if fivePct == nil && weekPct == nil { return nil }
        var models: [ModelLimit] = []
        for model in modelKeys {
            guard let obj = root["seven_day_\(model)"] as? [String: Any],
                  let pct = clamp((obj["utilization"] as? NSNumber)?.doubleValue) else { continue }
            models.append(ModelLimit(model: model, percent: pct,
                                     resetsAt: parseDate(obj["resets_at"] as? String)))
        }
        return UsageSnapshot(
            fiveHourPercent: fivePct,
            weeklyPercent: weekPct,
            fiveHourResetsAt: parseDate(five?["resets_at"] as? String),
            weeklyResetsAt: parseDate(week?["resets_at"] as? String),
            fetchedAt: now,
            modelLimits: models
        )
    }

    /// Per-model weekly limits the API may report ("seven_day_<model>").
    static let modelKeys = ["opus", "sonnet"]

    private static func clamp(_ v: Double?) -> Double? {
        guard let v = v, v.isFinite else { return nil }
        return min(100, max(0, v))
    }

    static func parseDate(_ s: String?) -> Date? {
        guard let s = s, !s.isEmpty else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withFraction.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }

    // MARK: - Shared cache (same format as runtime/lib/usage.mjs)

    struct CacheEntry {
        var timestamp: Date
        var snapshot: UsageSnapshot?
        var error: Bool
        var retryAfter: Date?
    }

    static func readCache() -> CacheEntry? {
        guard let root = JSONFile.readObject(Paths.usageCache),
              let ts = (root["timestamp"] as? NSNumber)?.doubleValue else { return nil }
        let timestamp = Date(timeIntervalSince1970: ts / 1000)
        var snap: UsageSnapshot?
        if let d = root["data"] as? [String: Any] {
            let five = (d["fiveHourPercent"] as? NSNumber)?.doubleValue
            let week = (d["weeklyPercent"] as? NSNumber)?.doubleValue
            if five != nil || week != nil {
                let models = (d["models"] as? [[String: Any]] ?? []).compactMap { m -> ModelLimit? in
                    guard let name = m["model"] as? String,
                          let pct = (m["percent"] as? NSNumber)?.doubleValue else { return nil }
                    return ModelLimit(model: name, percent: pct, resetsAt: parseDate(m["resetsAt"] as? String))
                }
                snap = UsageSnapshot(
                    fiveHourPercent: five,
                    weeklyPercent: week,
                    fiveHourResetsAt: parseDate(d["fiveHourResetsAt"] as? String),
                    weeklyResetsAt: parseDate(d["weeklyResetsAt"] as? String),
                    fetchedAt: timestamp,
                    modelLimits: models
                )
            }
        }
        let retry = (root["retryAfter"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) }
        return CacheEntry(timestamp: timestamp, snapshot: snap,
                          error: root["error"] as? Bool ?? false, retryAfter: retry)
    }

    static func isFresh(_ c: CacheEntry, now: Date) -> Bool {
        if let r = c.retryAfter, now < r { return true }
        let ttl = c.error ? failureTTL : self.ttl
        return now.timeIntervalSince(c.timestamp) < ttl
    }

    static func writeCache(snapshot: UsageSnapshot?, error: Bool, retryAfter: Date?, now: Date) {
        let iso = ISO8601DateFormatter()
        var root: [String: Any] = [
            "timestamp": Int(now.timeIntervalSince1970 * 1000),
            "error": error,
            "source": "app",
        ]
        if let s = snapshot {
            var d: [String: Any] = [:]
            d["fiveHourPercent"] = s.fiveHourPercent ?? NSNull()
            d["weeklyPercent"] = s.weeklyPercent ?? NSNull()
            d["fiveHourResetsAt"] = s.fiveHourResetsAt.map { iso.string(from: $0) } ?? NSNull()
            d["weeklyResetsAt"] = s.weeklyResetsAt.map { iso.string(from: $0) } ?? NSNull()
            d["models"] = s.modelLimits.map { m -> [String: Any] in
                ["model": m.model, "percent": m.percent,
                 "resetsAt": m.resetsAt.map { iso.string(from: $0) } ?? NSNull()]
            }
            root["data"] = d
        } else {
            root["data"] = NSNull()
        }
        if let r = retryAfter { root["retryAfter"] = Int(r.timeIntervalSince1970 * 1000) }
        JSONFile.writeObject(root, to: Paths.usageCache, pretty: false)
    }

    // MARK: - Credentials (read-only)

    struct Credentials {
        let token: String
        let expiresAt: Date?
        /// "max", "pro", "team"… as stored by Claude Code (may be absent).
        let subscriptionType: String?
    }

    /// Display name of the user's plan ("Max", "Pro"), if Claude Code stored it.
    private(set) var plan: String?
    private var planChecked = false

    /// Reads Claude Code's OAuth credentials from the login keychain, then
    /// from ~/.claude/.credentials.json. Never writes either.
    static func readCredentials() -> Credentials? {
        // The keychain can hold more than one "Claude Code-credentials"
        // item (an older one without an account, a current one under the
        // user's account). Without -a, `security` returns whichever it finds
        // first, which may be stale. Prefer the user's account and any
        // unexpired token, like runtime/lib/usage.mjs does.
        var expired: Credentials?
        for account in [NSUserName(), nil] as [String?] {
            guard let raw = KeychainReader.genericPassword(service: "Claude Code-credentials", account: account),
                  let c = parseCredentialBlob(raw) else { continue }
            if let exp = c.expiresAt, exp <= Date() {
                if expired == nil { expired = c }
                continue
            }
            return c
        }
        if let c = expired { return c }
        if let data = JSONFile.read(Paths.claudeDir + "/.credentials.json"),
           let raw = String(data: data, encoding: .utf8) {
            return parseCredentialBlob(raw)
        }
        return nil
    }

    static func planName(_ raw: String) -> String? {
        let t = raw.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        return t.prefix(1).uppercased() + t.dropFirst().lowercased()
    }

    static func parseCredentialBlob(_ raw: String) -> Credentials? {
        guard let data = raw.data(using: .utf8),
              let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
        let oauth = (root["claudeAiOauth"] as? [String: Any]) ?? root
        guard let token = oauth["accessToken"] as? String, !token.isEmpty else { return nil }
        let exp = (oauth["expiresAt"] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) }
        return Credentials(token: token, expiresAt: exp,
                           subscriptionType: oauth["subscriptionType"] as? String)
    }
}

/// Thin wrapper over `/usr/bin/security`, matching how the chat client
/// already reads the token (one "Always Allow" prompt, then silent).
enum KeychainReader {
    static func genericPassword(service: String, account: String? = nil) -> String? {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        var args = ["find-generic-password", "-s", service]
        if let account = account, !account.isEmpty { args += ["-a", account] }
        proc.arguments = args + ["-w"]
        let out = Pipe()
        proc.standardOutput = out
        proc.standardError = Pipe()
        do { try proc.run() } catch { return nil }
        let data = out.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return nil }
        let s = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? nil : s
    }
}
