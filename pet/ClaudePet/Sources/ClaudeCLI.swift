import Cocoa

// ============================================================================
// MARK: - Process runner
// ============================================================================

/// Runs the official Claude Code CLI. Clawd never touches Claude Code's login
/// (Anthropic's terms reserve it for Claude Code and Claude.ai); everything
/// here goes through `claude` itself, started only when the user asks.
enum ClaudeCLI {
    struct Output {
        var status: Int32
        var stdout: String
        var stderr: String
        var timedOut: Bool
    }

    /// Blocking. Call off the main thread. Stdout and stderr are drained while
    /// the process runs, so large output (stream-json) cannot fill the pipe.
    static func run(_ arguments: [String], timeout: TimeInterval,
                    workingDirectory: String? = nil) -> Output? {
        guard let path = ClawdChat.resolveClaudePath() else { return nil }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = arguments
        task.environment = ClawdChat.cliEnvironment(claudePath: path)
        if let dir = workingDirectory {
            task.currentDirectoryURL = URL(fileURLWithPath: dir)
        }
        let out = Pipe(), err = Pipe()
        task.standardInput = FileHandle.nullDevice
        task.standardOutput = out
        task.standardError = err

        var outData = Data(), errData = Data()
        let group = DispatchGroup()
        for (pipe, isOut) in [(out, true), (err, false)] {
            group.enter()
            DispatchQueue.global(qos: .utility).async {
                let d = pipe.fileHandleForReading.readDataToEndOfFile()
                if isOut { outData = d } else { errData = d }
                group.leave()
            }
        }

        do { try task.run() } catch { return nil }

        var timedOut = false
        let deadline = Date().addingTimeInterval(timeout)
        while task.isRunning {
            if Date() > deadline {
                timedOut = true
                task.terminate()
                break
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        task.waitUntilExit()
        _ = group.wait(timeout: .now() + 2)
        return Output(status: task.terminationStatus,
                      stdout: String(data: outData, encoding: .utf8) ?? "",
                      stderr: String(data: errData, encoding: .utf8) ?? "",
                      timedOut: timedOut)
    }

    static func looksLikeLoginError(_ text: String) -> Bool {
        let t = text.lowercased()
        return t.contains("not logged in") || t.contains("/login")
            || t.contains("invalid api key") || t.contains("oauth token")
            || t.contains("authentication")
    }
}

// ============================================================================
// MARK: - Login state
// ============================================================================

enum ClaudeAuthState: Equatable {
    case unknown
    case cliMissing
    case loggedIn
    case loggedOut
    /// The login Terminal window is open; waiting for the browser sign-in.
    case loggingIn
}

/// `claude auth status` / `claude auth login`, the official commands.
enum ClaudeAuth {
    /// `claude auth` exists in every recent Claude Code. On a much older one
    /// "auth status" would be taken as a prompt, so it is never run there.
    static let minimumVersion = [2, 1, 120]
    private static var versionOK: Bool?

    static func supportsAuthCommands() -> Bool? {
        if let ok = versionOK { return ok }
        guard let out = ClaudeCLI.run(["--version"], timeout: 15), out.status == 0 else { return nil }
        guard let v = parseVersion(out.stdout) else { return nil }
        let ok = v.lexicographicallyPrecedes(minimumVersion) == false
        versionOK = ok
        return ok
    }

    /// "2.1.191 (Claude Code)" -> [2, 1, 191]
    static func parseVersion(_ text: String) -> [Int]? {
        guard let token = text.split(whereSeparator: { $0 == " " || $0 == "\n" }).first else { return nil }
        let parts = token.split(separator: ".").compactMap { Int($0) }
        return parts.count >= 3 ? Array(parts.prefix(3)) : nil
    }

    /// Exit 0 = logged in, 1 = not logged in. Blocking; call off main.
    static func checkStatus() -> ClaudeAuthState {
        guard ClawdChat.resolveClaudePath() != nil else { return .cliMissing }
        guard supportsAuthCommands() == true else { return .unknown }
        guard let out = ClaudeCLI.run(["auth", "status"], timeout: 15) else { return .cliMissing }
        if out.timedOut { return .unknown }
        if out.status == 0 { return .loggedIn }
        if out.status == 1 { return .loggedOut }
        return .unknown
    }

    static let loginScriptPath = NSHomeDirectory() + "/.claude/pet/claude-login.command"

    /// Opens Terminal running `claude auth login`. Claude Code opens the
    /// browser itself, so the user only signs in on the web. A real terminal
    /// is used because the login may ask for a pasted code when the browser
    /// cannot reach back, which needs a TTY.
    static func openLoginTerminal() -> Bool {
        guard let claude = ClawdChat.resolveClaudePath(),
              supportsAuthCommands() != false else { return false }
        let env = ClawdChat.cliEnvironment(claudePath: claude)
        let script = """
        #!/bin/bash
        export PATH=\(shellQuote(env["PATH"] ?? "/usr/bin:/bin"))
        clear
        echo "Claude Code 로그인"
        echo "브라우저가 열리면 Claude 계정으로 로그인해 주세요."
        echo
        \(shellQuote(claude)) auth login
        status=$?
        echo
        if [ $status -eq 0 ]; then
          echo "로그인이 끝났어요. 이 창은 닫아도 돼요."
        else
          echo "로그인이 끝나지 않았어요. Clawd 팝오버에서 다시 시도할 수 있어요."
        fi
        """
        Paths.ensurePetDir()
        do {
            try script.write(toFile: loginScriptPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700],
                                                  ofItemAtPath: loginScriptPath)
        } catch {
            return false
        }
        return NSWorkspace.shared.open(URL(fileURLWithPath: loginScriptPath))
    }

    private static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

/// Keeps the login state current: at launch, every 10 minutes, after a
/// chat login error, and every 3 seconds while a login is in progress.
final class ClaudeAuthMonitor {
    private(set) var state: ClaudeAuthState = .unknown
    var onChange: ((ClaudeAuthState) -> Void)?

    private var timer: Timer?
    private var loginPoll: Timer?
    private var loginDeadline = Date.distantPast
    private var checking = false

    func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.check()
        }
        check()
    }

