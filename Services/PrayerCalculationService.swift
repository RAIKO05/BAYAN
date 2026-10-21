import Foundation

// MARK: - Prayer Calculation Conventions
public enum CalculationConvention: String, CaseIterable, Identifiable, Sendable {
    case habous = "habous"
    case ummAlQura = "ummAlQura"
    case mwl = "mwl"
    case egyptian = "egyptian"
    case isna = "isna"
    case karachi = "karachi"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .habous: return "Morocco (Habous)"
        case .ummAlQura: return "Umm Al-Qura (Makkah)"
        case .mwl: return "Muslim World League"
        case .egyptian: return "Egyptian Authority"
        case .isna: return "ISNA (North America)"
        case .karachi: return "Karachi (Univ. Islamic Sci.)"
        }
    }

    public var subtitle: String {
        switch self {
        case .habous: return "Fajr 19°, Isha 17° (Official Moroccan Standard)"
        case .ummAlQura: return "Fajr 18.5°, Isha 90 min after Maghrib"
        case .mwl: return "Fajr 18°, Isha 17° (Europe, Far East, parts of US)"
        case .egyptian: return "Fajr 19.5°, Isha 17.5° (Egypt, Africa, Levant)"
        case .isna: return "Fajr 15°, Isha 15° (North America)"
        case .karachi: return "Fajr 18°, Isha 18° (Pakistan, India, Bangladesh)"
        }
    }

    public var fajrAngle: Double {
        switch self {
        case .habous: return 19.0
        case .ummAlQura: return 18.5
        case .mwl: return 18.0
        case .egyptian: return 19.5
        case .isna: return 15.0
        case .karachi: return 18.0
        }
    }

    public var ishaAngle: Double {
        switch self {
        case .habous: return 17.0
        case .ummAlQura: return 0.0 // 90 min fixed offset after Maghrib
        case .mwl: return 17.0
        case .egyptian: return 17.5
        case .isna: return 15.0
        case .karachi: return 18.0
        }
    }
}

// MARK: - Asr Juristic School
public enum AsrJuristicSchool: String, CaseIterable, Identifiable, Sendable {
    case standard = "standard" // Maliki, Shafi'i, Hanbali
    case hanafi = "hanafi"     // Hanafi

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .standard: return "Standard (Maliki / Shafi'i / Hanbali)"
        case .hanafi: return "Hanafi School"
        }
    }

    public var subtitle: String {
        switch self {
        case .standard: return "Shadow equals object length (1x)"
        case .hanafi: return "Shadow equals twice object length (2x)"
        }
    }

    public var shadowFactor: Double {
        self == .hanafi ? 2.0 : 1.0
    }
}

// MARK: - Global Prayer Settings Manager
@Observable
public final class PrayerSettingsManager {
    public static let shared = PrayerSettingsManager()

    public var convention: CalculationConvention {
        get {
            let raw = UserDefaults.standard.string(forKey: "prayer_calculation_convention") ?? "habous"
            return CalculationConvention(rawValue: raw) ?? .habous
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "prayer_calculation_convention")
        }
    }

    public var asrSchool: AsrJuristicSchool {
        get {
            let raw = UserDefaults.standard.string(forKey: "prayer_asr_school") ?? "standard"
            return AsrJuristicSchool(rawValue: raw) ?? .standard
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "prayer_asr_school")
        }
    }

    public var isPreAdhanReminderEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: "prayer_pre_adhan_reminder")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "prayer_pre_adhan_reminder")
        }
    }

    private init() {}
}

// MARK: - Calculation Results
public struct PrayerTimesDayResult: Sendable {
    public let date: Date
    public let gregorianDateString: String
    public let hijriDateString: String
    public let prayers: [PrayerTimeItem]
    public let currentPrayer: PrayerTimeItem
    public let nextPrayer: PrayerTimeItem
    public let countdownSubtitle: String
}

// MARK: - Prayer Times Solar Engine
public final class PrayerCalculationService: Sendable {
    public static let shared = PrayerCalculationService()

    public init() {}

