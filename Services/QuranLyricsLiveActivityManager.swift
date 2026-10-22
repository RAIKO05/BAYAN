import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Quran Lyrics Live Activity Manager
/// Manages starting, updating, and dismissing the Lock Screen & Dynamic Island Live Activity
/// that streams synchronized Arabic Quran verse text ("Lyrics") and translations.
public final class QuranLyricsLiveActivityManager {
    public static let shared = QuranLyricsLiveActivityManager()

    #if canImport(ActivityKit)
    private var currentActivity: Activity<QuranLyricsActivityAttributes>?
    #endif

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
        #if canImport(ActivityKit)
        guard isEnabled else {
            endActivity()
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("ℹ️ Live Activities are disabled in iOS Settings.")
            return
        }

        // 1. Synchronously format Ayah text with authentic medallion and next preview
        let currentArabic = QuranVerseText.formattedAyah(surahId: surah.id, ayahNumber: ayah, includeMedallion: true)

        var nextArabic = ""
        if ayah < surah.totalAyahs {
            let nextRaw = QuranVerseText.formattedAyah(surahId: surah.id, ayahNumber: ayah + 1, includeMedallion: false)
            // Limit preview to first 120 chars to guarantee lightweight payload
            nextArabic = nextRaw.count > 120 ? String(nextRaw.prefix(120)) + "..." : nextRaw
        }

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

        let content = ActivityContent(
            state: state,
            staleDate: nil,
            relevanceScore: 100.0
        )

        // 2. Request iOS background execution time so background transitions are never cut short by the kernel
        #if canImport(UIKit)
        var bgTaskId: UIBackgroundTaskIdentifier = .invalid
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "QuranLyricsAyahUpdate") {
            if bgTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskId)
                bgTaskId = .invalid
            }
        }
        #endif

        Task { @MainActor [weak self] in
            defer {
                #if canImport(UIKit)
                if bgTaskId != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTaskId)
                    bgTaskId = .invalid
                }
                #endif
            }

            // Check all active live activities for our attributes
            let runningActivities = Activity<QuranLyricsActivityAttributes>.activities
            if !runningActivities.isEmpty {
                for activity in runningActivities {
                    await activity.update(content)
                }
                self?.currentActivity = runningActivities.first
                print("🔄 [LiveActivity] Updated Lock Screen Lyrics to Surah \(surah.id) (\(surah.nameEnglish)) Ayah \(ayah)")
            } else {
                let attributes = QuranLyricsActivityAttributes(activityId: "surah_\(surah.id)")
                do {
                    let activity = try Activity<QuranLyricsActivityAttributes>.request(
                        attributes: attributes,
                        content: content,
                        pushType: nil
                    )
                    self?.currentActivity = activity
                    print("✅ [LiveActivity] Started Lock Screen Lyrics for Surah \(surah.id) (\(surah.nameEnglish)) Ayah \(ayah)")
                } catch {
                    print("⚠️ [LiveActivity] Request failed: \(error)")
                }
            }
        }
        #endif
    }

    // MARK: - Update Playback State (Pause / Resume)
    public func updatePlaybackState(isPlaying: Bool) {
        #if canImport(ActivityKit)
        let runningActivities = Activity<QuranLyricsActivityAttributes>.activities
        guard !runningActivities.isEmpty else { return }

        #if canImport(UIKit)
        var bgTaskId: UIBackgroundTaskIdentifier = .invalid
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "QuranLyricsStateUpdate") {
            if bgTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskId)
                bgTaskId = .invalid
            }
        }
        #endif

        Task { @MainActor in
            defer {
                #if canImport(UIKit)
                if bgTaskId != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTaskId)
                    bgTaskId = .invalid
                }
                #endif
            }

            for activity in runningActivities {
                var updatedState = activity.content.state
                updatedState.isPlaying = isPlaying
                let content = ActivityContent(
                    state: updatedState,
                    staleDate: nil,
                    relevanceScore: 100.0
                )
                await activity.update(content)
            }
            print("🔄 [LiveActivity] Playback state changed: isPlaying=\(isPlaying)")
        }
        #endif
    }

    // MARK: - End Activity
    public func endActivity() {
        #if canImport(ActivityKit)
        let runningActivities = Activity<QuranLyricsActivityAttributes>.activities
        self.currentActivity = nil
        guard !runningActivities.isEmpty else { return }

        #if canImport(UIKit)
        var bgTaskId: UIBackgroundTaskIdentifier = .invalid
        bgTaskId = UIApplication.shared.beginBackgroundTask(withName: "QuranLyricsEndActivity") {
            if bgTaskId != .invalid {
                UIApplication.shared.endBackgroundTask(bgTaskId)
                bgTaskId = .invalid
            }
        }
        #endif

        Task { @MainActor in
            defer {
                #if canImport(UIKit)
                if bgTaskId != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTaskId)
                    bgTaskId = .invalid
                }
                #endif
            }

            for activity in runningActivities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            print("🛑 [LiveActivity] Dismissed all active Quran Lyrics Live Activities.")
        }
        #endif
    }

    // MARK: - Test Preview on Lock Screen (Called from Settings)
    public func testPreviewActivity() {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

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

        let content = ActivityContent(
            state: state,
            staleDate: nil,
            relevanceScore: 100.0
        )

        Task { @MainActor [weak self] in
            let runningActivities = Activity<QuranLyricsActivityAttributes>.activities
            if !runningActivities.isEmpty {
                for activity in runningActivities {
                    await activity.update(content)
                }
                self?.currentActivity = runningActivities.first
            } else {
                do {
                    let activity = try Activity<QuranLyricsActivityAttributes>.request(
                        attributes: QuranLyricsActivityAttributes(activityId: "test_preview"),
                        content: content,
                        pushType: nil
                    )
                    self?.currentActivity = activity
                } catch {
                    print("⚠️ Failed test activity: \(error)")
                }
            }
        }
        #endif
    }
}
