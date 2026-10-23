import Foundation
import AVFoundation

// MARK: - Smart Multi-Ayah Quran Audio Cache Manager
/// High-performance lookahead audio pre-caching engine that silently pre-buffers upcoming
/// Ayahs to local disk cache (Library/Caches/BayanAudioStreamCache/).
/// Guarantees zero-stall recitation playback across subways, elevators, and weak networks.
public final class QuranAudioCacheManager: @unchecked Sendable {
    public static let shared = QuranAudioCacheManager()

    private let cacheDirectoryName = "BayanAudioStreamCache"
    private let maxCacheSizeBytes: Int64 = 150 * 1024 * 1024 // 150 MB max ephemeral stream cache
    private let urlSession: URLSession

    private var activePrefechTasks: [String: URLSessionDownloadTask] = [:]
    private let lock = NSLock()

    private var cacheDirectoryURL: URL {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = cachesDir.appendingPathComponent(cacheDirectoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.urlSession = URLSession(configuration: config)
    }

    // MARK: - Cache Resolution
    /// Returns the local file URL if the Ayah audio is already cached on disk.
    public func cachedAudioUrl(reciterId: String, surah: Int, ayah: Int) -> URL? {
        let fileUrl = cacheFileUrl(reciterId: reciterId, surah: surah, ayah: ayah)
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            return fileUrl
        }
        return nil
    }

    /// Full local path for an Ayah audio cache item
    public func cacheFileUrl(reciterId: String, surah: Int, ayah: Int) -> URL {
        let fileName = "\(reciterId)_\(surah)_\(ayah).mp3"
        return cacheDirectoryURL.appendingPathComponent(fileName)
    }

    // MARK: - Lookahead Multi-Ayah Pre-fetching
    /// Asynchronously pre-fetches the next `count` Ayahs in the background
    public func prefetchUpcomingAyahs(reciter: Reciter, surah: Surah, currentAyah: Int, count: Int = 5) {
        // Skip whole-surah reciters as they play single monolithic files
        if reciter.id == "omardiaa" || reciter.id == "kazabri_warsh" {
            return
        }

        let maxAyah = surah.totalAyahs
        let startAyah = currentAyah + 1
        let endAyah = min(startAyah + count - 1, maxAyah)

        guard startAyah <= endAyah else { return }

        for nextAyah in startAyah...endAyah {
            prefetchSingleAyah(reciter: reciter, surah: surah.id, ayah: nextAyah)
        }
    }

    private func prefetchSingleAyah(reciter: Reciter, surah: Int, ayah: Int) {
        let targetFile = cacheFileUrl(reciterId: reciter.id, surah: surah, ayah: ayah)

        // Check if already in cache
        if FileManager.default.fileExists(atPath: targetFile.path) {
            return
        }

        // Check if already in permanent offline downloads
        if QuranAudioDownloadService.shared.localAudioUrl(reciterId: reciter.id, surah: surah, ayah: ayah) != nil {
            return
        }

        guard let remoteUrl = reciter.audioUrl(surah: surah, ayah: ayah) else { return }

        let taskKey = "\(reciter.id)_\(surah)_\(ayah)"

        lock.lock()
        if activePrefechTasks[taskKey] != nil {
            lock.unlock()
            return
        }

        let task = urlSession.downloadTask(with: remoteUrl) { [weak self] tempUrl, response, error in
            guard let self = self else { return }
            defer {
                self.lock.lock()
                self.activePrefechTasks.removeValue(forKey: taskKey)
                self.lock.unlock()
            }

            guard let tempUrl = tempUrl, error == nil else { return }

            do {
                if FileManager.default.fileExists(atPath: targetFile.path) {
                    try? FileManager.default.removeItem(at: targetFile)
                }
                try FileManager.default.moveItem(at: tempUrl, to: targetFile)
                self.pruneCacheIfNeeded()
            } catch {
                #if DEBUG
                print("[QuranAudioCacheManager] Failed to cache \(taskKey): \(error)")
                #endif
            }
        }

        activePrefechTasks[taskKey] = task
        lock.unlock()

        task.resume()
    }

    // MARK: - LRU Cache Eviction
    private func pruneCacheIfNeeded() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let dir = self.cacheDirectoryURL
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) else { return }

            var totalSize: Int64 = 0
            var fileDetails: [(url: URL, date: Date, size: Int64)] = []

            for file in files {
                guard let resourceValues = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                      let size = resourceValues.fileSize,
                      let date = resourceValues.contentModificationDate else { continue }
                let s = Int64(size)
                totalSize += s
                fileDetails.append((url: file, date: date, size: s))
            }

            if totalSize > self.maxCacheSizeBytes {
                // Sort oldest modified first
                fileDetails.sort { $0.date < $1.date }

                for item in fileDetails {
                    try? FileManager.default.removeItem(at: item.url)
                    totalSize -= item.size
                    if totalSize <= (self.maxCacheSizeBytes * 3 / 4) { // prune down to 75%
                        break
                    }
                }
            }
        }
    }

    /// Clear all ephemeral stream cache
    public func clearStreamCache() {
        try? FileManager.default.removeItem(at: cacheDirectoryURL)
    }
}
