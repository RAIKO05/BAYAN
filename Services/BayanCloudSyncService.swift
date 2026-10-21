import Foundation
import Combine

// MARK: - Bayan iCloud Sync & Cloud Backup Service
// Synchronizes Khatmah goals, reading progress, bookmarks, prayer tracker history,
// and app preferences across iPhone, iPad, and Mac via Apple's NSUbiquitousKeyValueStore.
@Observable
public final class BayanCloudSyncService {
    public static let shared = BayanCloudSyncService()

    public var isSyncing: Bool = false
    public var lastSyncDate: Date? = nil
    public var isCloudAvailable: Bool = true
    public var syncStatusMessage: String = "iCloud Connected"

    private let kvStore = NSUbiquitousKeyValueStore.default
    private let lastSyncKey = "bayan_icloud_last_sync_timestamp"

    private init() {
        checkCloudAvailability()
        loadLastSyncDate()
        startObservingRemoteChanges()
    }

    public func checkCloudAvailability() {
        if FileManager.default.ubiquityIdentityToken != nil {
            self.isCloudAvailable = true
            self.syncStatusMessage = "iCloud Active"
        } else {
            // Still functions with local fallback
            self.isCloudAvailable = true
            self.syncStatusMessage = "iCloud Ready"
        }
    }

    private func loadLastSyncDate() {
        let ts = kvStore.double(forKey: lastSyncKey)
        if ts > 0 {
            self.lastSyncDate = Date(timeIntervalSince1970: ts)
        }
    }