    func check() {
        guard !checking else { return }
        checking = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let result = ClaudeAuth.checkStatus()
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.checking = false
                // While logging in, only success ends the waiting state.
                if self.state == .loggingIn, result != .loggedIn,
                   Date() < self.loginDeadline { return }
                if result == .loggedIn { self.stopLoginPoll() }
                self.set(result == .unknown && self.state != .loggingIn ? self.state : result)
            }
        }
    }

    /// Opens the login Terminal and waits up to 5 minutes for it to finish.
    @discardableResult
    func beginLogin() -> Bool {
        guard ClaudeAuth.openLoginTerminal() else { return false }
        loginDeadline = Date().addingTimeInterval(300)
        set(.loggingIn)
        loginPoll?.invalidate()
        loginPoll = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Date() >= self.loginDeadline {
                self.stopLoginPoll()
                self.set(.loggedOut)
                self.check()
                return
            }
            self.check()
        }
        return true
    }

    func cancelLogin() {
        stopLoginPoll()
        set(.loggedOut)
        check()
    }

    private func stopLoginPoll() {
        loginPoll?.invalidate()
        loginPoll = nil
        loginDeadline = .distantPast
    }

    private func set(_ s: ClaudeAuthState) {
        guard s != state else { return }
        state = s
        onChange?(s)
    }
}

// ============================================================================
// MARK: - Usage refresh
// ============================================================================

enum UsageRefreshError: Error, Equatable {
    case cliMissing
    case notLoggedIn
    /// Claude Code answered but sent no subscription usage (API key, or a
    /// plan without these limits).
    case noData
    case failed(String)

    var message: String {
        switch self {
        case .cliMissing:  return "Claude Code가 없어서 새로고침할 수 없어요"
        case .notLoggedIn: return "Claude Code 로그인이 필요해요"
        case .noData:      return "이 계정은 사용량 정보를 받을 수 없어요 (Pro, Max 전용)"
        case .failed(let m): return m
        }
    }
}

/// On request, asks Claude Code for the current usage: one tiny Haiku
/// message through `claude -p`, whose stream-json output carries a
/// `rate_limit_event` with both windows. Costs a sliver of usage, so it
/// only runs when the user presses refresh, never on a timer.
enum UsageRefresher {
    private static let lock = NSLock()
    private static var running = false

