import SwiftUI

// MARK: - Minimalist Personal Quran Hub ("You" Tab)
/// High-efficiency personal sanctuary displaying real user metrics, sacred bookmarks,
/// local offline audio storage manager, reading history, and direct working settings.
public struct HistoryView: View {
    @State private var syncManager = QuranSyncManager.shared
    @State private var playerService = AudioPlayerService.shared
    @State private var bookmarkService = BookmarkService.shared
    @State private var khatmahService = KhatmahService.shared
    @State private var downloadService = QuranAudioDownloadService.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var languageManager = AppLanguageManager.shared
    @State private var authService = BayanAuthService.shared
    @State private var socialService = BayanSocialService.shared

    // Segmented tab: 0: Bookmarks, 1: Offline Audio, 2: History
    @State private var selectedTab: Int = 0

    // Sheets
    @State private var showingSettingsSheet = false
    @State private var showingEditProfileSheet = false
    @State private var showingLanguageSheet = false
    @State private var showingKhatmahPlanner = false
    @State private var showingLiveActivitySettings = false
    @State private var showingThemeSheet = false
    @State private var showingClearCacheAlert = false
    @State private var showingClearHistoryAlert = false
    @State private var selectedTafsirSurah: Surah? = nil
    @State private var selectedTafsirAyah: Int = 1

    @AppStorage("bayan_live_activity_enabled") private var isLiveActivityEnabled: Bool = true

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: - 1. Minimalist User Identity & Quick Settings Header
                        userHeaderCard

                        // MARK: - 2. Continue Reading / Listening (1-Tap Resume)
                        continueReadingCard

                        // MARK: - 3. Authentic Quran Engagement Metrics (4 Real KPIs)
                        realStatsBar

                        // MARK: - 4. Khatmah Quran Goal Tracker
                        khatmahTrackerCard

                        // MARK: - 5. Segmented Personal Tabs
                        segmentedTabBar

                        // MARK: - 6. Tab Content (Bookmarks / Offline Audio / History)
                        Group {
                            switch selectedTab {
                            case 0:
                                bookmarksFeed
                            case 1:
                                offlineAudioFeed
                            case 2:
                                recitationsHistoryFeed
                            default:
                                bookmarksFeed
                            }
                        }

