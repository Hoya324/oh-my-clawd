import Foundation

/// Refreshes Claude Code's expired OAuth token so usage keeps updating for
/// people who rarely open Claude Code (claude.ai / desktop app users).
///
/// Why this is careful: the refresh token can rotate. Refreshing without
/// saving the result (what the old HUD did) leaves Claude Code holding a
/// dead refresh token and signs the user out. So this:
///
///  1. only runs when the access token is already expired,
///  2. only runs when no Claude Code process is running (Claude Code
///     refreshes for itself while it runs; two refreshers could race),
///  3. writes the new tokens back to the same keychain item, the same way
///     Claude Code does (`security add-generic-password -U -a <user> -X`),
///     keeping every other field of the stored JSON as it was,
///  4. re-reads the item right before writing and gives up if anything
///     changed in between (someone else refreshed first),
///  5. backs off after a failure, and can be turned off:
///     `defaults write com.hoya324.oh-my-clawd autoRefreshToken -bool false`
final class CredentialRefresher {
    static let service = "Claude Code-credentials"
    static let tokenURL = URL(string: "https://platform.claude.com/v1/oauth/token")!
    static let clientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    static let defaultsKey = "autoRefreshToken"

    private let lock = NSLock()
    private var lastAttempt: Date?
    private var failureBackoffUntil: Date?
    private static let minInterval: TimeInterval = 10 * 60
    private static let failureBackoff: TimeInterval = 60 * 60

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: defaultsKey) as? Bool ?? true
    }

    enum Outcome: Equatable {
        case refreshed(UsageService.Credentials)
        case skipped(String)
        case failed(String)

        static func == (a: Outcome, b: Outcome) -> Bool {
            switch (a, b) {
            case (.refreshed(let x), .refreshed(let y)): return x.token == y.token
            case (.skipped(let x), .skipped(let y)), (.failed(let x), .failed(let y)): return x == y
            default: return false
            }
        }
    }

    /// Blocking; call from a background queue.
    func refreshIfPossible(now: Date = Date()) -> Outcome {
        guard Self.isEnabled else { return .skipped("disabled") }

        lock.lock()
        if let until = failureBackoffUntil, now < until { lock.unlock(); return .skipped("backoff") }
        if let last = lastAttempt, now.timeIntervalSince(last) < Self.minInterval {
            lock.unlock(); return .skipped("too soon")
        }
        lastAttempt = now
        lock.unlock()

        if Self.isClaudeCodeRunning() { return .skipped("claude code running") }

        // Claude Code stores the item under the user's account; only touch
        // that one so we write back exactly where we read from.
        let account = NSUserName()
        guard let originalRaw = KeychainReader.genericPassword(service: Self.service, account: account),
              var root = Self.jsonObject(originalRaw),
              var oauth = root["claudeAiOauth"] as? [String: Any],
              let refreshToken = oauth["refreshToken"] as? String, !refreshToken.isEmpty else {
            return .skipped("no refreshable credentials")
        }
        if let exp = (oauth["expiresAt"] as? NSNumber)?.doubleValue,
           Date(timeIntervalSince1970: exp / 1000) > now {
            return .skipped("not expired")
        }

        guard let tokens = Self.requestRefresh(refreshToken: refreshToken) else {
            backOff(now)
            return .failed("refresh request failed")
        }

        // Compare-and-swap: abort if the item changed while we were away.
        guard KeychainReader.genericPassword(service: Self.service, account: account) == originalRaw else {
            return .skipped("changed concurrently")
        }

        oauth["accessToken"] = tokens.accessToken
        oauth["refreshToken"] = tokens.refreshToken ?? refreshToken
        oauth["expiresAt"] = Int(tokens.expiresAt.timeIntervalSince1970 * 1000)
        root["claudeAiOauth"] = oauth

        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.withoutEscapingSlashes]),
              Self.writeKeychain(account: account, data: data) else {
            backOff(now)
            return .failed("keychain write failed")
        }
        return .refreshed(UsageService.Credentials(
            token: tokens.accessToken,
            expiresAt: tokens.expiresAt,
            subscriptionType: oauth["subscriptionType"] as? String
        ))
    }

    private func backOff(_ now: Date) {
        lock.lock()
        failureBackoffUntil = now.addingTimeInterval(Self.failureBackoff)
        lock.unlock()
    }

    // MARK: - Pieces

    private static func jsonObject(_ raw: String) -> [String: Any]? {
        guard let data = raw.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    /// Any `claude` CLI process (native binary under .../claude/versions/,
    /// a `claude` executable, or node running @anthropic-ai/claude-code).
    static func isClaudeCodeRunning() -> Bool {
        let r = RuntimeInstaller.run("/bin/ps", ["-axo", "args="], timeout: 3)
        guard r.status == 0 else { return true }   // unsure: do not risk a race
        for line in r.output.split(separator: "\n") {
            let args = line.trimmingCharacters(in: .whitespaces)
            if args.contains("/claude/versions/") || args.contains("claude-code/cli") { return true }
            let exe = args.split(separator: " ").first.map(String.init) ?? ""
            if (exe as NSString).lastPathComponent == "claude" { return true }
        }
        return false
    }

    struct Tokens {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date
    }

    private static func requestRefresh(refreshToken: String) -> Tokens? {
        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: clientID),
        ]
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = comps.percentEncodedQuery?.data(using: .utf8)

        let sem = DispatchSemaphore(value: 0)
        var result: Tokens?
        URLSession.shared.dataTask(with: req) { data, response, _ in
            defer { sem.signal() }
            guard (response as? HTTPURLResponse)?.statusCode == 200, let data = data,
                  let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let access = obj["access_token"] as? String, !access.isEmpty else { return }
            let expiresIn = (obj["expires_in"] as? NSNumber)?.doubleValue ?? 3600
            result = Tokens(accessToken: access,
                            refreshToken: obj["refresh_token"] as? String,
                            expiresAt: Date().addingTimeInterval(expiresIn))
        }.resume()
        _ = sem.wait(timeout: .now() + 20)
        return result
    }

    /// Same command Claude Code uses, fed through `security -i` on stdin so
    /// the secret never appears in the process list.
    private static func writeKeychain(account: String, data: Data) -> Bool {
        let hex = data.map { String(format: "%02x", $0) }.joined()
        let quotedAccount = account.replacingOccurrences(of: "\"", with: "")
        let command = "add-generic-password -U -a \"\(quotedAccount)\" -s \"\(service)\" -X \(hex)\n"

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        proc.arguments = ["-i"]
        let input = Pipe()
        proc.standardInput = input
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        do { try proc.run() } catch { return false }
        input.fileHandleForWriting.write(command.data(using: .utf8)!)
        input.fileHandleForWriting.closeFile()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0 else { return false }

        // Verify by reading back.
        let back = KeychainReader.genericPassword(service: service, account: account)
        return back?.data(using: .utf8) == data
    }
}
