import Cocoa
import Foundation

enum UpdateStatus: Equatable {
    case idle
    case checking
    case upToDate(String)                  // current version
    case available(String, String)         // (new version, dmg URL)
    case installing(Double)                // 0.0 - 1.0 progress
    case installed(String)                 // new version, ready to relaunch
    case failed(String)
}

struct UpdateChecker {
    static let repoOwner = "Hoya324"
    static let repoName = "oh-my-clawd"
    static let releasesURL = "https://api.github.com/repos/Hoya324/oh-my-clawd/releases/latest"
    static let releasePageURL = "https://github.com/Hoya324/oh-my-clawd/releases/latest"

    static var currentVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?"
    }

    static func check(completion: @escaping (UpdateStatus) -> Void) {
        guard let url = URL(string: releasesURL) else {
            completion(.failed("bad url"))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                completion(.failed("network"))
                return
            }

            let remoteVersion = tagName.hasPrefix("v")
                ? String(tagName.dropFirst())
                : tagName
            let local = currentVersion

            if compareVersions(remoteVersion, isNewerThan: local) {
                let assets = json["assets"] as? [[String: Any]] ?? []
                let dmg = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true })
                let dmgURL = dmg.flatMap { $0["browser_download_url"] as? String } ?? ""
                // GitHub publishes "sha256:<hex>" per asset; keep it so the
                // installer can verify the download.
                if let digest = dmg?["digest"] as? String, digest.hasPrefix("sha256:") {
                    setDigest(String(digest.dropFirst("sha256:".count)), for: dmgURL)
                }
                completion(.available(remoteVersion, dmgURL))
            } else {
                completion(.upToDate(local))
            }
        }
        task.resume()
    }

    private static let digestLock = NSLock()
    private static var digests: [String: String] = [:]

    static func setDigest(_ hex: String, for url: String) {
        digestLock.lock(); defer { digestLock.unlock() }
        digests[url] = hex.lowercased()
    }

    static func digest(for url: String) -> String? {
        digestLock.lock(); defer { digestLock.unlock() }
        return digests[url]
    }

    private static func compareVersions(_ lhs: String, isNewerThan rhs: String) -> Bool {
        let lhsParts = lhs.split(separator: ".").compactMap { Int($0) }
        let rhsParts = rhs.split(separator: ".").compactMap { Int($0) }
        let count = max(lhsParts.count, rhsParts.count)
        for i in 0..<count {
            let l = i < lhsParts.count ? lhsParts[i] : 0
            let r = i < rhsParts.count ? rhsParts[i] : 0
            if l > r { return true }
            if l < r { return false }
        }
        return false
    }
}

// ============================================================================
// MARK: - Installer
// ============================================================================

final class UpdateInstaller {
    static func installAndRelaunch(
        dmgURL: String,
        version: String,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: dmgURL) else {
            completion(.failure(InstallError.badURL))
            return
        }

        let cacheDir = NSHomeDirectory() + "/Library/Caches/OhMyClawd"
        try? FileManager.default.createDirectory(
            atPath: cacheDir, withIntermediateDirectories: true
        )
        let dmgPath = cacheDir + "/OhMyClawd-\(version).dmg"

