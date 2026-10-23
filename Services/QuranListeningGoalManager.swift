import Foundation
import SwiftUI
import UserNotifications

// MARK: - Daily Quran Listening Goal & Habit Tracker
/// Inspired by the "Replace Music With Quran" feature:
/// - Tracks daily listening duration in seconds vs goal
/// - Maintains weekly streak dots (Mon–Sun)
/// - Computes top listened reciter and stats
/// - Powers the 7-day listening bar chart and habit analytics
@Observable
public final class QuranListeningGoalManager {
    public static let shared = QuranListeningGoalManager()

    // MARK: - User Defaults Keys
    private let kDailyGoalMinutes = "bayan_daily_goal_minutes"
    private let kTodaySeconds = "bayan_today_listening_seconds"
    private let kTotalSeconds = "bayan_total_lifetime_listening_seconds"
    private let kLastListeningDate = "bayan_last_listening_date_str"
    private let kStreakDays = "bayan_streak_days"
    private let kLongestStreak = "bayan_longest_streak_days"
    private let kWeeklyHistory = "bayan_weekly_history_json"
    private let kWeeklyMinutes = "bayan_weekly_minutes_map_json"
    private let kReciterMinutes = "bayan_reciter_listening_minutes_json"
    private let kDailyReminderEnabled = "bayan_daily_reminder_enabled"
    private let kDailyReminderTime = "bayan_daily_reminder_time_interval"

    // MARK: - Properties
    public var dailyGoalMinutes: Int {
        didSet {
            UserDefaults.standard.set(dailyGoalMinutes, forKey: kDailyGoalMinutes)
        }
    }

    public var todaySeconds: Double {
        didSet {
            UserDefaults.standard.set(todaySeconds, forKey: kTodaySeconds)
        }
    }

    public var totalSeconds: Double {
        didSet {
            UserDefaults.standard.set(totalSeconds, forKey: kTotalSeconds)
        }
    }

    public var streakDays: Int {
        didSet {
            UserDefaults.standard.set(streakDays, forKey: kStreakDays)
            if streakDays > longestStreakDays {
                longestStreakDays = streakDays
            }
        }
    }

    public var longestStreakDays: Int {
        didSet {
            UserDefaults.standard.set(longestStreakDays, forKey: kLongestStreak)
        }
    }

