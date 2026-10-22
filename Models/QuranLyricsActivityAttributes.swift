import Foundation
#if canImport(ActivityKit)
import ActivityKit

// MARK: - Quran Lyrics Live Activity Attributes
/// ActivityKit attributes for displaying synchronized Quran verse text ("Lyrics")
/// on the iOS Lock Screen and Dynamic Island during recitation playback.
public struct QuranLyricsActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var surahId: Int
        public var surahNameArabic: String
        public var surahNameEnglish: String
        public var ayahNumber: Int
        public var totalAyahs: Int
        public var currentAyahArabic: String
        public var nextAyahArabic: String
        public var translationText: String
        public var reciterName: String
        public var isPlaying: Bool
        public var displayMode: String // "lyrics", "lyricsAndTranslation", "translationOnly"

        public init(
            surahId: Int,
            surahNameArabic: String,
            surahNameEnglish: String,
            ayahNumber: Int,
            totalAyahs: Int,
            currentAyahArabic: String,
            nextAyahArabic: String = "",
            translationText: String = "",
            reciterName: String = "",
            isPlaying: Bool = true,
            displayMode: String = "lyrics"
        ) {
            self.surahId = surahId
            self.surahNameArabic = surahNameArabic
            self.surahNameEnglish = surahNameEnglish
            self.ayahNumber = ayahNumber
            self.totalAyahs = totalAyahs
            self.currentAyahArabic = currentAyahArabic
            self.nextAyahArabic = nextAyahArabic
            self.translationText = translationText
            self.reciterName = reciterName
            self.isPlaying = isPlaying
            self.displayMode = displayMode
        }
    }

    public var activityId: String

    public init(activityId: String = "bayan_quran_lyrics") {
        self.activityId = activityId
    }
}
#endif
