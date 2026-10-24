import Foundation
import SwiftUI

// MARK: - Prayer Tracker & Habit Service
@Observable
public final class PrayerTrackerService {
    public static let shared = PrayerTrackerService()

    private let storageKeyPrefix = "bayan_prayed_prayers_"
    private let secureKeyPrefix = "bayan_secure_prayed_aes256_"
    private let mutedPrayersKey = "bayan_muted_prayers"
    private let encryption = BayanDataEncryptionService.shared

    public var mutedPrayerIds: Set<String> = []

    public init() {
        if let array = UserDefaults.standard.stringArray(forKey: mutedPrayersKey) {
            self.mutedPrayerIds = Set(array)
        }
    }

    private func legacyKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return storageKeyPrefix + formatter.string(from: date)
    }

    private func secureKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return secureKeyPrefix + formatter.string(from: date)
    }

    public func getCompletedPrayers(for date: Date) -> Set<String> {
        // 1. Check AES-256 encrypted storage
        let sKey = secureKey(for: date)
        if let encrypted = UserDefaults.standard.data(forKey: sKey),
           let decrypted = try? encryption.decryptCodable([String].self, from: encrypted) {
            return Set(decrypted)
        }

        // 2. Migration from legacy plaintext
        let lKey = legacyKey(for: date)
        if let array = UserDefaults.standard.stringArray(forKey: lKey) {
            let set = Set(array)
            saveSecurePrayers(set, for: date)
            UserDefaults.standard.removeObject(forKey: lKey)
            return set
        }
        return []
    }

    private func saveSecurePrayers(_ set: Set<String>, for date: Date) {
        if let encrypted = try? encryption.encryptCodable(Array(set)) {
            UserDefaults.standard.set(encrypted, forKey: secureKey(for: date))
        }
        UserDefaults.standard.removeObject(forKey: legacyKey(for: date))
        BayanCloudSyncService.shared.pushLocalChanges()
    }

    public func togglePrayer(_ prayerId: String, for date: Date) -> Set<String> {
        var set = getCompletedPrayers(for: date)
        if set.contains(prayerId) {
            set.remove(prayerId)
        } else {
            set.insert(prayerId)
        }
        saveSecurePrayers(set, for: date)
        return set
    }

    public func markAll(for date: Date, allIds: [String]) -> Set<String> {
        let current = getCompletedPrayers(for: date)
        let newSet: Set<String>
        if current.count == allIds.count {
            newSet = []
        } else {
            newSet = Set(allIds)
        }
        saveSecurePrayers(newSet, for: date)
        return newSet
    }

    public func toggleMute(prayerId: String) {
        if mutedPrayerIds.contains(prayerId) {
            mutedPrayerIds.remove(prayerId)
        } else {
            mutedPrayerIds.insert(prayerId)
        }
        UserDefaults.standard.set(Array(mutedPrayerIds), forKey: mutedPrayersKey)
    }
}