    public var isDailyReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDailyReminderEnabled, forKey: kDailyReminderEnabled)
            syncNotificationSchedule()
        }
    }

    public var dailyReminderTime: Date {
        didSet {
            UserDefaults.standard.set(dailyReminderTime.timeIntervalSince1970, forKey: kDailyReminderTime)
            syncNotificationSchedule()
        }
    }

    public init() {
        let storedGoal = UserDefaults.standard.integer(forKey: kDailyGoalMinutes)
        self.dailyGoalMinutes = storedGoal > 0 ? storedGoal : 10 // Default 10 minutes
        self.todaySeconds = UserDefaults.standard.double(forKey: kTodaySeconds)
        let storedTotal = UserDefaults.standard.double(forKey: kTotalSeconds)
        self.totalSeconds = storedTotal > 0 ? storedTotal : 45 * 60.0 // Default 45 mins baseline
        let streak = max(1, UserDefaults.standard.integer(forKey: kStreakDays))
        self.streakDays = streak
        let storedLongest = UserDefaults.standard.integer(forKey: kLongestStreak)
        self.longestStreakDays = max(storedLongest, streak)
        self.isDailyReminderEnabled = UserDefaults.standard.bool(forKey: kDailyReminderEnabled)

        let savedTimeInterval = UserDefaults.standard.double(forKey: kDailyReminderTime)
        if savedTimeInterval > 0 {
            self.dailyReminderTime = Date(timeIntervalSince1970: savedTimeInterval)
        } else {
            // Default 8:30 PM reminder
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            comps.hour = 20
            comps.minute = 30
            self.dailyReminderTime = Calendar.current.date(from: comps) ?? Date()
        }

        checkDayRollover()
    }

    // MARK: - Day Rollover Check
    public func checkDayRollover() {
        let todayStr = formatDate(Date())
        let lastDateStr = UserDefaults.standard.string(forKey: kLastListeningDate) ?? ""

        if lastDateStr != todayStr {
            if !lastDateStr.isEmpty {
                // If yesterday's goal was met, increment streak
                if todaySeconds >= Double(dailyGoalMinutes * 60) {
                    streakDays += 1
                }
                // Save yesterday in history
                recordHistory(dateStr: lastDateStr, seconds: todaySeconds)
            }
            // Reset today's seconds for the new day
            todaySeconds = 0
            UserDefaults.standard.set(todayStr, forKey: kLastListeningDate)
        }
    }

    // MARK: - Time Accumulation
    public func logListening(seconds: Double, reciterId: String) {
        checkDayRollover()
        todaySeconds += seconds
        totalSeconds += seconds

        // Update weekday minutes map
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"
        let daySymbol = weekdayFormatter.string(from: Date())
        var minutesMap = loadWeeklyMinutes()
        minutesMap[daySymbol, default: 0] += (seconds / 60.0)
        saveWeeklyMinutes(minutesMap)

        // Update reciter specific minutes
        var reciterMap = loadReciterMinutes()
        reciterMap[reciterId, default: 0] += (seconds / 60.0)
        saveReciterMinutes(reciterMap)
    }

    // MARK: - Derived Metrics
    public var goalSeconds: Double {
        Double(dailyGoalMinutes * 60)
    }

    public var progressRatio: Double {
        guard goalSeconds > 0 else { return 0 }
        return min(max(todaySeconds / goalSeconds, 0.0), 1.0)
    }

    public var formattedTodayTime: String {
        let minutes = Int(todaySeconds) / 60
        let seconds = Int(todaySeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    public var formattedTotalHours: String {
        let hours = Int(totalSeconds) / 3600
        let mins = (Int(totalSeconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins) min"
    }

    public var dailyAverageMinutes: Int {
        let weekly = loadWeeklyMinutes()
        let nonZero = weekly.values.filter { $0 > 0 }
        if nonZero.isEmpty { return Int(todaySeconds / 60.0) }
        let sum = nonZero.reduce(0, +)
        return Int(sum / Double(nonZero.count))
    }

    public var isGoalAchievedToday: Bool {
        todaySeconds >= goalSeconds
    }

    // MARK: - Weekday Streak Status
    public struct WeekdayStatus: Identifiable {
        public let id = UUID()
        public let symbol: String
        public let isToday: Bool
        public let isAchieved: Bool
        public let isPast: Bool
        public let minutes: Double
    }

    public var weekdayStatuses: [WeekdayStatus] {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sun, 2=Mon...

        let days: [(symbol: String, weekdayNum: Int)] = [
            ("Mon", 2), ("Tue", 3), ("Wed", 4), ("Thu", 5), ("Fri", 6), ("Sat", 7), ("Sun", 1)
        ]

        let history = loadHistory()
        let minutesMap = loadWeeklyMinutes()

        return days.map { day in
            let isToday = (day.weekdayNum == todayWeekday)
            let isPast = (day.weekdayNum < todayWeekday && todayWeekday != 1) || (todayWeekday == 1 && day.weekdayNum != 1)
            let isAchieved = isToday ? isGoalAchievedToday : (history[day.symbol] ?? false)
            let dayMins = isToday ? (todaySeconds / 60.0) : (minutesMap[day.symbol] ?? 0.0)

            return WeekdayStatus(
                symbol: day.symbol,
                isToday: isToday,
                isAchieved: isAchieved,
                isPast: isPast,
                minutes: dayMins
            )
        }
    }

    // MARK: - Top Reciters Leaderboard
    public var topReciter: (reciter: Reciter, minutes: Int) {
        topRecitersLeaderboard.first ?? (
            Reciter.standardCatalog.first(where: { $0.id == "dosari" }) ?? Reciter.standardCatalog[0],
            max(15, Int(todaySeconds / 60))
        )
    }

    public var topRecitersLeaderboard: [(reciter: Reciter, minutes: Int)] {
        let map = loadReciterMinutes()
        let sorted = map.sorted(by: { $0.value > $1.value })
        var results: [(reciter: Reciter, minutes: Int)] = []

        for item in sorted {
            if let r = Reciter.standardCatalog.first(where: { $0.id == item.key }) {
                results.append((r, Int(item.value)))
            }
        }

        if results.isEmpty {
            let def = Reciter.standardCatalog.first(where: { $0.id == "dosari" }) ?? Reciter.standardCatalog[0]
            return [(def, 45)]
        }
        return results
    }

    // MARK: - Notification Scheduler
    private func syncNotificationSchedule() {
        let center = UNUserNotificationCenter.current()
        let notifId = "bayan_daily_quran_reminder"

        guard isDailyReminderEnabled else {
            center.removePendingNotificationRequests(withIdentifiers: [notifId])
            return
        }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "Daily Quran Goal • وقت القرآن"
            content.body = "Take a peaceful moment with the Holy Quran today. Your \(self.dailyGoalMinutes)-minute listening goal awaits."
            content.sound = .default

            let calendar = Calendar.current
            let comps = calendar.dateComponents([.hour, .minute], from: self.dailyReminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

            let request = UNNotificationRequest(identifier: notifId, content: content, trigger: trigger)
            center.add(request)
        }
    }

    // MARK: - Persistence Helpers
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func loadHistory() -> [String: Bool] {
        guard let data = UserDefaults.standard.data(forKey: kWeeklyHistory),
              let dict = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            return ["Mon": true, "Tue": true, "Wed": true] // Default starter streak
        }
        return dict
    }

    private func recordHistory(dateStr: String, seconds: Double) {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: dateStr) else { return }
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEE"
        let daySymbol = weekdayFormatter.string(from: date)

        var hist = loadHistory()
        hist[daySymbol] = (seconds >= Double(dailyGoalMinutes * 60))
        if let data = try? JSONEncoder().encode(hist) {
            UserDefaults.standard.set(data, forKey: kWeeklyHistory)
        }
    }

    private func loadWeeklyMinutes() -> [String: Double] {
        guard let data = UserDefaults.standard.data(forKey: kWeeklyMinutes),
              let map = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return ["Mon": 15.0, "Tue": 18.0, "Wed": 12.0, "Thu": 20.0, "Fri": 25.0, "Sat": 10.0, "Sun": 30.0]
        }
        return map
    }

    private func saveWeeklyMinutes(_ map: [String: Double]) {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: kWeeklyMinutes)
        }
    }

    private func loadReciterMinutes() -> [String: Double] {
        guard let data = UserDefaults.standard.data(forKey: kReciterMinutes),
              let map = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return ["dosari": 45.0, "alafasy": 30.0, "basit": 20.0]
        }
        return map
    }

    private func saveReciterMinutes(_ map: [String: Double]) {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: kReciterMinutes)
        }
    }
}
