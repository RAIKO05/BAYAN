import SwiftUI

public struct DiscoverFriendsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var socialService = BayanSocialService.shared
    @State private var searchQuery: String = ""
    @State private var showingAddCustomSheet = false
    @State private var newFriendName = ""
    @State private var newFriendHandle = ""

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    private var filteredFriends: [BayanFriend] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return socialService.friends
        } else {
            return socialService.friends.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.handle.localizedCaseInsensitiveContains(searchQuery) ||
                $0.currentSurahName.localizedCaseInsensitiveContains(searchQuery) ||
                $0.reciterName.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.11).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        // Search Bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search by name, handle or reciter...", text: $searchQuery)
                                .foregroundColor(.white)
                            if !searchQuery.isEmpty {
                                Button {
                                    searchQuery = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                        // Add Friend by Handle Quick Action
                        Button {
                            showingAddCustomSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(spotifyGreen.opacity(0.18))
                                        .frame(width: 42, height: 42)
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(spotifyGreen)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Add Friend by Username")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Invite a family member or study partner")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.55))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(12)
                            .background(Color(red: 0.12, green: 0.13, blue: 0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 18)
                        }

                        // List of Suggested & Community Companions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SUGGESTED COMPANIONS")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(1.0)
                                .padding(.horizontal, 22)
                                .padding(.top, 8)

                            VStack(spacing: 10) {
                                ForEach(filteredFriends) { friend in
                                    friendRow(friend: friend)
                                }
                            }
                            .padding(.horizontal, 18)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Discover Companions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(spotifyGreen)
                }
            }
            .alert("Add Friend", isPresented: $showingAddCustomSheet) {
                TextField("Friend Name", text: $newFriendName)
                TextField("@username", text: $newFriendHandle)
                Button("Add") {
                    if !newFriendName.isEmpty {
                        socialService.addFriend(name: newFriendName, handle: newFriendHandle)
                        newFriendName = ""
                        newFriendHandle = ""
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter the name and username handle of the companion you want to follow.")
            }
        }
    }

    private func friendRow(friend: BayanFriend) -> some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: friend.avatarColorHex).opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(friend.avatarEmoji)
                    .font(.system(size: 22))
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(friend.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    if friend.isOnline {
                        Circle()
                            .fill(spotifyGreen)
                            .frame(width: 6, height: 6)
                    }
                }

                Text(friend.handle)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(spotifyGreen.opacity(0.85))

                HStack(spacing: 4) {
                    Image(systemName: "headphones")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Surah \(friend.currentSurahName) • \(friend.reciterName)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Follow / Following Button
            Button {
                socialService.toggleFollow(friendId: friend.id)
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            } label: {
                Text(friend.isFollowing ? "Following" : "Follow")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(friend.isFollowing ? .white.opacity(0.8) : .black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(friend.isFollowing ? Color.white.opacity(0.12) : spotifyGreen)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(friend.isFollowing ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                    )
            }
        }
        .padding(12)
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
