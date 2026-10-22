import WidgetKit
import SwiftUI

@main
struct BayanWidgetBundle: WidgetBundle {
    var body: some Widget {
        // iOS 18+ Control Center & Lock Screen Quick Action
        if #available(iOS 18.0, *) {
            BayanControlWidget()
        }

        // Home Screen & Lock Screen Interactive Widgets
        BayanLastReadWidget()
        BayanPrayerTimesWidget()
        BayanAyahOfTheDayWidget()
        BayanIdentifyWidget()

        #if canImport(ActivityKit)
        // Dynamic Island & Lock Screen Live Activities
        BayanPrayerLiveActivity()
        BayanQuranLyricsLiveActivity()
        #endif
    }
}
