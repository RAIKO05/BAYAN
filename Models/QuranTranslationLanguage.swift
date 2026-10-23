import Foundation

// MARK: - Supported Translation Languages for Read & Understand Mode
public enum QuranTranslationLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case arabicTafsir = "ar_tafsir"
    case french = "fr"
    case spanish = "es"
    case turkish = "tr"
    case indonesian = "id"
    case urdu = "ur"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .english: return "English"
        case .arabicTafsir: return "التفسير الميسر"
        case .french: return "Français"
        case .spanish: return "Español"
        case .turkish: return "Türkçe"
        case .indonesian: return "Bahasa Indonesia"
        case .urdu: return "اردو"
        }
    }

    public var subtitle: String {
        switch self {
        case .english: return "Sahih International"
        case .arabicTafsir: return "المختصر في التفسير"
        case .french: return "Muhammad Hamidullah"
        case .spanish: return "Muhammad Isa García"
        case .turkish: return "Diyanet İşleri Başkanlığı"
        case .indonesian: return "Kementerian Agama RI"
        case .urdu: return "فتح محمد جالندھری"
        }
    }

    public var flagEmoji: String {
        switch self {
        case .english: return "🇺🇸"
        case .arabicTafsir: return "🇸🇦"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .turkish: return "🇹🇷"
        case .indonesian: return "🇮🇩"
        case .urdu: return "🇵🇰"
        }
    }

    public var isRightToLeft: Bool {
        self == .arabicTafsir || self == .urdu
    }
}