        let session = URLSession(
            configuration: .default,
            delegate: DownloadDelegate(
                destPath: dmgPath,
                onProgress: progress,
                onFinish: { err in
                    if let e = err {
                        DispatchQueue.main.async { completion(.failure(e)) }
                        return
                    }
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try installFromDMG(path: dmgPath, expectedSHA256: UpdateChecker.digest(for: dmgURL))
                            DispatchQueue.main.async {
                                relaunch()
                                completion(.success(version))
                            }
                        } catch {
                            DispatchQueue.main.async { completion(.failure(error)) }
                        }
                    }
                }
            ),
            delegateQueue: nil
        )
        session.downloadTask(with: url).resume()
    }

    enum InstallError: LocalizedError {
        case badURL
        case mountFailed(String)
        case copyFailed(String)
        case appNotFound
        case checksumMismatch
        case signatureInvalid(String)
        var errorDescription: String? {
            switch self {
            case .badURL: return "잘못된 다운로드 주소"
            case .mountFailed(let m): return "DMG 마운트 실패: \(m)"
            case .copyFailed(let m): return "설치 실패: \(m)"
            case .appNotFound: return "DMG에서 앱을 찾지 못했어요"
            case .checksumMismatch: return "다운로드 파일이 손상됐어요 (체크섬 불일치)"
            case .signatureInvalid(let m): return "서명 검증 실패: \(m)"
            }
        }
    }

    /// Developer ID team that signs official releases (scripts/build-dmg.sh).
    static let expectedTeamID = "H7825NYH4G"

    @discardableResult
    private static func run(_ path: String, _ args: [String]) -> (status: Int32, output: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return (-1, error.localizedDescription) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }

    static func sha256(ofFile path: String) -> String? {
        let r = run("/usr/bin/shasum", ["-a", "256", path])
        guard r.status == 0 else { return nil }
        return r.output.split(separator: " ").first.map { String($0).lowercased() }
    }

    static func teamIdentifier(ofApp path: String) -> String? {
        let r = run("/usr/bin/codesign", ["-dv", "--verbose=2", path])
        for line in r.output.split(separator: "\n") where line.hasPrefix("TeamIdentifier=") {
            let id = line.dropFirst("TeamIdentifier=".count)
            return id == "not set" ? nil : String(id)
        }
        return nil
    }

    /// The new app must carry a valid Developer ID signature from the same
    /// team, and pass Gatekeeper (notarization). Nothing is stripped from
    /// it (the old installer ran `xattr -cr`, bypassing Gatekeeper).
    static func verifyApp(at path: String) throws {
        let sig = run("/usr/bin/codesign", ["--verify", "--deep", "--strict", path])
        guard sig.status == 0 else {
            throw InstallError.signatureInvalid(String(sig.output.prefix(160)))
        }
        guard teamIdentifier(ofApp: path) == expectedTeamID else {
            throw InstallError.signatureInvalid("다른 개발자 서명")
        }
        let gk = run("/usr/sbin/spctl", ["--assess", "--type", "execute", path])
        guard gk.status == 0 else {
            throw InstallError.signatureInvalid("Gatekeeper 거부: \(gk.output.prefix(120))")
        }
    }

    private static func installFromDMG(path: String, expectedSHA256: String?) throws {
        if let expected = expectedSHA256 {
            guard sha256(ofFile: path) == expected else {
                try? FileManager.default.removeItem(atPath: path)
                throw InstallError.checksumMismatch
            }
        }

        let fm = FileManager.default
        let mountPoint = NSTemporaryDirectory() + "OhMyClawd-mount-\(UUID().uuidString.prefix(8))"
        try fm.createDirectory(atPath: mountPoint, withIntermediateDirectories: true)

        let attach = run("/usr/bin/hdiutil", ["attach", path, "-nobrowse", "-readonly", "-mountpoint", mountPoint])
        guard attach.status == 0 else {
            throw InstallError.mountFailed(String(attach.output.prefix(200)))
        }
        defer {
            run("/usr/bin/hdiutil", ["detach", mountPoint, "-force"])
            try? fm.removeItem(atPath: mountPoint)
        }

        let srcApp = mountPoint + "/OhMyClawd.app"
        guard fm.fileExists(atPath: srcApp) else { throw InstallError.appNotFound }
        try verifyApp(at: srcApp)

        let destApp: String = {
            let bundle = Bundle.main.bundlePath
            if bundle.hasSuffix("OhMyClawd.app") { return bundle }
            return NSHomeDirectory() + "/Applications/OhMyClawd.app"
        }()
        let destDir = (destApp as NSString).deletingLastPathComponent
        try? fm.createDirectory(atPath: destDir, withIntermediateDirectories: true)

        // Copy next to the destination first, verify the copy, then swap.
        // If anything fails the current app is left untouched.
        let staging = destDir + "/.OhMyClawd-update-\(UUID().uuidString.prefix(8)).app"
        let cp = run("/usr/bin/ditto", [srcApp, staging])
        guard cp.status == 0 else {
            try? fm.removeItem(atPath: staging)
            throw InstallError.copyFailed(String(cp.output.prefix(200)))
        }
        do {
            try verifyApp(at: staging)
            if fm.fileExists(atPath: destApp) {
                _ = try fm.replaceItemAt(URL(fileURLWithPath: destApp),
                                         withItemAt: URL(fileURLWithPath: staging))
            } else {
                try fm.moveItem(atPath: staging, toPath: destApp)
            }
        } catch {
            try? fm.removeItem(atPath: staging)
            if error is InstallError { throw error }
            throw InstallError.copyFailed(error.localizedDescription)
        }
    }

    private static func relaunch() {
        let bundlePath: String = {
            let bundle = Bundle.main.bundlePath
            if bundle.hasSuffix("OhMyClawd.app") { return bundle }
            return NSHomeDirectory() + "/Applications/OhMyClawd.app"
        }()
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 1; open \"\(bundlePath)\""]
        _ = try? task.run()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.terminate(nil)
        }
    }

    private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
        let destPath: String
        let onProgress: (Double) -> Void
        let onFinish: (Error?) -> Void

        init(destPath: String,
             onProgress: @escaping (Double) -> Void,
             onFinish: @escaping (Error?) -> Void) {
            self.destPath = destPath
            self.onProgress = onProgress
            self.onFinish = onFinish
        }

        func urlSession(_ session: URLSession,
                        downloadTask: URLSessionDownloadTask,
                        didWriteData bytesWritten: Int64,
                        totalBytesWritten: Int64,
                        totalBytesExpectedToWrite: Int64) {
            guard totalBytesExpectedToWrite > 0 else { return }
            let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            DispatchQueue.main.async { self.onProgress(p) }
        }

        func urlSession(_ session: URLSession,
                        downloadTask: URLSessionDownloadTask,
                        didFinishDownloadingTo location: URL) {
            do {
                try? FileManager.default.removeItem(atPath: destPath)
                try FileManager.default.moveItem(
                    at: location,
                    to: URL(fileURLWithPath: destPath)
                )
                onFinish(nil)
            } catch {
                onFinish(error)
            }
        }

        func urlSession(_ session: URLSession,
                        task: URLSessionTask,
                        didCompleteWithError error: Error?) {
            if let error = error { onFinish(error) }
        }
    }
}
