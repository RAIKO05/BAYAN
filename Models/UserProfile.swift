import Foundation
import SwiftUI

// MARK: - Color Hex Extension
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 16, 185, 129)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - User Social Profile Model
public struct UserProfile: Codable, Equatable {
    public var name: String
    public var handle: String
    public var bio: String
    public var avatarEmoji: String
    public var avatarColorHex: String
    public var followersCount: Int
    public var followingCount: Int
    public var khatmahsCompleted: Int
    public var dailyStreak: Int
    public var isBroadcastingListening: Bool

    public static let standard = UserProfile(
        name: "Mouad Aka",
        handle: "@mouad_bayan",
        bio: "« وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا » • Seeking peace through the Holy Qur'an 🤲",
        avatarEmoji: "👑",
        avatarColorHex: "#10b981",
        followersCount: 142,
        followingCount: 38,
        khatmahsCompleted: 3,
        dailyStreak: 14,
        isBroadcastingListening: true
    )
}

// MARK: - Friend & Community Activity Model (Spotify-Style Friend Activity)
public struct BayanFriend: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public var handle: String
    public var avatarEmoji: String
    public var avatarColorHex: String
    public var isOnline: Bool
    public var isListeningNow: Bool
    public var currentSurahId: Int
    public var currentSurahName: String
    public var currentSurahArabic: String
    public var currentAyah: Int
    public var reciterId: String
    public var reciterName: String
    public var timeAgoText: String
    public var reflectionNote: String
    public var isFollowing: Bool
    public var reactions: [String: Int]
    public var khatmahProgressPercent: Int

    public init(
        id: String,
        name: String,
        handle: String,
        avatarEmoji: String,
        avatarColorHex: String,
        isOnline: Bool,
        isListeningNow: Bool,
        currentSurahId: Int,
        currentSurahName: String,
        currentSurahArabic: String,
        currentAyah: Int,
        reciterId: String,
        reciterName: String,
        timeAgoText: String,
        reflectionNote: String,
        isFollowing: Bool,
        reactions: [String: Int] = ["🤲": 12, "✨": 24, "❤️": 18],
        khatmahProgressPercent: Int = 45
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.avatarEmoji = avatarEmoji
        self.avatarColorHex = avatarColorHex
        self.isOnline = isOnline
        self.isListeningNow = isListeningNow
        self.currentSurahId = currentSurahId
        self.currentSurahName = currentSurahName
        self.currentSurahArabic = currentSurahArabic
        self.currentAyah = currentAyah
        self.reciterId = reciterId
        self.reciterName = reciterName
        self.timeAgoText = timeAgoText
        self.reflectionNote = reflectionNote
        self.isFollowing = isFollowing
        self.reactions = reactions
        self.khatmahProgressPercent = khatmahProgressPercent
    }

    public static let sampleCommunity: [BayanFriend] = [
        BayanFriend(
            id: "friend_1",
            name: "Dr. Omar Suleiman",
            handle: "@omarsuleiman",
            avatarEmoji: "🌙",
            avatarColorHex: "#d4af37",
            isOnline: true,
            isListeningNow: true,
            currentSurahId: 18,
            currentSurahName: "Al-Kahf",
            currentSurahArabic: "الكهف",
            currentAyah: 10,
            reciterId: "alafasy",
            reciterName: "Mishary Rashid Alafasy",
            timeAgoText: "Listening now",
            reflectionNote: "Reflecting on the youth of the cave. Friday blessings to all 🤲",
            isFollowing: true,
            reactions: ["🤲": 48, "✨": 92, "❤️": 64],
            khatmahProgressPercent: 78
        ),
        BayanFriend(
            id: "friend_2",
            name: "Zaid Al-Husseini",
            handle: "@zaid_quran",
            avatarEmoji: "🕋",
            avatarColorHex: "#10b981",
            isOnline: true,
            isListeningNow: true,
            currentSurahId: 55,
            currentSurahName: "Ar-Rahman",
            currentSurahArabic: "الرحمن",
            currentAyah: 13,
            reciterId: "sudais",
            reciterName: "Abdul Rahman Al-Sudais",
            timeAgoText: "Listening now",
            reflectionNote: "« فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ » • Soothing heart and soul ✨",
            isFollowing: true,
            reactions: ["🤲": 31, "✨": 45, "❤️": 29],
            khatmahProgressPercent: 52
        ),
        BayanFriend(
            id: "friend_3",
            name: "Amina Khalil",
            handle: "@amina_k",
            avatarEmoji: "📿",
            avatarColorHex: "#38bdf8",
            isOnline: true,
            isListeningNow: false,
            currentSurahId: 67,
            currentSurahName: "Al-Mulk",
            currentSurahArabic: "الملك",
            currentAyah: 1,
            reciterId: "dosari",
            reciterName: "Yasser Al-Dosari",
            timeAgoText: "14m ago",
            reflectionNote: "Night recitation protection before sleep. Beautiful Mujawwad style 🌙",
            isFollowing: true,
            reactions: ["🤲": 19, "✨": 38, "❤️": 14],
            khatmahProgressPercent: 91
        ),
        BayanFriend(
            id: "friend_4",
            name: "Hamza Yusuf",
            handle: "@hamzayusuf",
            avatarEmoji: "🦅",
            avatarColorHex: "#f59e0b",
            isOnline: false,
            isListeningNow: false,
            currentSurahId: 36,
            currentSurahName: "Ya-Sin",
            currentSurahArabic: "يس",
            currentAyah: 1,
            reciterId: "husary",
            reciterName: "Mahmoud Khalil Al-Husary",
            timeAgoText: "42m ago",
            reflectionNote: "Studying precision Tajweed rules with Shaykh Husary 📖",
            isFollowing: true,
            reactions: ["🤲": 54, "✨": 80, "❤️": 42],
            khatmahProgressPercent: 63
        ),
        BayanFriend(
            id: "friend_5",
            name: "Bilal Ansari",
            handle: "@bilal_a",
            avatarEmoji: "🕌",
            avatarColorHex: "#a855f7",
            isOnline: true,
            isListeningNow: false,
            currentSurahId: 50,
            currentSurahName: "Qaf",
            currentSurahArabic: "ق",
            currentAyah: 16,
            reciterId: "shuraim",
            reciterName: "Saud Al-Shuraim",
            timeAgoText: "1h ago",
            reflectionNote: "« وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ » • Deep contemplation 🤲",
            isFollowing: true,
            reactions: ["🤲": 22, "✨": 17, "❤️": 11],
            khatmahProgressPercent: 34
        ),
        BayanFriend(
            id: "friend_6",
            name: "Fatima Zahra",
            handle: "@fatima_z",
            avatarEmoji: "🕊️",
            avatarColorHex: "#ec4899",
            isOnline: false,
            isListeningNow: false,
            currentSurahId: 19,
            currentSurahName: "Maryam",
            currentSurahArabic: "مريم",
            currentAyah: 1,
            reciterId: "minshawi",
            reciterName: "Mohamed Siddiq El-Minshawi",
            timeAgoText: "3h ago",
            reflectionNote: "Emotional recitation of Surah Maryam in Cairo teacher style ✨",
            isFollowing: false,
            reactions: ["🤲": 15, "✨": 27, "❤️": 19],
            khatmahProgressPercent: 40
        )
    ]
}
