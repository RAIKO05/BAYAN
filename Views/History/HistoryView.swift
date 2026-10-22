import SwiftUI

// MARK: - Islamic Social Profile & Friends Listening Activity View ("You" Tab)
public struct HistoryView: View {
    @State private var socialService = BayanSocialService.shared
    @State private var authService = BayanAuthService.shared
    @State private var syncManager = QuranSyncManager.shared
    @State private var playerService = AudioPlayerService.shared
    @State private var bookmarkService = BookmarkService.shared
    @State private var khatmahService = KhatmahService.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var languageManager = AppLanguageManager.shared

    @State private var selectedTab: Int = 0
    @State private var selectedTafsirSurah: Surah? = nil
    @State private var selectedTafsirAyah: Int = 1

    // Sheets
    @State private var showingSignInSheet = false
    @State private var showingEditProfileSheet = false
    @State private var showingDiscoverFriendsSheet = false
    @State private var showingLanguageSheet = false
    @State private var showingThemeSheet = false
    @State private var showingCloudSyncSheet = false
    @State private var showingSupportSheet = false
    @State private var showingShareProfileSheet = false

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        // MARK: - 1. User Social Profile Hero Card
                        profileHeroCard

                        // MARK: - 2. Live Now Reciting Broadcast Card (if listening)
                        if playerService.isPlaying, let surah = playerService.currentSurah {
                            liveNowListeningCard(surah: surah)
                        }

                        // MARK: - 3. Segmented Profile Tabs
                        segmentedTabBar

