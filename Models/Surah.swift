import Foundation

public struct Surah: Identifiable, Codable, Hashable {
    public let id: Int
    public let nameArabic: String
    public let nameEnglish: String
    public let nameTranslation: String
    public let revelationType: RevelationType
    public let totalAyahs: Int
    public let startPage: Int

    public enum RevelationType: String, Codable, Hashable {
        case meccan = "Meccan"
        case medinan = "Medinan"

        public var arabicTitle: String {
            switch self {
            case .meccan: return "مكية"
            case .medinan: return "مدنية"
            }
        }
    }

    public static let sampleFatihah = Surah(
        id: 1,
        nameArabic: "الفاتحة",
        nameEnglish: "Al-Fatihah",
        nameTranslation: "The Opening",
        revelationType: .meccan,
        totalAyahs: 7,
        startPage: 1
    )

    public static let sampleBaqarah = Surah(
        id: 2,
        nameArabic: "البقرة",
        nameEnglish: "Al-Baqarah",
        nameTranslation: "The Cow",
        revelationType: .medinan,
        totalAyahs: 286,
        startPage: 2
    )

    public static let sampleKahf = Surah(
        id: 18,
        nameArabic: "الكهف",
        nameEnglish: "Al-Kahf",
        nameTranslation: "The Cave",
        revelationType: .meccan,
        totalAyahs: 110,
        startPage: 293
    )

    public static let sampleRahman = Surah(
        id: 55,
        nameArabic: "الرحمن",
        nameEnglish: "Ar-Rahman",
        nameTranslation: "The Beneficent",
        revelationType: .medinan,
        totalAyahs: 78,
        startPage: 531
    )

    public static let sampleMulk = Surah(
        id: 67,
        nameArabic: "الملك",
        nameEnglish: "Al-Mulk",
        nameTranslation: "The Sovereignty",
        revelationType: .meccan,
        totalAyahs: 30,
        startPage: 562
    )
}