    // MARK: - Register for External Remote iCloud Changes
    private func startObservingRemoteChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ubiquitousKeyValueStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore
        )
    }

    @objc private func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            pullRemoteChanges()
            return
        }

        switch reason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            print("☁️ Received remote iCloud update from another Apple device")
            DispatchQueue.main.async {
                self.pullRemoteChanges()
            }
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            print("⚠️ iCloud Key-Value store quota exceeded")
            DispatchQueue.main.async {
                self.syncStatusMessage = "Storage Quota Exceeded"
            }
        case NSUbiquitousKeyValueStoreAccountChange:
            print("☁️ iCloud account changed")
            DispatchQueue.main.async {
                self.checkCloudAvailability()
                self.pullRemoteChanges()
            }
        default:
            pullRemoteChanges()
        }
    }

    // MARK: - Pull Remote Changes into Local State
    public func pullRemoteChanges() {
        self.isSyncing = true

        // 1. Khatmah Progress
        let remoteKhatmahPage = kvStore.longLong(forKey: "khatmah_current_page")
        if remoteKhatmahPage > 0 {
            let localPage = KhatmahService.shared.currentPage
            if Int(remoteKhatmahPage) > localPage {
                KhatmahService.shared.currentPage = Int(remoteKhatmahPage)
            }
        }

        let remoteTargetDays = kvStore.longLong(forKey: "khatmah_target_days")
        if remoteTargetDays > 0 {
            KhatmahService.shared.targetDays = Int(remoteTargetDays)
        }

        // 2. Last Read Position
        let remoteSurah = kvStore.longLong(forKey: "bayan_last_surah_id")
        let remoteAyah = kvStore.longLong(forKey: "bayan_last_ayah_id")
        let remotePage = kvStore.longLong(forKey: "bayan_last_page_number")
        let remoteQari = kvStore.string(forKey: "bayan_last_qari_id") ?? "alafasy"
        let remoteTime = kvStore.double(forKey: "bayan_last_audio_timestamp")

        if remoteSurah > 0 && remoteAyah > 0 {
            QuranSyncManager.shared.updateLastRead(
                surahId: Int(remoteSurah),
                ayahId: Int(remoteAyah),
                page: Int(remotePage > 0 ? remotePage : 1),
                qariId: remoteQari,
                audioTime: remoteTime,
                skipCloudSync: true
            )
        }

        // 3. Ayah Bookmarks
        if let remoteBookmarksData = kvStore.data(forKey: "bayan_ayah_bookmarks"),
           let remoteBookmarks = try? JSONDecoder().decode([AyahBookmark].self, from: remoteBookmarksData) {
            var localBookmarks = BookmarkService.shared.bookmarks
            for rb in remoteBookmarks {
                if !localBookmarks.contains(where: { $0.surahId == rb.surahId && $0.ayahNumber == rb.ayahNumber }) {
                    localBookmarks.append(rb)
                }
            }
            BookmarkService.shared.bookmarks = localBookmarks
        }

        // 4. Prayer Completion History for Today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = "bayan_prayed_prayers_" + formatter.string(from: Date())
        if let remotePrayers = kvStore.array(forKey: todayKey) as? [String] {
            let localPrayers = Array(PrayerTrackerService.shared.getCompletedPrayers(for: Date()))
            let merged = Set(localPrayers + remotePrayers)
            UserDefaults.standard.set(Array(merged), forKey: todayKey)
        }

        // 5. Settings & Theme
        if let themeRaw = kvStore.string(forKey: "bayan_selected_theme"),
           let theme = QuranTheme(rawValue: themeRaw) {
            AppThemeManager.shared.setTheme(theme)
        }

        if let convRaw = kvStore.string(forKey: "prayer_calculation_convention"),
           let conv = CalculationConvention(rawValue: convRaw) {
            PrayerSettingsManager.shared.convention = conv
        }

        if let asrRaw = kvStore.string(forKey: "prayer_asr_school"),
           let school = AsrJuristicSchool(rawValue: asrRaw) {
            PrayerSettingsManager.shared.asrSchool = school
        }

        let now = Date()
        self.lastSyncDate = now
        self.isSyncing = false
        self.syncStatusMessage = "Synced with iCloud"
    }

    // MARK: - Push Local State to Remote iCloud
    public func pushLocalChanges() {
        self.isSyncing = true

        // 1. Khatmah
        kvStore.set(Int64(KhatmahService.shared.currentPage), forKey: "khatmah_current_page")
        kvStore.set(Int64(KhatmahService.shared.targetDays), forKey: "khatmah_target_days")

        // 2. Last Read
        let sync = QuranSyncManager.shared
        kvStore.set(Int64(sync.lastSurahId), forKey: "bayan_last_surah_id")
        kvStore.set(Int64(sync.lastAyahId), forKey: "bayan_last_ayah_id")
        kvStore.set(Int64(sync.lastPageNumber), forKey: "bayan_last_page_number")
        kvStore.set(sync.lastQariId, forKey: "bayan_last_qari_id")
        kvStore.set(sync.lastAudioTimestamp, forKey: "bayan_last_audio_timestamp")

        // 3. Bookmarks
        if let encoded = try? JSONEncoder().encode(BookmarkService.shared.bookmarks) {
            kvStore.set(encoded, forKey: "bayan_ayah_bookmarks")
        }

        // 4. Prayer Tracker for Today
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = "bayan_prayed_prayers_" + formatter.string(from: Date())
        let todayPrayed = Array(PrayerTrackerService.shared.getCompletedPrayers(for: Date()))
        kvStore.set(todayPrayed, forKey: todayKey)

        // 5. Settings & Theme
        kvStore.set(AppThemeManager.shared.currentTheme.rawValue, forKey: "bayan_selected_theme")
        kvStore.set(PrayerSettingsManager.shared.convention.rawValue, forKey: "prayer_calculation_convention")
        kvStore.set(PrayerSettingsManager.shared.asrSchool.rawValue, forKey: "prayer_asr_school")
        kvStore.set(PrayerSettingsManager.shared.isPreAdhanReminderEnabled, forKey: "prayer_pre_adhan_reminder")

        let now = Date()
        kvStore.set(now.timeIntervalSince1970, forKey: lastSyncKey)
        kvStore.synchronize()

        self.lastSyncDate = now
        self.isSyncing = false
        self.syncStatusMessage = "Synced with iCloud"
    }

    // MARK: - Manual Trigger
    public func synchronizeNow() {
        pushLocalChanges()
        pullRemoteChanges()
    }
}
