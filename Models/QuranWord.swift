import Foundation

// MARK: - Quran Word Model
/// Represents an individual word within a Quranic verse with its Arabic text,
/// transliteration, English translation, morphological classification, and root.
public struct QuranWord: Identifiable, Hashable, Sendable {
    public let id: String // "\(surahId):\(ayahNumber):\(wordIndex)"
    public let surahId: Int
    public let ayahNumber: Int
    public let wordIndex: Int
    public let arabic: String
    public let transliteration: String
    public let translation: String
    public let grammarRole: String?
    public let rootLetters: String?

    public init(
        surahId: Int,
        ayahNumber: Int,
        wordIndex: Int,
        arabic: String,
        transliteration: String,
        translation: String,
        grammarRole: String? = nil,
        rootLetters: String? = nil
    ) {
        self.id = "\(surahId):\(ayahNumber):\(wordIndex)"
        self.surahId = surahId
        self.ayahNumber = ayahNumber
        self.wordIndex = wordIndex
        self.arabic = arabic
        self.transliteration = transliteration
        self.translation = translation
        self.grammarRole = grammarRole
        self.rootLetters = rootLetters
    }
}
