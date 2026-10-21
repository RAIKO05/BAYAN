import Foundation
import UserNotifications

// MARK: - Adhan Local Push Notification Service
// Schedules notifications for the 5 daily prayers (Moroccan Ministry of Habous)
@Observable
public final class AdhanNotificationService {
    public static let shared = AdhanNotificationService()

    public var isNotificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "adhan_notifications_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "adhan_notifications_enabled") }
    }

    private init() {}

    /// Requests push notification authorization from iOS
    public func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationsEnabled = granted
                completion(granted)
            }
        }
    }

    /// Schedules notifications for today's calculated prayer times
    public func scheduleAdhanNotifications(prayerTimes: [PrayerTimeItem]) {
        guard isNotificationsEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let identifiers = ["fajr", "dhuhr", "asr", "maghrib", "isha"].map { "bayan_adhan_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        let calendar = Calendar.current
        let now = Date()

        for prayer in prayerTimes {
            var dateComponents = DateComponents()
            dateComponents.hour = prayer.hour
            dateComponents.minute = prayer.minute
            dateComponents.second = 0

            let content = UNMutableNotificationContent()
            content.title = "حان الآن موعد أذان \(prayer.nameArabic)"
            content.subtitle = "\(prayer.nameEnglish) Prayer Time (\(prayer.timeString))"
            content.body = "حي على الصلاة، حي على الفلاح • تقبل الله طاعتكم"
            content.sound = .default

            // Repeat daily at the specific hour and minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "bayan_adhan_\(prayer.id)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("⚠️ Failed to schedule Adhan for \(prayer.nameEnglish): \(error)")
                }
            }
        }
        print("🔔 Successfully scheduled daily Adhan notifications for 5 prayers.")
    }

    /// Cancels all scheduled Adhan notifications
    public func cancelAll() {
        let identifiers = ["fajr", "dhuhr", "asr", "maghrib", "isha"].map { "bayan_adhan_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        isNotificationsEnabled = false
        print("🔕 All Adhan notifications cancelled.")
    }
}
