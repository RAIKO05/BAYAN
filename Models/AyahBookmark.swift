import Foundation

// MARK: - Ayah Bookmark Model
public struct AyahBookmark: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let surahId: Int
    public let ayahNumber: Int
    public let surahNameArabic: String
    public let surahNameEnglish: String
    public let arabicText: String
    public let translationText: String
    public let dateAdded: Date

    public init(
        id: UUID = UUID(),
        surahId: Int,
        ayahNumber: Int,
        surahNameArabic: String,
        surahNameEnglish: String,
        arabicText: String,
        translationText: String,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.surahId = surahId
        self.ayahNumber = ayahNumber
        self.surahNameArabic = surahNameArabic
        self.surahNameEnglish = surahNameEnglish
        self.arabicText = arabicText
        self.translationText = translationText
        self.dateAdded = dateAdded
    }
}
