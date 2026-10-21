import Foundation

public struct DhikrItem: Identifiable, Codable, Hashable {
    public let id: String
    public let category: DhikrCategory
    public let arabicText: String
    public let transliteration: String
    public let translation: String
    public let targetCount: Int
    public let reference: String
    public let virtue: String

    public init(
        id: String,
        category: DhikrCategory,
        arabicText: String,
        transliteration: String,
        translation: String,
        targetCount: Int,
        reference: String,
        virtue: String
    ) {
        self.id = id
        self.category = category
        self.arabicText = arabicText
        self.transliteration = transliteration
        self.translation = translation
        self.targetCount = targetCount
        self.reference = reference
        self.virtue = virtue
    }
}

public enum DhikrCategory: String, Codable, CaseIterable, Identifiable {
    case morning = "morning"
    case evening = "evening"
    case sleep = "sleep"
    case waking = "waking"
    case postPrayer = "post_prayer"
    case quranic = "quranic"
    case protection = "protection"

    public var id: String { rawValue }

    public var titleArabic: String {
        switch self {
        case .morning: return "أذكار الصباح"
        case .evening: return "أذكار المساء"
        case .sleep: return "أذكار النوم"
        case .waking: return "أذكار الاستيقاظ"
        case .postPrayer: return "أذكار بعد الصلاة"
        case .quranic: return "أدعية قرآنية"
        case .protection: return "أدعية الحفظ والشفاء"
        }
    }

    public var titleEnglish: String {
        switch self {
        case .morning: return "Morning Adhkar"
        case .evening: return "Evening Adhkar"
        case .sleep: return "Before Sleep"
        case .waking: return "Upon Waking"
        case .postPrayer: return "Post-Prayer Adhkar"
        case .quranic: return "Quranic Duas"
        case .protection: return "Protection & Ruqyah"
        }
    }

    public var iconName: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .sleep: return "bed.double.fill"
        case .waking: return "sunrise.fill"
        case .postPrayer: return "hands.and.sparkles.fill"
        case .quranic: return "book.closed.fill"
        case .protection: return "shield.lefthalf.filled"
        }
    }
}
