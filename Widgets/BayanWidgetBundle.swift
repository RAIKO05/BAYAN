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

        // Dynamic Island & Lock Screen Live Activity
        BayanPrayerLiveActivity()
    }
}
