import Foundation
import Observation

@Observable
public final class QuranAudioDownloadService: NSObject, URLSessionDownloadDelegate {
    public static let shared = QuranAudioDownloadService()

    public enum DownloadStatus: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case downloaded(sizeBytes: Int64)
    }

    public var downloadProgress: [String: Double] = [:] // key: "{reciterId}_{surahId}"
    public var activeDownloads: Set<String> = []

    private var urlSession: URLSession!
    private var taskToSurahKey: [Int: (reciterId: String, surahId: Int, ayah: Int, totalAyahs: Int)] = [:]

    private let cacheDirectoryName = "BayanAudioOfflineCache"

    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "tools.rea.Bayan.AudioDownloader")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }

    private var baseCacheURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent(cacheDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public func localAudioUrl(reciterId: String, surah: Int, ayah: Int) -> URL? {
        let filename = String(format: "%@_%03d%03d.mp3", reciterId, surah, ayah)
        let fileURL = baseCacheURL.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }

    public func isSurahDownloaded(reciterId: String, surah: Surah) -> Bool {
        for ayah in 1...surah.totalAyahs {
            if localAudioUrl(reciterId: reciterId, surah: surah.id, ayah: ayah) == nil {
                return false
            }
        }
        return true
    }

    public func downloadStatus(reciterId: String, surah: Surah) -> DownloadStatus {
        let key = "\(reciterId)_\(surah.id)"
        if let progress = downloadProgress[key], activeDownloads.contains(key) {
            return .downloading(progress: progress)
        }
        if isSurahDownloaded(reciterId: reciterId, surah: surah) {
            let size = surahTotalDownloadedSize(reciterId: reciterId, surah: surah)
            return .downloaded(sizeBytes: size)
        }
        return .notDownloaded
    }

    public func downloadSurah(_ surah: Surah, reciter: Reciter) {
        let key = "\(reciter.id)_\(surah.id)"
        guard !activeDownloads.contains(key) else { return }

        activeDownloads.insert(key)
        downloadProgress[key] = 0.05

        // Sequential or parallel download of all Ayahs in Surah
        for ayah in 1...surah.totalAyahs {
            if localAudioUrl(reciterId: reciter.id, surah: surah.id, ayah: ayah) != nil {
                continue
            }
            if let remoteUrl = reciter.audioUrl(surah: surah.id, ayah: ayah) {
                let task = urlSession.downloadTask(with: remoteUrl)
                taskToSurahKey[task.taskIdentifier] = (reciter.id, surah.id, ayah, surah.totalAyahs)
                task.resume()
            }
        }
    }

    public func deleteDownloadedSurah(_ surah: Surah, reciterId: String) {
        let key = "\(reciterId)_\(surah.id)"
        activeDownloads.remove(key)
        downloadProgress.removeValue(forKey: key)

        for ayah in 1...surah.totalAyahs {
            let filename = String(format: "%@_%03d%03d.mp3", reciterId, surah.id, ayah)
            let fileURL = baseCacheURL.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    public func totalAudioStorageSize() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(at: baseCacheURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for file in files {
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    public func formattedStorageSize() -> String {
        let bytes = totalAudioStorageSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func surahTotalDownloadedSize(reciterId: String, surah: Surah) -> Int64 {
        var total: Int64 = 0
        for ayah in 1...surah.totalAyahs {
            if let url = localAudioUrl(reciterId: reciterId, surah: surah.id, ayah: ayah),
               let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    // MARK: - URLSessionDownloadDelegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let info = taskToSurahKey[downloadTask.taskIdentifier] else { return }
        taskToSurahKey.removeValue(forKey: downloadTask.taskIdentifier)

        let targetFilename = String(format: "%@_%03d%03d.mp3", info.reciterId, info.surahId, info.ayah)
        let destination = baseCacheURL.appendingPathComponent(targetFilename)

        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            print("⚠️ Failed to store downloaded audio: \(error)")
        }

        // Check overall surah progress
        let key = "\(info.reciterId)_\(info.surahId)"
        var downloadedAyahs = 0
        for a in 1...info.totalAyahs {
            if localAudioUrl(reciterId: info.reciterId, surah: info.surahId, ayah: a) != nil {
                downloadedAyahs += 1
            }
        }

        let progress = Double(downloadedAyahs) / Double(max(1, info.totalAyahs))
        downloadProgress[key] = progress

        if downloadedAyahs >= info.totalAyahs {
            activeDownloads.remove(key)
            downloadProgress.removeValue(forKey: key)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let err = error {
            print("⚠️ Audio download task failed: \(err)")
        }
    }

    // MARK: - Cache Storage Diagnostics & Cleanup
    public func totalCacheSizeBytes() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(at: baseCacheURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        var total: Int64 = 0
        for file in files {
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    public func clearAllAudioCache() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: baseCacheURL, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
        activeDownloads.removeAll()
        downloadProgress.removeAll()
    }
}
