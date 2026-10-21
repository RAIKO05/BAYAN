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
        let prayerIds = ["subuh", "dzuhur", "ashar", "maghrib", "isya", "fajr", "dhuhr", "asr", "isha"]
        var identifiers = prayerIds.map { "bayan_adhan_\($0)" }
        identifiers.append(contentsOf: prayerIds.map { "bayan_pre_adhan_\($0)" })
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        let isPreReminderEnabled = PrayerSettingsManager.shared.isPreAdhanReminderEnabled

        for prayer in prayerTimes {
            // 1. Main Adhan Notification at Prayer Time
            var dateComponents = DateComponents()
            dateComponents.hour = prayer.hour
            dateComponents.minute = prayer.minute
            dateComponents.second = 0

            let content = UNMutableNotificationContent()
            content.title = "حان الآن موعد أذان \(prayer.nameArabic)"
            content.subtitle = "\(prayer.nameEnglish) Prayer Time (\(prayer.timeString))"
            content.body = "حي على الصلاة، حي على الفلاح • تقبل الله طاعتكم"
            content.sound = UNNotificationSound(named: UNNotificationSoundName("adhan.caf"))

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

            // 2. 15-Minute Advance Pre-Adhan Reminder (Optional)
            if isPreReminderEnabled {
                var preHour = prayer.hour
                var preMinute = prayer.minute - 15
                if preMinute < 0 {
                    preMinute += 60
                    preHour -= 1
                    if preHour < 0 { preHour += 24 }
                }

                var preDateComponents = DateComponents()
                preDateComponents.hour = preHour
                preDateComponents.minute = preMinute
                preDateComponents.second = 0

                let preContent = UNMutableNotificationContent()
                preContent.title = "اقترب موعد أذان \(prayer.nameArabic)"
                preContent.subtitle = "\(prayer.nameEnglish) in 15 minutes (\(prayer.timeString))"
                preContent.body = "استعد للصلاة والوضوء • الصلاة عماد الدين"
                preContent.sound = .default

                let preTrigger = UNCalendarNotificationTrigger(dateMatching: preDateComponents, repeats: true)
                let preRequest = UNNotificationRequest(
                    identifier: "bayan_pre_adhan_\(prayer.id)",
                    content: preContent,
                    trigger: preTrigger
                )

                center.add(preRequest) { error in
                    if let error = error {
                        print("⚠️ Failed to schedule 15m pre-Adhan for \(prayer.nameEnglish): \(error)")
                    }
                }
            }
        }
        print("🔔 Successfully scheduled daily Adhan & Pre-Adhan notifications.")
    }

    /// Cancels all scheduled Adhan notifications
    public func cancelAll() {
        let prayerIds = ["subuh", "dzuhur", "ashar", "maghrib", "isya", "fajr", "dhuhr", "asr", "isha"]
        var identifiers = prayerIds.map { "bayan_adhan_\($0)" }
        identifiers.append(contentsOf: prayerIds.map { "bayan_pre_adhan_\($0)" })
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        isNotificationsEnabled = false
        print("🔕 All Adhan notifications cancelled.")
    }
}
