import Foundation
#if canImport(ActivityKit)
import ActivityKit

// MARK: - Quran Lyrics Live Activity Manager
/// Manages starting, updating, and dismissing the Lock Screen & Dynamic Island Live Activity
/// that streams synchronized Arabic Quran verse text ("Lyrics") and translations.
public final class QuranLyricsLiveActivityManager {
    public static let shared = QuranLyricsLiveActivityManager()

    private var currentActivity: Activity<QuranLyricsActivityAttributes>?
    private let activityQueue = DispatchQueue(label: "tools.rea.bayan.liveactivity", qos: .userInitiated)

    private init() {}

    // MARK: - User Settings
    public var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "bayan_live_activity_enabled") as? Bool ?? true
    }

    public var displayMode: String {
        UserDefaults.standard.string(forKey: "bayan_live_activity_mode") ?? "lyrics"
    }

    // MARK: - Start or Update Activity
    public func startOrUpdate(
        surah: Surah,
        ayah: Int,
        reciter: Reciter,
        isPlaying: Bool = true
    ) {
        guard isEnabled else {
            endActivity()
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("ℹ️ Live Activities are disabled in iOS Settings.")
            return
        }

        activityQueue.async { [weak self] in
            guard let self = self else { return }

            // Extract Current Ayah Text & Medallion
            let currentArabic = QuranVerseText.formattedAyah(surahId: surah.id, ayahNumber: ayah, includeMedallion: true)

            // Extract Next Ayah Snippet (if available)
            var nextArabic = ""
            if ayah < surah.totalAyahs {
                let nextRaw = QuranVerseText.formattedAyah(surahId: surah.id, ayahNumber: ayah + 1, includeMedallion: false)
                // Limit preview to first 120 chars to guarantee lightweight payload
                nextArabic = nextRaw.count > 120 ? String(nextRaw.prefix(120)) + "..." : nextRaw
            }

            // Extract Translation
            let translation = QuranVerseText.translation(surahId: surah.id, ayahNumber: ayah)

            let state = QuranLyricsActivityAttributes.ContentState(
                surahId: surah.id,
                surahNameArabic: surah.nameArabic,
                surahNameEnglish: surah.nameEnglish,
                ayahNumber: ayah,
                totalAyahs: surah.totalAyahs,
                currentAyahArabic: currentArabic,
                nextAyahArabic: nextArabic,
                translationText: translation,
                reciterName: reciter.nameEnglish,
                isPlaying: isPlaying,
                displayMode: self.displayMode
            )

            if let existing = self.currentActivity {
                Task {
                    await existing.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(600)))
                }
            } else {
                let attributes = QuranLyricsActivityAttributes(activityId: "surah_\(surah.id)")
                do {
                    let activity = try Activity<QuranLyricsActivityAttributes>.request(
                        attributes: attributes,
                        content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(600)),
                        pushType: nil
                    )
                    self.currentActivity = activity
                    print("✅ Started Quran Lyrics Live Activity on Lock Screen for Surah \(surah.nameEnglish) Ayah \(ayah)")
                } catch {
                    print("⚠️ Failed to request Quran Lyrics Live Activity: \(error)")
                }
            }
        }
    }

    // MARK: - Update Playback State (Pause / Resume)
    public func updatePlaybackState(isPlaying: Bool) {
        guard let activity = currentActivity else { return }
        activityQueue.async {
            var updatedState = activity.content.state
            updatedState.isPlaying = isPlaying
            Task {
                await activity.update(ActivityContent(state: updatedState, staleDate: Date().addingTimeInterval(600)))
            }
        }
    }

    // MARK: - End Activity
    public func endActivity() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.currentActivity = nil
            print("🛑 Dismissed Quran Lyrics Live Activity.")
        }
    }

    // MARK: - Test Preview on Lock Screen (Called from Settings)
    public func testPreviewActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Test with sample Ayah from Surah At-Tawbah (matching user's screenshot)
        let sampleArabic = "إِلَّا تَنصُرُوهُ فَقَدْ نَصَرَهُ اللَّهُ إِذْ أَخْرَجَهُ الَّذِينَ كَفَرُوا ثَانِيَ اثْنَيْنِ إِذْ هُمَا فِي الْغَارِ ﴿٤٠﴾"
        let sampleNext = "إِذْ يَقُولُ لِصَاحِبِهِ لَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا فَأَنزَلَ اللَّهُ سَكِينَتَهُ..."
        let sampleTranslation = "If you do not aid him, Allah has already aided him when those who disbelieved had driven him out..."

        let state = QuranLyricsActivityAttributes.ContentState(
            surahId: 9,
            surahNameArabic: "التوبة",
            surahNameEnglish: "At-Tawbah",
            ayahNumber: 40,
            totalAyahs: 129,
            currentAyahArabic: sampleArabic,
            nextAyahArabic: sampleNext,
            translationText: sampleTranslation,
            reciterName: "Maher Al-Muaiqly",
            isPlaying: true,
            displayMode: displayMode
        )

        activityQueue.async { [weak self] in
            guard let self = self else { return }
            if let existing = self.currentActivity {
                Task {
                    await existing.update(ActivityContent(state: state, staleDate: Date().addingTimeInterval(600)))
                }
            } else {
                do {
                    let activity = try Activity<QuranLyricsActivityAttributes>.request(
                        attributes: QuranLyricsActivityAttributes(activityId: "test_preview"),
                        content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(600)),
                        pushType: nil
                    )
                    self.currentActivity = activity
                } catch {
                    print("⚠️ Failed test activity: \(error)")
                }
            }
        }
    }
}
#endif