                        // MARK: - 4. Tab Content
                        switch selectedTab {
                        case 0:
                            friendsActivityFeed
                        case 1:
                            myRecitationsFeed
                        case 2:
                            myBookmarksFeed
                        case 3:
                            khatmahStatsFeed
                        default:
                            friendsActivityFeed
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 120) // Clearance for floating tab bar
                    .frame(maxWidth: 780)
                }
            }
            .navigationTitle("Profile & Ummah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingLanguageSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(languageManager.currentLanguage.flagEmoji)
                            Text(languageManager.currentLanguage.rawValue.uppercased())
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(BayanTheme.goldSoft)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Discover & Add Friends
                    Button {
                        showingDiscoverFriendsSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(BayanTheme.goldSoft)
                    }

                    // Favorites / Support
                    Button {
                        showingSupportSheet = true
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(BayanTheme.goldSoft)
                    }

                    // iCloud Sync
                    Button {
                        showingCloudSyncSheet = true
                    } label: {
                        Image(systemName: "icloud.and.arrow.up")
                            .foregroundColor(BayanTheme.goldSoft)
                    }

                    // Theme Picker
                    Button {
                        showingThemeSheet = true
                    } label: {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(BayanTheme.goldSoft)
                    }
                }
            }
            .sheet(isPresented: $showingSignInSheet) {
                BayanSignInSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingEditProfileSheet) {
                EditProfileSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingDiscoverFriendsSheet) {
                DiscoverFriendsSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedTafsirSurah) { surah in
                AyahTafsirSheet(surah: surah, ayahNumber: selectedTafsirAyah)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingLanguageSheet) {
                LanguagePickerSheet()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingThemeSheet) {
                ThemePickerSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingCloudSyncSheet) {
                CloudSyncSheet()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showingSupportSheet) {
                SupportBayanSheet()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showingShareProfileSheet) {
                ShareSheetView(activityItems: [
                    "Follow me on Bayan (البيان) to listen to Holy Quran recitations together! Handle: \(socialService.profile.handle)"
                ])
            }
        }
    }

    // MARK: - 1. User Social Profile Hero Card
    private var profileHeroCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Profile Avatar with Online Ring
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: socialService.profile.avatarColorHex).opacity(0.35),
                                    Color(red: 0.05, green: 0.12, blue: 0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 76, height: 76)
                        .overlay(
                            Circle()
                                .stroke(BayanTheme.gold, lineWidth: 2)
                        )

                    Text(socialService.profile.avatarEmoji)
                        .font(.system(size: 38))

                    // Active Online/Broadcasting Indicator
                    if socialService.profile.isBroadcastingListening {
                        Circle()
                            .fill(spotifyGreen)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color(red: 0.08, green: 0.10, blue: 0.12), lineWidth: 2.5))
                            .offset(x: 26, y: 26)
                    }
                }
                .shadow(color: BayanTheme.gold.opacity(0.3), radius: 8)

                // Name, Handle & Verification
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text(socialService.profile.name)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                            .foregroundColor(BayanTheme.gold)
                    }

                    Text(socialService.profile.handle)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(spotifyGreen)

                    Text(socialService.profile.bio)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.70))
                        .lineLimit(2)
                        .padding(.top, 2)
                }

                Spacer()
            }

            // Stats Bar (Followers, Following, Khatmah, Streak)
            HStack(spacing: 0) {
                statItem(title: "Followers", value: "\(socialService.profile.followersCount)")
                Divider().frame(height: 24).background(Color.white.opacity(0.15))
                statItem(title: "Following", value: "\(socialService.profile.followingCount)")
                Divider().frame(height: 24).background(Color.white.opacity(0.15))
                statItem(title: "Khatmahs", value: "\(socialService.profile.khatmahsCompleted)")
                Divider().frame(height: 24).background(Color.white.opacity(0.15))
                statItem(title: "Streak", value: "🔥 \(socialService.profile.dailyStreak)d")
            }
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Account & Sign In Quick Section (Apple, Google/Gmail, Email)
            if authService.isSignedIn, let user = authService.currentUser {
                HStack(spacing: 8) {
                    Image(systemName: user.provider == .apple ? "apple.logo" : (user.provider == .google ? "globe" : "envelope.fill"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(spotifyGreen)

                    Text("\(user.provider.rawValue): \(user.email)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)

                    Spacer()

                    Button("Sign Out") {
                        authService.signOut()
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                HStack(spacing: 8) {
                    // Sign in with Apple
                    Button {
                        showingSignInSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 12, weight: .bold))
                            Text("Apple")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    // Sign in with Google / Gmail
                    Button {
                        showingSignInSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Text("G")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                            Text("Google")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }

                    // Sign in with Email
                    Button {
                        showingSignInSheet = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 11))
                            Text("Email")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }

            // Action Buttons: Edit Profile, Share, Discover
            HStack(spacing: 10) {
                Button {
                    showingEditProfileSheet = true
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Edit Profile")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button {
                    showingShareProfileSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button {
                    showingDiscoverFriendsSheet = true
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                        Text("Companions")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(spotifyGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.10, green: 0.12, blue: 0.14).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(BayanTheme.gold.opacity(0.25), lineWidth: 1)
        )
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 2. Live Now Reciting Broadcast Card
    private func liveNowListeningCard(surah: Surah) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(spotifyGreen.opacity(0.2))
                    .frame(width: 42, height: 42)

                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(spotifyGreen)
                    .symbolEffect(.variableColor.iterative.reversing, isActive: true)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Circle().fill(spotifyGreen).frame(width: 6, height: 6)
                    Text("YOU ARE RECITING LIVE")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(spotifyGreen)
                        .tracking(1.0)
                }

                Text("Surah \(surah.nameEnglish) • Ayah \(playerService.currentAyah)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("🗣️ \(playerService.currentReciter.nameEnglish)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(spotifyGreen.opacity(0.9))
                    .lineLimit(1)
            }

            Spacer()

            Text("Broadcasting")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(spotifyGreen)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(spotifyGreen.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.16, blue: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(spotifyGreen.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - 3. Segmented Profile Tabs
    private var segmentedTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                tabButton(title: "Companions (\(socialService.friends.count))", icon: "person.2.fill", tag: 0)
                tabButton(title: "Recitations (\(syncManager.recentRecognitions.count))", icon: "waveform", tag: 1)
                tabButton(title: "Bookmarks (\(bookmarkService.bookmarks.count))", icon: "bookmark.fill", tag: 2)
                tabButton(title: "Khatmah", icon: "book.closed.fill", tag: 3)
            }
            .padding(.horizontal, 2)
        }
    }

    private func tabButton(title: String, icon: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTab = tag
            }
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(selectedTab == tag ? .black : .white.opacity(0.75))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selectedTab == tag ? spotifyGreen : Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
    }

    // MARK: - 4. Tab 0: Friends Activity Feed (Spotify Style)
    private var friendsActivityFeed: some View {
        VStack(spacing: 14) {
            ForEach(socialService.friends) { friend in
                friendActivityCard(friend: friend)
            }
        }
    }

    private func friendActivityCard(friend: BayanFriend) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Friend Header: Avatar, Name, Handle, Time & Follow
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: friend.avatarColorHex).opacity(0.25))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().stroke(friend.isListeningNow ? spotifyGreen : Color.clear, lineWidth: 1.5)
                        )

                    Text(friend.avatarEmoji)
                        .font(.system(size: 22))

                    if friend.isListeningNow {
                        Circle()
                            .fill(spotifyGreen)
                            .frame(width: 10, height: 10)
                            .offset(x: 16, y: 16)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(friend.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)

                        if friend.isListeningNow {
                            HStack(spacing: 3) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 10, weight: .bold))
                                    .symbolEffect(.variableColor.iterative.reversing, isActive: true)
                                Text("Listening")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(spotifyGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(spotifyGreen.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 6) {
                        Text(friend.handle)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(spotifyGreen.opacity(0.85))

                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))

                        Text(friend.timeAgoText)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Follow Button
                Button {
                    socialService.toggleFollow(friendId: friend.id)
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Text(friend.isFollowing ? "Following" : "+ Follow")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(friend.isFollowing ? .white.opacity(0.7) : .black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(friend.isFollowing ? Color.white.opacity(0.1) : spotifyGreen)
                        .clipShape(Capsule())
                }
            }

            // Surah & Reciter Listening Box
            HStack(spacing: 12) {
                // Surah Number Emblem
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.16, blue: 0.14))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(BayanTheme.gold.opacity(0.3), lineWidth: 1)
                        )

                    VStack(spacing: 1) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 12))
                            .foregroundColor(BayanTheme.gold)
                        Text("\(friend.currentSurahId)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(BayanTheme.goldSoft)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Surah \(friend.currentSurahName) • Ayah \(friend.currentAyah)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(friend.currentSurahArabic)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(BayanTheme.goldSoft)
                    }

                    Text("🗣️ \(friend.reciterName)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(spotifyGreen)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Reflection Note / Du'a
            if !friend.reflectionNote.isEmpty {
                Text(friend.reflectionNote)
                    .font(.system(size: 12.5))
                    .foregroundColor(.white.opacity(0.85))
                    .italic()
                    .padding(.horizontal, 4)
            }

            // Bottom Actions: "Listen Along" & Reactions
            HStack(spacing: 8) {
                // 1-Tap "Listen Along" Button
                Button {
                    socialService.tuneInWithFriend(friend)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "headphones")
                            .font(.system(size: 12, weight: .bold))
                        Text("Listen Along")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(spotifyGreen)
                    .clipShape(Capsule())
                }

                Spacer()

                // Interactive Reactions: Dua, Sparkles, Heart
                reactionPill(friendId: friend.id, emoji: "🤲", count: friend.reactions["🤲"] ?? 0)
                reactionPill(friendId: friend.id, emoji: "✨", count: friend.reactions["✨"] ?? 0)
                reactionPill(friendId: friend.id, emoji: "❤️", count: friend.reactions["❤️"] ?? 0)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.11, green: 0.12, blue: 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(friend.isListeningNow ? spotifyGreen.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func reactionPill(friendId: String, emoji: String, count: Int) -> some View {
        Button {
            socialService.reactToActivity(friendId: friendId, emoji: emoji)
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            HStack(spacing: 3) {
                Text(emoji).font(.system(size: 12))
                Text("\(count)").font(.system(size: 11, weight: .semibold)).foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
    }

    // MARK: - Tab 1: My Recitations Feed
    private var myRecitationsFeed: some View {
        VStack(spacing: 12) {
            if syncManager.recentRecognitions.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "waveform.badge.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(BayanTheme.gold.opacity(0.4))
                        .padding(.top, 30)

                    Text("No Recitations Recorded Yet")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Recitations identified in the Identify tab will appear here in your personal listening journal.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                ForEach(syncManager.recentRecognitions) { item in
                    RecitationHistoryCard(
                        item: item,
                        onPlay: {
                            playerService.play(surah: item.surah, ayah: item.startAyah)
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        },
                        onTafsir: {
                            selectedTafsirSurah = item.surah
                            selectedTafsirAyah = item.startAyah
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                    )
                }
            }
        }
    }

    // MARK: - Tab 2: My Bookmarks Feed
    private var myBookmarksFeed: some View {
        VStack(spacing: 12) {
            if bookmarkService.bookmarks.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "bookmark.slash")
                        .font(.system(size: 48))
                        .foregroundColor(BayanTheme.gold.opacity(0.4))
                        .padding(.top, 30)

                    Text("No Bookmarks Saved Yet")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Tap the (+) button on any Ayah while listening to save it to your sacred bookmarks.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            } else {
                ForEach(bookmarkService.bookmarks) { bookmark in
                    BookmarkItemCard(
                        bookmark: bookmark,
                        onDelete: {
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                            bookmarkService.removeBookmark(id: bookmark.id)
                        },
                        onPlay: {
                            if let surah = QuranDataService.shared.surah(for: bookmark.surahId) {
                                playerService.play(surah: surah, ayah: bookmark.ayahNumber)
                            }
                        },
                        onTafsir: {
                            if let surah = QuranDataService.shared.surah(for: bookmark.surahId) {
                                selectedTafsirSurah = surah
                                selectedTafsirAyah = bookmark.ayahNumber
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Tab 3: Khatmah & Stats Feed
    private var khatmahStatsFeed: some View {
        VStack(spacing: 14) {
            // Khatmah Progress Card
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("QURAN KHATMAH PROGRESS")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(BayanTheme.gold)
                            .tracking(1.0)
                        Text("Page \(khatmahService.currentPage) of 604")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("\(khatmahService.currentPage * 100 / 604)%")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(spotifyGreen)
                }

                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(colors: [BayanTheme.gold, spotifyGreen], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(khatmahService.currentPage) / 604.0), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("Juz' \((khatmahService.currentPage - 1) / 20 + 1) of 30")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("Goal: \(khatmahService.targetDays) Days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(BayanTheme.goldSoft)
                }
            }
            .padding(18)
            .background(Color(red: 0.11, green: 0.12, blue: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BayanTheme.gold.opacity(0.25), lineWidth: 1)
            )

            // Top Reciters Ranking
            VStack(alignment: .leading, spacing: 12) {
                Text("MOST LISTENED RECITERS")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1.0)

                reciterRankingRow(rank: 1, name: "Mishary Rashid Alafasy", percent: "58%")
                reciterRankingRow(rank: 2, name: "Abdul Rahman Al-Sudais", percent: "24%")
                reciterRankingRow(rank: 3, name: "Saud Al-Shuraim", percent: "18%")
            }
            .padding(18)
            .background(Color(red: 0.11, green: 0.12, blue: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func reciterRankingRow(rank: Int, name: String, percent: String) -> some View {
        HStack(spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(rank == 1 ? BayanTheme.gold : .white.opacity(0.4))
                .frame(width: 24)

            Text("🗣️")
                .font(.system(size: 14))

            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Text(percent)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(spotifyGreen)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ShareSheet Helper
private struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Standalone Recitation History Card
private struct RecitationHistoryCard: View {
    let item: RecognitionResult
    let onPlay: () -> Void
    let onTafsir: () -> Void

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.surah.nameArabic)
                    .font(.title3.weight(.bold))
                    .foregroundColor(BayanTheme.goldSoft)
                Spacer()
                Text(item.recognizedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text("\(item.surah.nameEnglish) • Ayah \(item.startAyah)–\(item.endAyah)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            HStack(spacing: 4) {
                Text("🗣️").font(.caption)
                Text(item.reciter.nameEnglish).font(.caption).foregroundColor(spotifyGreen)
            }

            Text(item.arabicSnippet)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(6)

            HStack {
                Button(action: onPlay) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("Play Recitation")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(BayanTheme.gold)
                    .clipShape(Capsule())
                }

                Button(action: onTafsir) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                        Text("Tafsir")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(BayanTheme.goldSoft)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.11, green: 0.12, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BayanTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Standalone Bookmark Item Card
private struct BookmarkItemCard: View {
    let bookmark: AyahBookmark
    let onDelete: () -> Void
    let onPlay: () -> Void
    let onTafsir: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(bookmark.surahNameArabic)
                    .font(.title3.weight(.bold))
                    .foregroundColor(BayanTheme.goldSoft)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }

            Text("\(bookmark.surahNameEnglish) • Ayah \(bookmark.ayahNumber)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            Text(bookmark.arabicText)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(6)

            if !bookmark.translationText.isEmpty {
                Text(bookmark.translationText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            HStack {
                Button(action: onPlay) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(.caption.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(BayanTheme.gold)
                    .clipShape(Capsule())
                }

                Button(action: onTafsir) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                        Text("Tafsir")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(BayanTheme.goldSoft)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.11, green: 0.12, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BayanTheme.gold.opacity(0.2), lineWidth: 1)
        )
    }
}
