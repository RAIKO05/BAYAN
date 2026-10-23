import Foundation

// MARK: - Islamic Lunar Phase
public enum LunarPhase: String, CaseIterable, Sendable {
    case newMoon = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter = "First Quarter"
    case waxingGibbous = "Waxing Gibbous"
    case fullMoon = "Full Moon"
    case waningGibbous = "Waning Gibbous"
    case lastQuarter = "Last Quarter"
    case waningCrescent = "Waning Crescent"

    public var nameArabic: String {
        switch self {
        case .newMoon: return "المحاق"
        case .waxingCrescent: return "هلال متزايد"
        case .firstQuarter: return "التربيع الأول"
        case .waxingGibbous: return "أحدب متزايد"
        case .fullMoon: return "البدر"
        case .waningGibbous: return "أحدب متناقص"
        case .lastQuarter: return "التربيع الأخير"
        case .waningCrescent: return "هلال متناقص"
        }
    }

    public var icon: String {
        switch self {
        case .newMoon: return "moonphase.new.moon"
        case .waxingCrescent: return "moonphase.waxing.crescent"
        case .firstQuarter: return "moonphase.first.quarter"
        case .waxingGibbous: return "moonphase.waxing.gibbous"
        case .fullMoon: return "moonphase.full.moon"
        case .waningGibbous: return "moonphase.waning.gibbous"
        case .lastQuarter: return "moonphase.last.quarter"
        case .waningCrescent: return "moonphase.waning.crescent"
        }
    }
}

// MARK: - Islamic Fasting Type
public enum IslamicFastingType: String, CaseIterable, Sendable {
    case none = "None"
    case fardRamadan = "Fard Ramadan"
    case sunnahMonday = "Sunnah Monday"
    case sunnahThursday = "Sunnah Thursday"
    case whiteDay = "White Day (Ayyam al-Beed)"
    case arafah = "Day of Arafah"
    case ashura = "Day of Ashura"
    case tasua = "Day of Tasu'a"
    case shawwalSix = "Six Days of Shawwal"
    case prohibited = "Prohibited Fasting Day"

    public var isRecommendedFast: Bool {
        switch self {
        case .fardRamadan, .sunnahMonday, .sunnahThursday, .whiteDay, .arafah, .ashura, .tasua, .shawwalSix:
            return true
        case .none, .prohibited:
            return false
        }
    }

    public var titleArabic: String {
        switch self {
        case .none: return ""
        case .fardRamadan: return "صيام فريضة رمضان"
        case .sunnahMonday: return "سنة الإثنين"
        case .sunnahThursday: return "سنة الخميس"
        case .whiteDay: return "الأيام البيض (١٣، ١٤، ١٥)"
        case .arafah: return "يوم عرفة"
        case .ashura: return "يوم عاشوراء"
        case .tasua: return "يوم تاسوعاء"
        case .shawwalSix: return "الست من شوال"
        case .prohibited: return "يوم يحرم صومه"
        }
    }

    public var titleEnglish: String {
        switch self {
        case .none: return ""
        case .fardRamadan: return "Ramadan Obligatory Fast"
        case .sunnahMonday: return "Sunnah Monday Fast"
        case .sunnahThursday: return "Sunnah Thursday Fast"
        case .whiteDay: return "White Days (13, 14, 15)"
        case .arafah: return "Day of Arafah"
        case .ashura: return "Day of Ashura"
        case .tasua: return "Day of Tasu'a"
        case .shawwalSix: return "6 Days of Shawwal"
        case .prohibited: return "Prohibited Fasting Day (Eid)"
        }
    }

    public var hadithVirtue: String? {
        switch self {
        case .sunnahMonday, .sunnahThursday:
            return "تُعْرَضُ الأَعْمَالُ يَوْمَ الاِثْنَيْنِ وَالْخَمِيسِ فَأُحِبُّ أَنْ يُعْرَضَ عَمَلِي وَأَنَا صَائِمٌ (رواه الترمذي)"
        case .whiteDay:
            return "صُمْ مِنْ كُلِّ شَهْرٍ ثَلاَثَةَ أَيَّامٍ، فَإِنَّ ذَلِكَ صِيَامُ الدَّهْرِ كُلِّهِ (متفق عليه)"
        case .arafah:
            return "صِيَامُ يَوْمِ عَرَفَةَ أَحْتَسِبُ عَلَى اللَّهِ أَنْ يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ وَالسَّنَةَ الَّتِي بَعْدَهُ (رواه مسلم)"
        case .ashura:
            return "صِيَامُ يَوْمِ عَاشُورَاءَ أَحْتَسِبُ عَلَى اللَّهِ أَنْ يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ (رواه مسلم)"
        case .tasua:
            return "لَئِنْ بَقِيتُ إِلَى قَابِلٍ لأَصُومَنَّ التَّاسِعَ (رواه مسلم)"
        case .shawwalSix:
            return "مَنْ صَامَ رَمَضَانَ ثُمَّ أَتْبَعَهُ سِتًّا مِنْ شَوَّالٍ كَانَ كَصِيَامِ الدَّهْرِ (رواه مسلم)"
        case .fardRamadan:
            return "يَا أَيُّهَا الَّذِينَ آمَنُوا كُتِبَ عَلَيْكُمُ الصِّيَامُ كَمَا كُتِبَ عَلَى الَّذِينَ مِنْ قَبْلِكُمْ لَعَلَّكُمْ تَتَّقُونَ"
        case .prohibited:
            return "نَهَى رَسُولُ اللَّهِ ﷺ عَنْ صِيَامِ يَوْمَيْنِ: يَوْمِ الْفِطْرِ وَيَوْمِ النَّحْرِ"
        case .none:
            return nil
        }
    }
}

// MARK: - Hijri Day Model
public struct HijriDay: Identifiable, Hashable, Sendable {
    public var id: String { "\(hijriYear)-\(hijriMonth)-\(hijriDay)" }
    public let date: Date
    public let hijriYear: Int
    public let hijriMonth: Int
    public let hijriDay: Int
    public let monthNameArabic: String
    public let monthNameEnglish: String
    public let isSacredMonth: Bool
    public let isToday: Bool
    public let lunarPhase: LunarPhase
    public let lunarIlluminationPercent: Int
    public let fastingType: IslamicFastingType
    public let islamicEvent: String?

    public init(
        date: Date,
        hijriYear: Int,
        hijriMonth: Int,
        hijriDay: Int,
        monthNameArabic: String,
        monthNameEnglish: String,
        isSacredMonth: Bool,
        isToday: Bool,
        lunarPhase: LunarPhase,
        lunarIlluminationPercent: Int,
        fastingType: IslamicFastingType,
        islamicEvent: String? = nil
    ) {
        self.date = date
        self.hijriYear = hijriYear
        self.hijriMonth = hijriMonth
        self.hijriDay = hijriDay
        self.monthNameArabic = monthNameArabic
        self.monthNameEnglish = monthNameEnglish
        self.isSacredMonth = isSacredMonth
        self.isToday = isToday
        self.lunarPhase = lunarPhase
        self.lunarIlluminationPercent = lunarIlluminationPercent
        self.fastingType = fastingType
        self.islamicEvent = islamicEvent
    }

    public var formattedHijriArabic: String {
        "\(hijriDay) \(monthNameArabic) \(hijriYear) هـ"
    }

    public var formattedHijriEnglish: String {
        "\(hijriDay) \(monthNameEnglish) \(hijriYear) AH"
    }
}