    static func refresh(completion: @escaping (Result<Void, UsageRefreshError>) -> Void) {
        lock.lock()
        if running { lock.unlock(); return }
        running = true
        lock.unlock()

        DispatchQueue.global(qos: .userInitiated).async {
            let result = runOnce()
            lock.lock(); running = false; lock.unlock()
            DispatchQueue.main.async { completion(result) }
        }
    }

    private static func runOnce() -> Result<Void, UsageRefreshError> {
        Paths.ensurePetDir()
        guard let out = ClaudeCLI.run(
            ["-p", "--model", ClawdChat.modelId,
             "--output-format", "stream-json", "--verbose",
             "Reply with just: ok"],
            timeout: 60,
            workingDirectory: NSHomeDirectory() + "/.claude/pet"
        ) else { return .failure(.cliMissing) }

        if let info = parseRateLimit(out.stdout) {
            return writeCache(info) ? .success(()) : .failure(.failed("사용량을 저장하지 못했어요"))
        }
        if out.timedOut { return .failure(.failed("Claude Code 응답이 없어요. 잠시 후 다시 눌러 주세요")) }
        if ClaudeCLI.looksLikeLoginError(out.stdout + out.stderr) { return .failure(.notLoggedIn) }
        if out.status != 0 {
            let detail = out.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            return .failure(.failed(detail.isEmpty ? "새로고침에 실패했어요" : String(detail.prefix(120))))
        }
        return .failure(.noData)
    }

    struct Window: Equatable {
        var percent: Double
        var resetsAt: Date?
    }

    struct Info: Equatable {
        var fiveHour: Window?
        var sevenDay: Window?
    }

    /// Finds the last `rate_limit_event` line. `utilization` is 0...1.
    static func parseRateLimit(_ stdout: String) -> Info? {
        var found: Info?
        for line in stdout.split(separator: "\n") where line.contains("rate_limit_event") {
            guard let data = line.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  obj["type"] as? String == "rate_limit_event",
                  let info = obj["rate_limit_info"] as? [String: Any] else { continue }
            let windows = info["unifiedWindows"] as? [String: Any] ?? [:]
            func window(_ key: String) -> Window? {
                guard let w = windows[key] as? [String: Any],
                      let u = (w["utilization"] as? NSNumber)?.doubleValue else { return nil }
                let reset = (w["resetsAt"] as? NSNumber).map {
                    Date(timeIntervalSince1970: $0.doubleValue)
                }
                return Window(percent: max(0, min(100, u * 100)), resetsAt: reset)
            }
            let parsed = Info(fiveHour: window("five_hour"), sevenDay: window("seven_day"))
            if parsed.fiveHour != nil || parsed.sevenDay != nil { found = parsed }
        }
        return found
    }

    /// Same shape the HUD writes (runtime/lib/usage.mjs), source "cli".
    private static func writeCache(_ info: Info) -> Bool {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let prev = (JSONFile.readObject(Paths.usageCache)?["data"] as? [String: Any]) ?? [:]
        let now = Date()

        var data: [String: Any] = ["models": []]
        func keep(_ pctKey: String, _ resetKey: String) {
            // A window missing from this answer keeps its old value until it resets.
            guard let p = prev[pctKey], let r = prev[resetKey] as? String,
                  let d = UsageService.parseDate(r), d > now else { return }
            data[pctKey] = p
            data[resetKey] = r
        }
        if let w = info.fiveHour {
            data["fiveHourPercent"] = w.percent
            if let r = w.resetsAt { data["fiveHourResetsAt"] = iso.string(from: r) }
        } else { keep("fiveHourPercent", "fiveHourResetsAt") }
        if let w = info.sevenDay {
            data["weeklyPercent"] = w.percent
            if let r = w.resetsAt { data["weeklyResetsAt"] = iso.string(from: r) }
        } else { keep("weeklyPercent", "weeklyResetsAt") }

        let root: [String: Any] = [
            "timestamp": Int(now.timeIntervalSince1970 * 1000),
            "data": data,
            "error": false,
            "source": "cli",
        ]
        return JSONFile.writeObject(root, to: Paths.usageCache, pretty: false)
    }
}