                        // MARK: - 7. Working Settings Quick Access Bar
                        quickSettingsBar
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 120) // Clearance for floating tab bar & mini-player
                    .frame(maxWidth: 780)
                }
            }
            .navigationTitle("You")
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
                    // Direct Working Settings Button
                    Button {
                        showingSettingsSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(BayanTheme.goldSoft)
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                BayanSettingsSheet()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showingEditProfileSheet) {
                EditProfileSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingLanguageSheet) {
                LanguagePickerSheet()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingKhatmahPlanner) {
                KhatmahPlannerView()
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showingLiveActivitySettings) {
                NavigationStack {
                    BayanLiveActivitySettingsView()
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingThemeSheet) {
                ThemePickerSheet()
                    .presentationDetents([.medium])
            }
            .sheet(item: $selectedTafsirSurah) { surah in
                AyahTafsirSheet(surah: surah, ayahNumber: selectedTafsirAyah)
                    .presentationDetents([.medium, .large])
            }
            .alert("Clear Audio Cache", isPresented: $showingClearCacheAlert) {
                Button("Delete All Audio", role: .destructive) {
                    downloadService.clearAllAudioCache()
                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all downloaded offline recitations from your device storage to free up space. You can re-download them anytime.")
            }
            .alert("Clear Recitation History", isPresented: $showingClearHistoryAlert) {
                Button("Clear", role: .destructive) {
                    syncManager.clearRecognitionHistory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to clear your Quran recitation history journal?")
            }
        }
    }

    // MARK: - 1. Minimalist User Identity & Quick Settings Header
    private var userHeaderCard: some View {
        HStack(spacing: 14) {
            // Minimalist Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: socialService.profile.avatarColorHex).opacity(0.4), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .overlay(Circle().stroke(BayanTheme.gold.opacity(0.6), lineWidth: 1.5))

                Text(socialService.profile.avatarEmoji)
                    .font(.system(size: 26))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(socialService.profile.name.isEmpty ? "Quran Companion" : socialService.profile.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 13))
                        .foregroundColor(BayanTheme.gold)
                }

                HStack(spacing: 6) {
                    Text(socialService.profile.handle)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(spotifyGreen)

                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))

                    HStack(spacing: 3) {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 10))
                        Text("Synced")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(BayanTheme.goldSoft.opacity(0.85))
                }
            }

            Spacer()

            // Working Settings & Edit Profile Buttons
            HStack(spacing: 8) {
                Button {
                    showingEditProfileSheet = true
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }

                Button {
                    showingSettingsSheet = true
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(BayanTheme.gold)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BayanTheme.gold.opacity(0.2), lineWidth: 1)
        )
        .onLongPressGesture(minimumDuration: 0.4) {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            showingSettingsSheet = true
        }
    }

    // MARK: - 2. Continue Reading / Listening (1-Tap Resume)
    private var continueReadingCard: some View {
        let lastSurah = QuranDataService.shared.surah(for: syncManager.lastSurahId) ?? QuranDataService.shared.allSurahs[1] // Surah Al-Baqarah
        let lastAyah = syncManager.lastAyahId

        return HStack(spacing: 12) {
            // Quran Emblem
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.14, blue: 0.11))
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(BayanTheme.gold.opacity(0.35), lineWidth: 1)
                    )

                Image(systemName: "book.pages.fill")
                    .font(.system(size: 20))
                    .foregroundColor(BayanTheme.gold)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Circle().fill(spotifyGreen).frame(width: 6, height: 6)
                    Text("CONTINUE WHERE YOU LEFT OFF")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(spotifyGreen)
                        .tracking(0.8)
                }

                HStack {
                    Text("Surah \(lastSurah.nameEnglish) • Ayah \(lastAyah)")
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(lastSurah.nameArabic)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(BayanTheme.goldSoft)
                }

                Text("Page \(syncManager.lastPageNumber) • \(syncManager.lastQariId.capitalized)")
                    .font(.system(size: 11.5))
                    .foregroundColor(.white.opacity(0.55))
            }

            // Quick Play Button
            Button {
                playerService.play(surah: lastSurah, ayah: lastAyah)
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(BayanTheme.gold)
                    .clipShape(Circle())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.12, blue: 0.10).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(spotifyGreen.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - 3. Authentic Quran Engagement Metrics (4 Real KPIs)
    private var realStatsBar: some View {
        HStack(spacing: 8) {
            statMetricCard(
                title: "Khatmah",
                value: khatmahService.progressPercentString,
                subtitle: "p. \(khatmahService.currentPage)/604",
                icon: "chart.pie.fill",
                accentColor: spotifyGreen
            ) {
                showingKhatmahPlanner = true
            }

            statMetricCard(
                title: "Bookmarks",
                value: "\(bookmarkService.bookmarks.count)",
                subtitle: "Verses Saved",
                icon: "bookmark.fill",
                accentColor: BayanTheme.goldSoft
            ) {
                withAnimation { selectedTab = 0 }
            }

            statMetricCard(
                title: "Storage",
                value: downloadService.formattedStorageSize(),
                subtitle: "Offline Audio",
                icon: "internaldrive.fill",
                accentColor: Color(red: 0.45, green: 0.75, blue: 1.0)
            ) {
                withAnimation { selectedTab = 1 }
            }

            statMetricCard(
                title: "Journal",
                value: "\(syncManager.recentRecognitions.count)",
                subtitle: "Recitations",
                icon: "waveform",
                accentColor: Color(red: 0.95, green: 0.65, blue: 0.35)
            ) {
                withAnimation { selectedTab = 2 }
            }
        }
    }

    private func statMetricCard(
        title: String,
        value: String,
        subtitle: String,
        icon: String,
        accentColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                    Spacer()
                }

                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Khatmah Quran Goal Tracker
    private var khatmahTrackerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HOLY QURAN KHATMAH PACE")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(BayanTheme.gold)
                        .tracking(0.8)
                    Text("Juz' \(khatmahService.currentJuz) of 30 • Page \(khatmahService.currentPage) of 604")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Button {
                    khatmahService.incrementPage()
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("1 Page")
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(spotifyGreen)
                    .clipShape(Capsule())
                }
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 7)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [BayanTheme.gold, spotifyGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * CGFloat(khatmahService.progressFraction)), height: 7)
                }
            }
            .frame(height: 7)

            HStack {
                Text("\(khatmahService.pagesRemaining) pages remaining")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                Button {
                    showingKhatmahPlanner = true
                } label: {
                    HStack(spacing: 3) {
                        Text("Pace Planner")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(BayanTheme.goldSoft)
                }
            }
        }
        .padding(14)
        .background(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 5. Segmented Personal Tabs
    private var segmentedTabBar: some View {
        HStack(spacing: 6) {
            tabButton(
                title: "Bookmarks",
                badge: "\(bookmarkService.bookmarks.count)",
                icon: "bookmark.fill",
                tag: 0
            )

            tabButton(
                title: "Offline Storage",
                badge: downloadService.formattedStorageSize(),
                icon: "internaldrive.fill",
                tag: 1
            )

            tabButton(
                title: "Journal",
                badge: "\(syncManager.recentRecognitions.count)",
                icon: "waveform",
                tag: 2
            )
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func tabButton(title: String, badge: String, icon: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedTab = tag
            }
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))

                Text(title)
                    .font(.system(size: 12, weight: .bold))

                Text("(\(badge))")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .opacity(0.7)
            }
            .foregroundColor(selectedTab == tag ? .black : .white.opacity(0.75))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selectedTab == tag ? BayanTheme.gold : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - 6A. Tab 0: Sacred Bookmarks Feed
    private var bookmarksFeed: some View {
        VStack(spacing: 12) {
            if bookmarkService.bookmarks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 38))
                        .foregroundColor(BayanTheme.gold.opacity(0.35))
                        .padding(.top, 24)

                    Text("No Bookmarks Yet")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Text("Tap the bookmark icon on any verse while reading or listening in the Mushaf to save it here.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(bookmarkService.bookmarks) { bookmark in
                    bookmarkCard(bookmark: bookmark)
                }
            }
        }
    }

    private func bookmarkCard(bookmark: AyahBookmark) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(bookmark.surahNameArabic)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(BayanTheme.goldSoft)

                Text("• Ayah \(bookmark.ayahNumber)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Button {
                    bookmarkService.removeBookmark(id: bookmark.id)
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(6)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }

            Text("Surah \(bookmark.surahNameEnglish)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            Text(bookmark.arabicText)
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(5)

            if !bookmark.translationText.isEmpty {
                Text(bookmark.translationText)
                    .font(.system(size: 11.5))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                Button {
                    if let surah = QuranDataService.shared.surah(for: bookmark.surahId) {
                        playerService.play(surah: surah, ayah: bookmark.ayahNumber)
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BayanTheme.gold)
                    .clipShape(Capsule())
                }

                Button {
                    if let surah = QuranDataService.shared.surah(for: bookmark.surahId) {
                        selectedTafsirSurah = surah
                        selectedTafsirAyah = bookmark.ayahNumber
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                        Text("Tafsir")
                    }
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(BayanTheme.goldSoft)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }

                Spacer()
            }
        }
        .padding(14)
        .background(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(BayanTheme.gold.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - 6B. Tab 1: Offline Audio & Storage Manager Feed
    private var offlineAudioFeed: some View {
        let downloadedList = downloadService.downloadedSurahsList()

        return VStack(spacing: 12) {
            // Storage Management Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("OFFLINE RECITATION STORAGE")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                        .tracking(0.8)
                    Text("\(downloadService.formattedStorageSize()) used on device")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                if downloadService.totalAudioStorageSize() > 0 {
                    Button(role: .destructive) {
                        showingClearCacheAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Clear All")
                        }
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color.red.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if downloadedList.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 38))
                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0).opacity(0.4))
                        .padding(.top, 24)

                    Text("No Offline Recitations")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Text("Download full Surahs from the Mushaf for seamless offline recitation without internet or cellular data.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ForEach(downloadedList) { item in
                    downloadedSurahRow(item: item)
                }
            }
        }
    }

    private func downloadedSurahRow(item: QuranAudioDownloadService.DownloadedSurahInfo) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.14, blue: 0.20))
                    .frame(width: 42, height: 42)
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Surah \(item.surah.nameEnglish)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(item.surah.nameArabic)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(BayanTheme.goldSoft)
                }

                HStack(spacing: 6) {
                    Text("🗣️ \(item.reciter.nameEnglish)")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.6))
                    Text("•")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                    Text(item.formattedSize)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(spotifyGreen)
                }
            }

            // Delete Button
            Button {
                downloadService.deleteDownloadedSurah(item.surah, reciterId: item.reciterId)
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.45))
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
        )
    }

    // MARK: - 6C. Tab 2: Recitation History Feed
    private var recitationsHistoryFeed: some View {
        VStack(spacing: 12) {
            if syncManager.recentRecognitions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.badge.magnifyingglass")
                        .font(.system(size: 38))
                        .foregroundColor(BayanTheme.gold.opacity(0.35))
                        .padding(.top, 24)

                    Text("No Recitations Recorded")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Text("Recitations identified via the radar orb will automatically be archived in your journal.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                HStack {
                    Text("RECENT RECITATIONS JOURNAL")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(0.8)

                    Spacer()

                    Button {
                        showingClearHistoryAlert = true
                    } label: {
                        Text("Clear")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 4)

                ForEach(syncManager.recentRecognitions) { item in
                    recitationJournalCard(item: item)
                }
            }
        }
    }

    private func recitationJournalCard(item: RecognitionResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(item.surah.nameArabic)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(BayanTheme.goldSoft)
                Spacer()
                Text(item.recognizedAt, format: .dateTime.month().day().hour().minute())
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.45))
            }

            HStack {
                Text("\(item.surah.nameEnglish) • Ayah \(item.startAyah)–\(item.endAyah)")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("🗣️ \(item.reciter.nameEnglish)")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(spotifyGreen)
            }

            Text(item.arabicSnippet)
                .font(.system(size: 15, design: .serif))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineSpacing(4)

            HStack(spacing: 8) {
                Button {
                    playerService.play(surah: item.surah, ayah: item.startAyah)
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BayanTheme.gold)
                    .clipShape(Capsule())
                }

                Button {
                    selectedTafsirSurah = item.surah
                    selectedTafsirAyah = item.startAyah
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                        Text("Tafsir")
                    }
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundColor(BayanTheme.goldSoft)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }

                Spacer()
            }
        }
        .padding(14)
        .background(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - 7. Working Settings Quick Access Bar
    private var quickSettingsBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("QUICK PREFERENCES")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(0.8)
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Live Activity Row
                Button {
                    showingLiveActivitySettings = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.display")
                            .font(.system(size: 15))
                            .foregroundColor(BayanTheme.gold)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lock Screen Quran Lyrics")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(.white)
                            Text(isLiveActivityEnabled ? "Active & Streaming" : "Disabled")
                                .font(.system(size: 11))
                                .foregroundColor(isLiveActivityEnabled ? spotifyGreen : .white.opacity(0.45))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)

                Divider().background(Color.white.opacity(0.08))

                // App Theme Row
                Button {
                    showingThemeSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 15))
                            .foregroundColor(spotifyGreen)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appearance & Palette")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(.white)
                            Text(themeManager.currentTheme.name)
                                .font(.system(size: 11))
                                .foregroundColor(BayanTheme.goldSoft)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)

                Divider().background(Color.white.opacity(0.08))

                // Open All Settings Row
                Button {
                    showingSettingsSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.45, green: 0.75, blue: 1.0))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Application Settings")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(.white)
                            Text("Audio, Qari, Tajweed, Adhan, iCloud & Diagnostics")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.45))
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(14)
                }
                .buttonStyle(.plain)
            }
            .background(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.top, 4)
    }
}
