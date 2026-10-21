import Foundation
#if canImport(ActivityKit)
import ActivityKit

public struct PrayerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var prayerNameArabic: String
        public var prayerNameEnglish: String
        public var prayerDate: Date
        public var cityName: String
        public var qiblaDegrees: Double
        public var progress: Double // 0.0 to 1.0

        public init(
            prayerNameArabic: String,
            prayerNameEnglish: String,
            prayerDate: Date,
            cityName: String,
            qiblaDegrees: Double,
            progress: Double
        ) {
            self.prayerNameArabic = prayerNameArabic
            self.prayerNameEnglish = prayerNameEnglish
            self.prayerDate = prayerDate
            self.cityName = cityName
            self.qiblaDegrees = qiblaDegrees
            self.progress = progress
        }
    }

    public var targetPrayerId: String

    public init(targetPrayerId: String) {
        self.targetPrayerId = targetPrayerId
    }
}
#endif
