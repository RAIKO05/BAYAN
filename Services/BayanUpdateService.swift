import SwiftUI
import Foundation

// MARK: - GitHub Release API Models
public struct GitHubReleaseResponse: Decodable, Sendable {
    public let tagName: String
    public let name: String?
    public let body: String?
    public let htmlUrl: String
    public let publishedAt: String?
    public let assets: [GitHubReleaseAssetResponse]?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
        case assets
    }
}

public struct GitHubReleaseAssetResponse: Decodable, Sendable {
    public let name: String
    public let size: Int?
    public let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case name
        case size
        case browserDownloadUrl = "browser_download_url"
    }
}

// MARK: - Bayan Update Service
/// Continuously monitors GitHub Releases (https://api.github.com/repos/RAIKO05/BAYAN/releases/latest)
/// to detect newly published builds and allow 1-tap direct IPA downloads.
@Observable
public final class BayanUpdateService: @unchecked Sendable {
    public static let shared = BayanUpdateService()

    // State
    public var isChecking: Bool = false
    public var isUpdateAvailable: Bool = false
    public var latestVersion: String = ""
    public var latestBuild: Int = 0
    public var releaseTitle: String = ""
    public var releaseNotes: String = ""
    public var publishedDateString: String = ""
    public var downloadUrl: URL? = nil
    public var releasePageUrl: URL? = URL(string: "https://github.com/RAIKO05/BAYAN/releases/latest")
    public var lastCheckedDate: Date? = nil
    public var errorMessage: String? = nil
    public var hasDismissedNotice: Bool = false
    public var showingUpdateSheet: Bool = false

    private let githubApiUrl = URL(string: "https://api.github.com/repos/RAIKO05/BAYAN/releases/latest")!

    // Dynamic Installed Version & Build
    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.81"
    }

    public var currentBuild: Int {
        if let buildStr = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
           let buildInt = Int(buildStr) {
            return buildInt
        }
        // Fallback: extract last component from CFBundleShortVersionString (e.g. 1.1.81 -> 81)
        let parts = currentVersion.split(separator: ".")
        if parts.count >= 3, let last = Int(parts[2]) {
            return last
        }
        return 81
    }

    private init() {
        // Initial silent check
        Task {
            await checkForUpdates(silent: true)
        }
    }

    // MARK: - Check for Updates
    @MainActor
    public func checkForUpdates(silent: Bool = false) async {
        guard !isChecking else { return }
        isChecking = true
        errorMessage = nil

        do {
            var request = URLRequest(url: githubApiUrl)
            request.httpMethod = "GET"
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.setValue("Bayan-iOS-Companion", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 12

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw NSError(domain: "BayanUpdate", code: status, userInfo: [NSLocalizedDescriptionKey: "GitHub returned status code \(status)"])
            }

            let release = try JSONDecoder().decode(GitHubReleaseResponse.self, from: data)

            // Extract Version & Build
            // tag_name is usually "v1.1.80" or "v1.1.81"
            let tagClean = release.tagName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "v", with: "")
            self.latestVersion = tagClean
            self.releaseTitle = release.name ?? "Bayan v\(tagClean)"
            self.releaseNotes = release.body ?? ""
            self.releasePageUrl = URL(string: release.htmlUrl)

            // Parse remote build number (e.g. "1.1.81" -> 81)
            let tagParts = tagClean.split(separator: ".")
            var remoteBuild = 0
            if tagParts.count >= 3, let b = Int(tagParts[2]) {
                remoteBuild = b
            } else if let b = Int(tagClean) {
                remoteBuild = b
            }
            self.latestBuild = remoteBuild

            // Locate direct IPA asset
            if let assets = release.assets {
                // Priority 1: Versioned IPA (e.g. Bayan_v1.1.81.ipa)
                if let versionedIpa = assets.first(where: { $0.name.hasPrefix("Bayan_v") && $0.name.hasSuffix(".ipa") }) {
                    self.downloadUrl = URL(string: versionedIpa.browserDownloadUrl)
                }
                // Priority 2: Generic Bayan.ipa
                else if let genericIpa = assets.first(where: { $0.name.lowercased() == "bayan.ipa" }) {
                    self.downloadUrl = URL(string: genericIpa.browserDownloadUrl)
                }
                // Priority 3: Any IPA file
                else if let anyIpa = assets.first(where: { $0.name.hasSuffix(".ipa") }) {
                    self.downloadUrl = URL(string: anyIpa.browserDownloadUrl)
                }
            }

            if self.downloadUrl == nil {
                self.downloadUrl = self.releasePageUrl
            }

            // Compare version / build numbers
            let isNewerBuild = remoteBuild > self.currentBuild
            let isNewerSemantic = self.compareVersions(remote: tagClean, local: self.currentVersion) > 0

            self.isUpdateAvailable = isNewerBuild || isNewerSemantic
            self.lastCheckedDate = Date()
            self.isChecking = false

        } catch {
            self.isChecking = false
            self.errorMessage = error.localizedDescription
            self.lastCheckedDate = Date()
            #if DEBUG
            print("[BayanUpdateService] Check failed: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Version Semantic Comparison
    private func compareVersions(remote: String, local: String) -> Int {
        let v1 = remote.split(separator: ".").compactMap { Int($0) }
        let v2 = local.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(v1.count, v2.count) {
            let p1 = i < v1.count ? v1[i] : 0
            let p2 = i < v2.count ? v2[i] : 0
            if p1 > p2 { return 1 }
            if p1 < p2 { return -1 }
        }
        return 0
    }

    // MARK: - Actions
    @MainActor
    public func openDownload() {
        if let url = downloadUrl {
            UIApplication.shared.open(url)
        } else if let releaseUrl = releasePageUrl {
            UIApplication.shared.open(releaseUrl)
        }
    }

    @MainActor
    public func openReleasePage() {
        if let releaseUrl = releasePageUrl {
            UIApplication.shared.open(releaseUrl)
        }
    }

    public func dismissNotice() {
        hasDismissedNotice = true
    }
}
