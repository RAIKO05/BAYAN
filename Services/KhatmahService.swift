import Foundation

// MARK: - Quran Khatmah Goal Tracker Service
// Tracks personal completion goals (30-day Ramadan pace, 60-day, etc.),
// page progress (1 to 604), Juz' calculation, and daily pace.
@Observable
public final class KhatmahService {
    public static let shared = KhatmahService()

    public let totalPages: Int = 604
    public let totalJuz: Int = 30

    private let userDefaults = UserDefaults.standard

    // Keys
    private let kCurrentPage = "khatmah_current_page"
    private let kTargetDays = "khatmah_target_days"
    private let kStartDate = "khatmah_start_date"
    private let kPagesReadToday = "khatmah_pages_today"
    private let kLastLogDate = "khatmah_last_log_date"
    private let kIsActive = "khatmah_is_active"

    public var currentPage: Int {
        didSet {
            userDefaults.set(currentPage, forKey: kCurrentPage)
        }
    }

    public var targetDays: Int {
        didSet {
            userDefaults.set(targetDays, forKey: kTargetDays)
        }
    }

    public var startDate: Date {
        didSet {
            userDefaults.set(startDate, forKey: kStartDate)
        }
    }

    public var pagesReadToday: Int {
        didSet {
            userDefaults.set(pagesReadToday, forKey: kPagesReadToday)
        }
    }

    public var isActive: Bool {
        didSet {
            userDefaults.set(isActive, forKey: kIsActive)
        }
    }

    private init() {
        let savedPage = userDefaults.integer(forKey: kCurrentPage)
        self.currentPage = savedPage > 0 ? min(savedPage, 604) : 1

        let savedDays = userDefaults.integer(forKey: kTargetDays)
        self.targetDays = savedDays > 0 ? savedDays : 30

        if let savedDate = userDefaults.object(forKey: kStartDate) as? Date {
            self.startDate = savedDate
        } else {
            let now = Date()
            self.startDate = now
            userDefaults.set(now, forKey: kStartDate)
        }

        self.isActive = userDefaults.object(forKey: kIsActive) as? Bool ?? true

        // Check if date rolled over for pagesReadToday
        let lastDate = userDefaults.object(forKey: kLastLogDate) as? Date ?? Date.distantPast
        if Calendar.current.isDateInToday(lastDate) {
            self.pagesReadToday = userDefaults.integer(forKey: kPagesReadToday)
        } else {
            self.pagesReadToday = 0
            userDefaults.set(0, forKey: kPagesReadToday)
            userDefaults.set(Date(), forKey: kLastLogDate)
        }
    }

    // MARK: - Computed Progress Metrics
    public var progressFraction: Double {
        min(1.0, max(0.0, Double(currentPage) / Double(totalPages)))
    }

    public var progressPercentString: String {
        let percent = Int(progressFraction * 100)
        return "\(percent)%"
    }

    public var currentJuz: Int {
        max(1, min(30, ((currentPage - 1) / 20) + 1))
    }

    public var pagesRemaining: Int {
        max(0, totalPages - currentPage)
    }

    public var daysElapsed: Int {
        let diff = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0, diff)
    }

    public var daysRemaining: Int {
        max(0, targetDays - daysElapsed)
    }

    public var dailyTargetPages: Int {
        max(1, Int(ceil(Double(totalPages) / Double(targetDays))))
    }

    public var pagesLeftToday: Int {
        max(0, dailyTargetPages - pagesReadToday)
    }

    public var isOnTrack: Bool {
        let idealPage = Int(Double(dailyTargetPages) * Double(max(1, daysElapsed + 1)))
        return currentPage >= min(totalPages, idealPage)
    }

    // MARK: - Actions
    public func incrementPage() {
        guard currentPage < totalPages else { return }
        checkDateRollover()
        currentPage += 1
        pagesReadToday += 1
        userDefaults.set(Date(), forKey: kLastLogDate)
    }

    public func setPage(_ page: Int) {
        let clamped = max(1, min(totalPages, page))
        checkDateRollover()
        let diff = clamped - currentPage
        if diff > 0 {
            pagesReadToday += diff
        }
        currentPage = clamped
        userDefaults.set(Date(), forKey: kLastLogDate)
    }

    public func startNewKhatmah(days: Int) {
        targetDays = max(7, days)
        currentPage = 1
        pagesReadToday = 0
        startDate = Date()
        isActive = true
        userDefaults.set(Date(), forKey: kLastLogDate)
    }

    public func resetKhatmah() {
        currentPage = 1
        pagesReadToday = 0
        startDate = Date()
        userDefaults.set(Date(), forKey: kLastLogDate)
    }

    private func checkDateRollover() {
        let lastDate = userDefaults.object(forKey: kLastLogDate) as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastDate) {
            pagesReadToday = 0
            userDefaults.set(0, forKey: kPagesReadToday)
            userDefaults.set(Date(), forKey: kLastLogDate)
        }
    }

    public func currentSurah() -> Surah {
        QuranDataService.shared.allSurahs.last(where: { $0.startPage <= currentPage }) ?? Surah.sampleFatihah
    }
}
