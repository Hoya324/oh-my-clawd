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
                let dmgURL = assets
                    .first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true })
                    .flatMap { $0["browser_download_url"] as? String } ?? ""
                completion(.available(remoteVersion, dmgURL))
            } else {
                completion(.upToDate(local))
            }
        }
        task.resume()
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
                            try installFromDMG(path: dmgPath)
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
        var errorDescription: String? {
            switch self {
            case .badURL: return "잘못된 다운로드 주소"
            case .mountFailed(let m): return "DMG 마운트 실패: \(m)"
            case .copyFailed(let m): return "설치 실패: \(m)"
            case .appNotFound: return "DMG에서 앱을 찾지 못했어요"
            }
        }
    }

    private static func installFromDMG(path: String) throws {
        let mountPoint = "/tmp/OhMyClawd-mount-\(UUID().uuidString.prefix(8))"
        try FileManager.default.createDirectory(
            atPath: mountPoint, withIntermediateDirectories: true
        )

        let attach = Process()
        attach.launchPath = "/usr/bin/hdiutil"
        attach.arguments = ["attach", path, "-nobrowse", "-mountpoint", mountPoint]
        let attachErr = Pipe()
        attach.standardError = attachErr
        attach.standardOutput = Pipe()
        try attach.run()
        attach.waitUntilExit()
        guard attach.terminationStatus == 0 else {
            let msg = String(
                data: attachErr.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            throw InstallError.mountFailed(msg.prefix(200).description)
        }
        defer {
            let detach = Process()
            detach.launchPath = "/usr/bin/hdiutil"
            detach.arguments = ["detach", mountPoint, "-force"]
            detach.standardOutput = Pipe()
            detach.standardError = Pipe()
            _ = try? detach.run()
            detach.waitUntilExit()
        }

        let srcApp = mountPoint + "/OhMyClawd.app"
        guard FileManager.default.fileExists(atPath: srcApp) else {
            throw InstallError.appNotFound
        }

        let destApp: String = {
            let bundle = Bundle.main.bundlePath
            if bundle.hasSuffix("OhMyClawd.app") { return bundle }
            return NSHomeDirectory() + "/Applications/OhMyClawd.app"
        }()

        try? FileManager.default.removeItem(atPath: destApp)
        try? FileManager.default.createDirectory(
            atPath: (destApp as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true
        )

        let cp = Process()
        cp.launchPath = "/bin/cp"
        cp.arguments = ["-R", srcApp, destApp]
        let cpErr = Pipe()
        cp.standardError = cpErr
        cp.standardOutput = Pipe()
        try cp.run()
        cp.waitUntilExit()
        guard cp.terminationStatus == 0 else {
            let msg = String(
                data: cpErr.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            throw InstallError.copyFailed(msg.prefix(200).description)
        }

        let xattr = Process()
        xattr.launchPath = "/usr/bin/xattr"
        xattr.arguments = ["-cr", destApp]
        xattr.standardOutput = Pipe()
        xattr.standardError = Pipe()
        _ = try? xattr.run()
        xattr.waitUntilExit()
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