    /// Calculates accurate prayer times, dates, and active countdowns
    public func calculate(
        for date: Date,
        lat: Double,
        lng: Double,
        convention: CalculationConvention = PrayerSettingsManager.shared.convention,
        asrSchool: AsrJuristicSchool = PrayerSettingsManager.shared.asrSchool
    ) -> PrayerTimesDayResult {
        let calendar = Calendar.current
        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let tzOffset = Double(TimeZone.current.secondsFromGMT(for: date)) / 3600.0

        let gamma = 2.0 * .pi / 365.25 * (dayOfYear - 1.0)
        let eqtime = 229.18 * (0.000075 + 0.001868 * cos(gamma) - 0.032077 * sin(gamma) - 0.014615 * cos(2.0 * gamma) - 0.040849 * sin(2.0 * gamma))
        let decl = 0.006918 - 0.399912 * cos(gamma) + 0.070257 * sin(gamma) - 0.006758 * cos(2.0 * gamma) + 0.000907 * sin(2.0 * gamma)

        let solarNoon = (720.0 - 4.0 * lng - eqtime) / 60.0 + tzOffset

        func hourAngle(alphaDeg: Double) -> Double {
            let latRad = lat * .pi / 180.0
            let alphaRad = alphaDeg * .pi / 180.0
            let cosH = (sin(alphaRad) - sin(latRad) * sin(decl)) / (cos(latRad) * cos(decl))
            let clamped = max(-1.0, min(1.0, cosH))
            return acos(clamped) * 180.0 / .pi
        }

        let haFajr = hourAngle(alphaDeg: -convention.fajrAngle)
        let haSunset = hourAngle(alphaDeg: -0.833)

        // Asr: Juristic shadow multiplier
        let latRad = lat * .pi / 180.0
        let asrAltRad = atan(1.0 / (asrSchool.shadowFactor + tan(abs(latRad - decl))))
        let cosAsr = (sin(asrAltRad) - sin(latRad) * sin(decl)) / (cos(latRad) * cos(decl))
        let haAsr = acos(max(-1.0, min(1.0, cosAsr))) * 180.0 / .pi

        let fajrHour = (solarNoon - haFajr / 15.0).truncatingRemainder(dividingBy: 24.0)
        let dhuhrHour = (solarNoon + 5.0 / 60.0).truncatingRemainder(dividingBy: 24.0)
        let asrHour = (solarNoon + haAsr / 15.0).truncatingRemainder(dividingBy: 24.0)
        let maghribHour = (solarNoon + haSunset / 15.0 + 2.0 / 60.0).truncatingRemainder(dividingBy: 24.0)

        let ishaHour: Double
        if convention == .ummAlQura {
            // Umm Al-Qura uses a fixed 90-minute offset after Maghrib
            ishaHour = (maghribHour + 1.5).truncatingRemainder(dividingBy: 24.0)
        } else {
            let haIsha = hourAngle(alphaDeg: -convention.ishaAngle)
            ishaHour = (solarNoon + haIsha / 15.0).truncatingRemainder(dividingBy: 24.0)
        }

        func prayerComponents(hourVal: Double) -> (String, Int, Int, Double) {
            let positive = (hourVal + 24.0).truncatingRemainder(dividingBy: 24.0)
            let h = Int(positive)
            let m = Int((positive - Double(h)) * 60.0)
            return (String(format: "%02d.%02d", h, m), h, m, positive)
        }

        let now = Date()
        let isToday = calendar.isDateInToday(date)
        let currentDecimalHour = isToday
            ? Double(calendar.component(.hour, from: now)) + Double(calendar.component(.minute, from: now)) / 60.0
            : 12.0

        let fajr = prayerComponents(hourVal: fajrHour)
        let dhuhr = prayerComponents(hourVal: dhuhrHour)
        let asr = prayerComponents(hourVal: asrHour)
        let maghrib = prayerComponents(hourVal: maghribHour)
        let isha = prayerComponents(hourVal: ishaHour)

        let specs = [
            ("subuh", "الفجر", "Fajr", "Subuh", "✨", fajr.0, fajr.1, fajr.2, fajr.3, "sun.horizon.fill"),
            ("dzuhur", "الظهر", "Dhuhr", "Dzuhur", "☀️", dhuhr.0, dhuhr.1, dhuhr.2, dhuhr.3, "sun.max.fill"),
            ("ashar", "العصر", "Asr", "Ashar", "⛅", asr.0, asr.1, asr.2, asr.3, "sun.haze.fill"),
            ("maghrib", "المغرب", "Maghrib", "Maghrib", "🌅", maghrib.0, maghrib.1, maghrib.2, maghrib.3, "sunset.fill"),
            ("isya", "العشاء", "Isha", "Isya", "🌙", isha.0, isha.1, isha.2, isha.3, "moon.stars.fill")
        ]

        // Determine current prayer period and next prayer
        var currentIndex = 0
        var nextIndex = 0

        if currentDecimalHour < fajr.3 {
            // Before Fajr -> current is Isha from yesterday, next is Fajr
            currentIndex = 4
            nextIndex = 0
        } else if currentDecimalHour < dhuhr.3 {
            currentIndex = 0
            nextIndex = 1
        } else if currentDecimalHour < asr.3 {
            currentIndex = 1
            nextIndex = 2
        } else if currentDecimalHour < maghrib.3 {
            currentIndex = 2
            nextIndex = 3
        } else if currentDecimalHour < isha.3 {
            currentIndex = 3
            nextIndex = 4
        } else {
            currentIndex = 4
            nextIndex = 0
        }

        // Calculate time delta to next prayer
        let nextDecHour = specs[nextIndex].8
        var deltaHours = nextDecHour - currentDecimalHour
        if deltaHours < 0 { deltaHours += 24.0 }

        let remHours = Int(deltaHours)
        let remMinutes = Int((deltaHours - Double(remHours)) * 60.0)

        let nextPrayerName = specs[nextIndex].3
        let countdownSubtitle = remHours > 0
            ? "\(nextPrayerName) in \(remHours)h \(remMinutes)m"
            : "\(nextPrayerName) in \(remMinutes)m"
        let inCountdownBadge = remHours > 0
            ? "in \(remHours)h \(remMinutes)m"
            : "in \(remMinutes)m"

        var items: [PrayerTimeItem] = []
        for (i, s) in specs.enumerated() {
            let isCurrent = (i == currentIndex)
            let isNext = (i == nextIndex)
            items.append(PrayerTimeItem(
                id: s.0,
                nameArabic: s.1,
                nameEnglish: s.2,
                name: s.3,
                emoji: s.4,
                timeString: s.5,
                hour: s.6,
                minute: s.7,
                icon: s.9,
                isCurrent: isCurrent,
                isNext: isNext,
                countdownString: isNext ? inCountdownBadge : nil
            ))
        }

        // Dates
        let gregorianString: String
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMMM"
        let dayMonth = dayFormatter.string(from: date)

        if calendar.isDateInToday(date) {
            gregorianString = "Today, \(dayMonth)"
        } else if calendar.isDateInTomorrow(date) {
            gregorianString = "Tomorrow, \(dayMonth)"
        } else if calendar.isDateInYesterday(date) {
            gregorianString = "Yesterday, \(dayMonth)"
        } else {
            let fullFormatter = DateFormatter()
            fullFormatter.dateFormat = "EEEE, d MMMM"
            gregorianString = fullFormatter.string(from: date)
        }

        // Hijri date
        let hijriFormatter = DateFormatter()
        hijriFormatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        hijriFormatter.dateFormat = "d MMMM yyyy 'AH'"
        hijriFormatter.locale = Locale(identifier: "en_US")
        let hijriString = hijriFormatter.string(from: date)

        return PrayerTimesDayResult(
            date: date,
            gregorianDateString: gregorianString,
            hijriDateString: hijriString,
            prayers: items,
            currentPrayer: items[currentIndex],
            nextPrayer: items[nextIndex],
            countdownSubtitle: countdownSubtitle
        )
    }
}
