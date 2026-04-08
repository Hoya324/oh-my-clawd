import Foundation

enum UpdateStatus: Equatable {
    case idle
    case checking
    case upToDate(String)       // current version
    case available(String)      // new version tag
    case failed
}

struct UpdateChecker {
    static let repoOwner = "Hoya324"
    static let repoName = "oh-my-clawd"
    static let releasesURL = "https://api.github.com/repos/Hoya324/oh-my-clawd/releases/latest"
    static let releasePageURL = "https://github.com/Hoya324/oh-my-clawd/releases/latest"

    static var currentVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    static func check(completion: @escaping (UpdateStatus) -> Void) {
        guard let url = URL(string: releasesURL) else {
            completion(.failed)
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                completion(.failed)
                return
            }

            let remoteVersion = tagName.hasPrefix("v")
                ? String(tagName.dropFirst())
                : tagName

            guard let local = currentVersion else {
                completion(.available(remoteVersion))
                return
            }

            if compareVersions(remoteVersion, isNewerThan: local) {
                completion(.available(remoteVersion))
            } else {
                completion(.upToDate(local))
            }
        }
        task.resume()
    }

    /// Compare two semver strings. Returns `true` when `lhs` is strictly newer than `rhs`.
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
