import Foundation

// MARK: - Prayer Time Model
public struct PrayerTimeItem: Identifiable, Sendable {
    public let id: String
    public let nameArabic: String
    public let nameEnglish: String
    public let name: String
    public let emoji: String
    public let timeString: String
    public let hour: Int
    public let minute: Int
    public let icon: String
    public let isCurrent: Bool
    public let isNext: Bool
    public let countdownString: String?

    public init(
        id: String,
        nameArabic: String,
        nameEnglish: String,
        name: String? = nil,
        emoji: String? = nil,
        timeString: String,
        hour: Int,
        minute: Int,
        icon: String,
        isCurrent: Bool = false,
        isNext: Bool = false,
        countdownString: String? = nil
    ) {
        self.id = id
        self.nameArabic = nameArabic
        self.nameEnglish = nameEnglish
        self.name = name ?? nameEnglish
        self.emoji = emoji ?? "✨"
        self.timeString = timeString
        self.hour = hour
        self.minute = minute
        self.icon = icon
        self.isCurrent = isCurrent
        self.isNext = isNext
        self.countdownString = countdownString
    }
}
