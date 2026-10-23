import Foundation
import UserNotifications

// MARK: - Sunnah Fasting & Suhoor Notification Service
@Observable
public final class FastingNotificationService: @unchecked Sendable {
    public static let shared = FastingNotificationService()

    public var isFastingRemindersEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isFastingRemindersEnabled, forKey: "bayan_sunnah_fasting_reminders_enabled")
            if isFastingRemindersEnabled {
                scheduleFastingReminders()
            } else {
                cancelFastingReminders()
            }
        }
    }

    public var isSuhoorAlarmEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSuhoorAlarmEnabled, forKey: "bayan_suhoor_alarm_enabled")
        }
    }

    public var suhoorLeadMinutes: Int {
        didSet {
            UserDefaults.standard.set(suhoorLeadMinutes, forKey: "bayan_suhoor_lead_minutes")
        }
    }

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        self.isFastingRemindersEnabled = UserDefaults.standard.bool(forKey: "bayan_sunnah_fasting_reminders_enabled")
        self.isSuhoorAlarmEnabled = UserDefaults.standard.bool(forKey: "bayan_suhoor_alarm_enabled")
        let savedLead = UserDefaults.standard.integer(forKey: "bayan_suhoor_lead_minutes")
        self.suhoorLeadMinutes = savedLead > 0 ? savedLead : 45
    }

    public func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    self.scheduleFastingReminders()
                }
            }
        }
    }

    public func scheduleFastingReminders() {
        cancelFastingReminders()

        let calendarService = HijriCalendarService.shared
        let now = Date()
        let cal = Calendar.current

        // Schedule reminders for upcoming 14 days
        for offset in 1...14 {
            guard let targetDate = cal.date(byAdding: .day, value: offset, to: now) else { continue }
            let day = calendarService.hijriDay(for: targetDate)

            if day.fastingType.isRecommendedFast {
                // Schedule evening reminder on the eve of the fast (at 20:30 previous night)
                if let eveDate = cal.date(byAdding: .day, value: -1, to: targetDate) {
                    var eveComps = cal.dateComponents([.year, .month, .day], from: eveDate)
                    eveComps.hour = 20
                    eveComps.minute = 30

                    if let triggerDate = cal.date(from: eveComps), triggerDate > now {
                        let content = UNMutableNotificationContent()
                        content.title = "غداً صيام مسنون • Tomorrow is Sunnah Fasting"
                        content.body = "\(day.fastingType.titleArabic) • \(day.fastingType.titleEnglish). انوِ الصيام وجهّز سحورك."
                        content.sound = .default

                        let triggerComps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
                        let request = UNNotificationRequest(
                            identifier: "bayan_fasting_eve_\(day.id)",
                            content: content,
                            trigger: trigger
                        )
                        notificationCenter.add(request)
                    }
                }
            }
        }
    }

    public func cancelFastingReminders() {
        notificationCenter.getPendingNotificationRequests { requests in
            let fastingIds = requests.map { $0.identifier }.filter { $0.hasPrefix("bayan_fasting_") }
            if !fastingIds.isEmpty {
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: fastingIds)
            }
        }
    }
}
