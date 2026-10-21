import Foundation

// MARK: - Prayer Time Model
public struct PrayerTimeItem: Identifiable, Sendable {
    public let id: String
    public let nameArabic: String
    public let nameEnglish: String
    public let timeString: String
    public let hour: Int
    public let minute: Int
    public let icon: String
    public let isNext: Bool

    public init(
        id: String,
        nameArabic: String,
        nameEnglish: String,
        timeString: String,
        hour: Int,
        minute: Int,
        icon: String,
        isNext: Bool = false
    ) {
        self.id = id
        self.nameArabic = nameArabic
        self.nameEnglish = nameEnglish
        self.timeString = timeString
        self.hour = hour
        self.minute = minute
        self.icon = icon
        self.isNext = isNext
    }
}
