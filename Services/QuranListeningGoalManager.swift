import Foundation
import SwiftUI

// MARK: - Daily Quran Listening Goal & Habit Tracker
/// Inspired by the "Replace Music With Quran" feature:
/// - Tracks daily listening duration in seconds vs goal
/// - Maintains weekly streak dots (Mon–Sun)
/// - Computes top listened reciter and stats
@Observable
public final class QuranListeningGoalManager {
    public static let shared = QuranListeningGoalManager()

    // MARK: - User Defaults Keys
    private let kDailyGoalMinutes = "bayan_daily_goal_minutes"
    private let kTodaySeconds = "bayan_today_listening_seconds"
    private let kLastListeningDate = "bayan_last_listening_date_str"
    private let kStreakDays = "bayan_streak_days"
    private let kWeeklyHistory = "bayan_weekly_history_json"
    private let kReciterMinutes = "bayan_reciter_listening_minutes_json"

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

    public var streakDays: Int {
        didSet {
            UserDefaults.standard.set(streakDays, forKey: kStreakDays)
        }
    }

    public init() {
        let storedGoal = UserDefaults.standard.integer(forKey: kDailyGoalMinutes)
        self.dailyGoalMinutes = storedGoal > 0 ? storedGoal : 10 // Default 10 minutes
        self.todaySeconds = UserDefaults.standard.double(forKey: kTodaySeconds)
        self.streakDays = max(1, UserDefaults.standard.integer(forKey: kStreakDays))

        checkDayRollover()
    }

    // MARK: - Day Rollover Check
    public func checkDayRollover() {
        let calendar = Calendar.current
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
    }

    public var weekdayStatuses: [WeekdayStatus] {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sun, 2=Mon...

        // Standard Mon->Sun display symbols
        let days: [(symbol: String, weekdayNum: Int)] = [
            ("Mon", 2), ("Tue", 3), ("Wed", 4), ("Thu", 5), ("Fri", 6), ("Sat", 7), ("Sun", 1)
        ]

        let history = loadHistory()

        return days.map { day in
            let isToday = (day.weekdayNum == todayWeekday)
            let isPast = (day.weekdayNum < todayWeekday && todayWeekday != 1) || (todayWeekday == 1 && day.weekdayNum != 1)
            let isAchieved = isToday ? isGoalAchievedToday : (history[day.symbol] ?? false)

            return WeekdayStatus(
                symbol: day.symbol,
                isToday: isToday,
                isAchieved: isAchieved,
                isPast: isPast
            )
        }
    }

    // MARK: - Top Reciter
    public var topReciter: (reciter: Reciter, minutes: Int) {
        let map = loadReciterMinutes()
        if let top = map.max(by: { $0.value < $1.value }),
           let reciter = Reciter.standardCatalog.first(where: { $0.id == top.key }) {
            return (reciter, Int(top.value))
        }
        // Fallback default
        let defaultReciter = Reciter.standardCatalog.first(where: { $0.id == "dosari" }) ?? Reciter.standardCatalog[0]
        return (defaultReciter, max(15, Int(todaySeconds / 60)))
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
            return ["Mon": true, "Tue": true] // Default starter streak
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

    private func loadReciterMinutes() -> [String: Double] {
        guard let data = UserDefaults.standard.data(forKey: kReciterMinutes),
              let map = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return ["dosari": 45.0, "alafasy": 30.0]
        }
        return map
    }

    private func saveReciterMinutes(_ map: [String: Double]) {
        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: kReciterMinutes)
        }
    }
}
