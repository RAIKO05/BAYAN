import Foundation
import SwiftUI

// MARK: - Bayan Social & Community Service
// Manages the user's social profile, followed friends, and live recitation activity
@Observable
public final class BayanSocialService {
    public static let shared = BayanSocialService()

    private let userDefaults = UserDefaults.standard
    private let kProfileStorageKey = "bayan_social_profile"
    private let kFriendsStorageKey = "bayan_social_friends"

    public var profile: UserProfile
    public var friends: [BayanFriend]

    public var followedFriends: [BayanFriend] {
        friends.filter { $0.isFollowing }
    }

    public var suggestedFriends: [BayanFriend] {
        friends.filter { !$0.isFollowing }
    }

    private init() {
        // Load Profile
        if let data = userDefaults.data(forKey: kProfileStorageKey),
           let savedProfile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = savedProfile
        } else {
            self.profile = UserProfile.standard
        }

        // Load Friends
        if let data = userDefaults.data(forKey: kFriendsStorageKey),
           let savedFriends = try? JSONDecoder().decode([BayanFriend].self, from: data) {
            self.friends = savedFriends
        } else {
            self.friends = BayanFriend.sampleCommunity
        }
    }

    // MARK: - Profile Actions
    public func updateProfile(
        name: String,
        handle: String,
        bio: String,
        avatarEmoji: String,
        isBroadcasting: Bool
    ) {
        profile.name = name
        profile.handle = handle.hasPrefix("@") ? handle : "@\(handle)"
        profile.bio = bio
        profile.avatarEmoji = avatarEmoji
        profile.isBroadcastingListening = isBroadcasting
        saveProfile()
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            userDefaults.set(data, forKey: kProfileStorageKey)
        }
    }

    // MARK: - Friend & Activity Actions
    public func toggleFollow(friendId: String) {
        if let index = friends.firstIndex(where: { $0.id == friendId }) {
            friends[index].isFollowing.toggle()
            if friends[index].isFollowing {
                profile.followingCount += 1
            } else {
                profile.followingCount = max(0, profile.followingCount - 1)
            }
            saveFriends()
            saveProfile()
        }
    }

    public func reactToActivity(friendId: String, emoji: String) {
        if let index = friends.firstIndex(where: { $0.id == friendId }) {
            var current = friends[index].reactions[emoji] ?? 0
            current += 1
            friends[index].reactions[emoji] = current
            saveFriends()
        }
    }

    public func tuneInWithFriend(_ friend: BayanFriend) {
        let dataService = QuranDataService.shared
        guard let surah = dataService.surah(for: friend.currentSurahId) else { return }

        // Find reciter
        let catalog = Reciter.standardCatalog
        let targetReciter = catalog.first(where: { $0.id == friend.reciterId }) ?? catalog[0]

        let player = AudioPlayerService.shared
        player.currentReciter = targetReciter
        player.play(surah: surah, ayah: friend.currentAyah)

        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    public func addFriend(name: String, handle: String, avatarEmoji: String = "✨") {
        let cleanHandle = handle.hasPrefix("@") ? handle : "@\(handle)"
        let newFriend = BayanFriend(
            id: UUID().uuidString,
            name: name,
            handle: cleanHandle,
            avatarEmoji: avatarEmoji,
            avatarColorHex: "#10b981",
            isOnline: true,
            isListeningNow: false,
            currentSurahId: 1,
            currentSurahName: "Al-Fatihah",
            currentSurahArabic: "الفاتحة",
            currentAyah: 1,
            reciterId: "alafasy",
            reciterName: "Mishary Rashid Alafasy",
            timeAgoText: "Recently joined",
            reflectionNote: "New companion on the journey of Quran ✨",
            isFollowing: true,
            reactions: ["🤲": 1, "✨": 2, "❤️": 1],
            khatmahProgressPercent: 5
        )
        friends.insert(newFriend, at: 0)
        profile.followingCount += 1
        saveFriends()
        saveProfile()
    }

    private func saveFriends() {
        if let data = try? JSONEncoder().encode(friends) {
            userDefaults.set(data, forKey: kFriendsStorageKey)
        }
    }
}
