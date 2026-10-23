import Foundation
import SwiftUI

// MARK: - Islamic Hijri Calendar & Sunnah Fasting Service
@Observable
public final class HijriCalendarService: @unchecked Sendable {
    public static let shared = HijriCalendarService()

    // Moon Sighting Manual Offset (-2 to +2 days for regional alignment e.g. Morocco, North America)
    public var dayOffset: Int {
        didSet {
            UserDefaults.standard.set(dayOffset, forKey: "bayan_hijri_day_offset")
        }
    }

    // Fasted Dates Storage ("YYYY-MM-DD")
    private var fastedDateStrings: Set<String> = []

    private let islamicCalendar: Calendar = {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.timeZone = TimeZone.current
        return cal
    }()

    private let gregorianCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }()

    public let monthNamesArabic: [Int: String] = [
        1: "مُحَرَّم",
        2: "صَفَر",
        3: "رَبِيع الأَوَّل",
        4: "رَبِيع الآخِر",
        5: "جُمَادَى الأُولَى",
        6: "جُمَادَى الآخِرَة",
        7: "رَجَب",
        8: "شَعْبَان",
        9: "رَمَضَان",
        10: "شَوَّال",
        11: "ذُو القَعْدَة",
        12: "ذُو الحِجَّة"
    ]

    public let monthNamesEnglish: [Int: String] = [
        1: "Muharram",
        2: "Safar",
        3: "Rabi' al-Awwal",
        4: "Rabi' al-Thani",
        5: "Jumada al-Ula",
        6: "Jumada al-Akhirah",
        7: "Rajab",
        8: "Sha'ban",
        9: "Ramadan",
        10: "Shawwal",
        11: "Dhu al-Qi'dah",
        12: "Dhu al-Hijjah"
    ]

    public let sacredMonths: Set<Int> = [1, 7, 11, 12]

    private init() {
        self.dayOffset = UserDefaults.standard.integer(forKey: "bayan_hijri_day_offset")
        loadFastedDays()
    }

    // MARK: - Fasted Days Management
    private func loadFastedDays() {
        if let data = UserDefaults.standard.string(forKey: "bayan_fasted_days_json"),
           let array = try? JSONDecoder().decode([String].self, from: Data(data.utf8)) {
            self.fastedDateStrings = Set(array)
        }
    }

    private func saveFastedDays() {
        if let data = try? JSONEncoder().encode(Array(fastedDateStrings)),
           let string = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(string, forKey: "bayan_fasted_days_json")
        }
    }

    public func isFasted(date: Date) -> Bool {
        let key = dateFormatterKey(from: date)
        return fastedDateStrings.contains(key)
    }

    public func toggleFasted(date: Date) {
        let key = dateFormatterKey(from: date)
        if fastedDateStrings.contains(key) {
            fastedDateStrings.remove(key)
        } else {
            fastedDateStrings.insert(key)
        }
        saveFastedDays()
    }

    private func dateFormatterKey(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }

    // MARK: - Date Conversion & HijriDay Construction
    public func hijriDay(for date: Date) -> HijriDay {
        let adjustedDate = gregorianCalendar.date(byAdding: .day, value: dayOffset, to: date) ?? date
        let comps = islamicCalendar.dateComponents([.year, .month, .day], from: adjustedDate)

        let hYear = comps.year ?? 1447
        let hMonth = comps.month ?? 1
        let hDay = comps.day ?? 1

        let monthAr = monthNamesArabic[hMonth] ?? "شهر"
        let monthEn = monthNamesEnglish[hMonth] ?? "Month"
        let isSacred = sacredMonths.contains(hMonth)
        let isToday = gregorianCalendar.isDateInToday(date)

        let (phase, illumination) = calculateLunarPhase(for: date)
        let fastingType = determineFastingType(date: date, hijriMonth: hMonth, hijriDay: hDay)
        let event = islamicEvent(hijriMonth: hMonth, hijriDay: hDay)

        return HijriDay(
            date: date,
            hijriYear: hYear,
            hijriMonth: hMonth,
            hijriDay: hDay,
            monthNameArabic: monthAr,
            monthNameEnglish: monthEn,
            isSacredMonth: isSacred,
            isToday: isToday,
            lunarPhase: phase,
            lunarIlluminationPercent: illumination,
            fastingType: fastingType,
            islamicEvent: event
        )
    }

    public func currentHijriDay() -> HijriDay {
        hijriDay(for: Date())
    }

    // MARK: - Month Days Generator
    /// Returns all days corresponding to the given Hijri month and year
    public func days(forHijriMonth targetMonth: Int, year targetYear: Int) -> [HijriDay] {
        var result: [HijriDay] = []
        var testDate = gregorianCalendar.date(byAdding: .day, value: -60, to: Date()) ?? Date()

        // Scan window of ~120 days to capture all days belonging to this Hijri month
        for offset in 0..<120 {
            guard let candidate = gregorianCalendar.date(byAdding: .day, value: offset, to: testDate) else { continue }
            let day = hijriDay(for: candidate)
            if day.hijriMonth == targetMonth && day.hijriYear == targetYear {
                result.append(day)
            }
        }

        // Sort chronologically and deduplicate
        result.sort { $0.date < $1.date }
        var unique: [HijriDay] = []
        var seenDays = Set<Int>()
        for d in result {
            if !seenDays.contains(d.hijriDay) {
                seenDays.insert(d.hijriDay)
                unique.append(d)
            }
        }
        return unique
    }

    // MARK: - Fasting Type Classification
    private func determineFastingType(date: Date, hijriMonth: Int, hijriDay: Int) -> IslamicFastingType {
        // 1. Prohibited days: Eid al-Fitr (10/1), Eid al-Adha (12/10), Tashreeq (12/11, 12, 13)
        if hijriMonth == 10 && hijriDay == 1 {
            return .prohibited
        }
        if hijriMonth == 12 && (hijriDay >= 10 && hijriDay <= 13) {
            return .prohibited
        }

        // 2. Fard Ramadan
        if hijriMonth == 9 {
            return .fardRamadan
        }

        // 3. Day of Arafah (12/9)
        if hijriMonth == 12 && hijriDay == 9 {
            return .arafah
        }

        // 4. Ashura & Tasu'a (1/9, 1/10)
        if hijriMonth == 1 && hijriDay == 10 {
            return .ashura
        }
        if hijriMonth == 1 && hijriDay == 9 {
            return .tasua
        }

        // 5. White Days (13, 14, 15 of every month)
        if hijriDay >= 13 && hijriDay <= 15 {
            return .whiteDay
        }

        // 6. Six Days of Shawwal (Month 10, days 2..30)
        let weekday = gregorianCalendar.component(.weekday, from: date)
        if weekday == 2 { // Monday (Sunday=1, Monday=2)
            return .sunnahMonday
        }
        if weekday == 5 { // Thursday (Thursday=5)
            return .sunnahThursday
        }

        if hijriMonth == 10 && hijriDay >= 2 {
            return .shawwalSix
        }

        return .none
    }

    // MARK: - Major Islamic Historical Events
    private func islamicEvent(hijriMonth: Int, hijriDay: Int) -> String? {
        switch (hijriMonth, hijriDay) {
        case (1, 1): return "Islamic New Year • رأس السنة الهجرية"
        case (1, 9): return "Tasu'a • تاسوعاء"
        case (1, 10): return "Day of Ashura • يوم عاشوراء"
        case (3, 12): return "Mawlid an-Nabi • المولد النبوي الشريف"
        case (7, 27): return "Al-Isra wal-Mi'raj • الإسراء والمعراج"
        case (8, 15): return "Nisf Sha'ban • ليلة النصف من شعبان"
        case (9, 1): return "1st of Ramadan • أول أيام شهر رمضان المبارك"
        case (9, 21): return "Start of Last 10 Nights • بداية العشر الأواخر"
        case (9, 27): return "Laylat al-Qadr (Estimated) • ليلة القدر"
        case (10, 1): return "Eid al-Fitr • عيد الفطر المبارك"
        case (12, 1): return "First of Dhu al-Hijjah • أول ذي الحجة"
        case (12, 8): return "Yawm at-Tarwiyah • يوم التروية"
        case (12, 9): return "Day of Arafah • يوم عرفة"
        case (12, 10): return "Eid al-Adha • عيد الأضحى المبارك"
        case (12, 11...13): return "Days of Tashreeq • أيام التشريق"
        default: return nil
        }
    }

    // MARK: - Astronomical Lunar Phase Calculation
    public func calculateLunarPhase(for date: Date) -> (phase: LunarPhase, illuminationPercent: Int) {
        // Reference new moon epoch: Jan 11, 2024 at 11:57 UTC
        var comps = DateComponents()
        comps.year = 2024
        comps.month = 1
        comps.day = 11
        comps.hour = 11
        comps.minute = 57
        comps.timeZone = TimeZone(secondsFromGMT: 0)
        let refNewMoon = Calendar(identifier: .gregorian).date(from: comps) ?? Date(timeIntervalSince1970: 1704974220)

        let synodicMonth = 29.53058867 * 86400.0
        let elapsed = date.timeIntervalSince(refNewMoon)
        let cycles = elapsed / synodicMonth
        let normalizedPhase = cycles - floor(cycles)

        let illumination = Int(round((1.0 - cos(2.0 * .pi * normalizedPhase)) / 2.0 * 100.0))

        let phase: LunarPhase
        switch normalizedPhase {
        case 0.0..<0.03, 0.97...1.0:
            phase = .newMoon
        case 0.03..<0.22:
            phase = .waxingCrescent
        case 0.22..<0.28:
            phase = .firstQuarter
        case 0.28..<0.47:
            phase = .waxingGibbous
        case 0.47..<0.53:
            phase = .fullMoon
        case 0.53..<0.72:
            phase = .waningGibbous
        case 0.72..<0.78:
            phase = .lastQuarter
        default:
            phase = .waningCrescent
        }

        return (phase, illumination)
    }

    // MARK: - Fasting Statistics & Upcoming Fasts
    public func monthlyFastedCount(hijriMonth: Int, year: Int) -> Int {
        let allMonthDays = days(forHijriMonth: hijriMonth, year: year)
        return allMonthDays.filter { isFasted(date: $0.date) }.count
    }

    public func currentFastingStreak() -> Int {
        var streak = 0
        var checkDate = Date()
        while true {
            if isFasted(date: checkDate) {
                streak += 1
                guard let prev = gregorianCalendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    public func nextUpcomingSunnahFast() -> HijriDay? {
        let today = Date()
        for offset in 0...30 {
            guard let nextDate = gregorianCalendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let day = hijriDay(for: nextDate)
            if day.fastingType.isRecommendedFast && !isFasted(date: nextDate) {
                return day
            }
        }
        return nil
    }
}
