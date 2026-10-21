import Foundation
#if canImport(ActivityKit)
import ActivityKit

public final class PrayerLiveActivityManager {
    public static let shared = PrayerLiveActivityManager()

    private var currentActivity: Activity<PrayerActivityAttributes>?

    private init() {}

    public func startOrUpdatePrayerActivity(
        prayerNameArabic: String,
        prayerNameEnglish: String,
        prayerDate: Date,
        cityName: String,
        qiblaDegrees: Double,
        progress: Double
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("ℹ️ Live Activities are not enabled by the user.")
            return
        }

        let state = PrayerActivityAttributes.ContentState(
            prayerNameArabic: prayerNameArabic,
            prayerNameEnglish: prayerNameEnglish,
            prayerDate: prayerDate,
            cityName: cityName,
            qiblaDegrees: qiblaDegrees,
            progress: progress
        )

        if let existing = currentActivity {
            Task {
                await existing.update(ActivityContent(state: state, staleDate: prayerDate.addingTimeInterval(300)))
            }
        } else {
            let attributes = PrayerActivityAttributes(targetPrayerId: prayerNameEnglish.lowercased())
            do {
                let activity = try Activity<PrayerActivityAttributes>.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: prayerDate.addingTimeInterval(300)),
                    pushType: nil
                )
                self.currentActivity = activity
                print("✅ Started Prayer Live Activity on Dynamic Island & Lock Screen: \(prayerNameEnglish)")
            } catch {
                print("⚠️ Failed to request Prayer Live Activity: \(error)")
            }
        }
    }

    public func endPrayerActivity() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.currentActivity = nil
        }
    }
}
#endif
