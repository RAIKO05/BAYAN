import Foundation

public struct RecognitionResult: Identifiable, Codable, Hashable {
    public let id: UUID
    public let surah: Surah
    public let startAyah: Int
    public let endAyah: Int
    public let reciter: Reciter
    public let arabicSnippet: String
    public let translationSnippet: String
    public let confidence: Double
    public let recognizedAt: Date

    public init(
        id: UUID = UUID(),
        surah: Surah,
        startAyah: Int,
        endAyah: Int,
        reciter: Reciter,
        arabicSnippet: String,
        translationSnippet: String,
        confidence: Double,
        recognizedAt: Date = Date()
    ) {
        self.id = id
        self.surah = surah
        self.startAyah = startAyah
        self.endAyah = endAyah
        self.reciter = reciter
        self.arabicSnippet = arabicSnippet
        self.translationSnippet = translationSnippet
        self.confidence = confidence
        self.recognizedAt = recognizedAt
    }

    public static let sample = RecognitionResult(
        surah: Surah.sampleRahman,
        startAyah: 1,
        endAyah: 5,
        reciter: Reciter.standardCatalog[0],
        arabicSnippet: "ٱلرَّحْمَٰنُ ۝ عَلَّمَ ٱلْقُرْءَانَ ۝ خَلَقَ ٱلْإِنسَٰنَ ۝ عَلَّمَهُ ٱلْبَيَانَ",
        translationSnippet: "The Most Merciful. Taught the Qur'an. Created man, [and] taught him clear expression (Al-Bayan).",
        confidence: 0.98
    )
}
