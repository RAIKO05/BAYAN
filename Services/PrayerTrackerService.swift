import Foundation
import SwiftUI

// MARK: - Prayer Tracker & Habit Service
@Observable
public final class PrayerTrackerService {
    public static let shared = PrayerTrackerService()

    private let storageKeyPrefix = "bayan_prayed_prayers_"
    private let mutedPrayersKey = "bayan_muted_prayers"

    public var mutedPrayerIds: Set<String> = []

    public init() {
        if let array = UserDefaults.standard.stringArray(forKey: mutedPrayersKey) {
            self.mutedPrayerIds = Set(array)
        }
    }

    private func key(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return storageKeyPrefix + formatter.string(from: date)
    }

    public func getCompletedPrayers(for date: Date) -> Set<String> {
        let k = key(for: date)
        if let array = UserDefaults.standard.stringArray(forKey: k) {
            return Set(array)
        }
        return []
    }

    public func togglePrayer(_ prayerId: String, for date: Date) -> Set<String> {
        var set = getCompletedPrayers(for: date)
        if set.contains(prayerId) {
            set.remove(prayerId)
        } else {
            set.insert(prayerId)
        }
        UserDefaults.standard.set(Array(set), forKey: key(for: date))
        BayanCloudSyncService.shared.pushLocalChanges()
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
        UserDefaults.standard.set(Array(newSet), forKey: key(for: date))
        BayanCloudSyncService.shared.pushLocalChanges()
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
