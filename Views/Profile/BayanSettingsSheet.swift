import SwiftUI
import StoreKit

// MARK: - Bayan Comprehensive Real Working Settings
/// Production-grade settings management engine controlling all audio, reading, prayer,
/// appearance, cloud sync, cache storage, and account preferences across Bayan.
public struct BayanSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    // Core Singletons
    @State private var authService = BayanAuthService.shared
    @State private var socialService = BayanSocialService.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var languageManager = AppLanguageManager.shared
    @State private var playerService = AudioPlayerService.shared
    @State private var prayerSettings = PrayerSettingsManager.shared
    @State private var adhanService = AdhanNotificationService.shared
    @State private var bookmarkService = BookmarkService.shared
    @State private var syncManager = QuranSyncManager.shared
    @State private var downloadService = QuranAudioDownloadService.shared
    @State private var cloudSync = BayanCloudSyncService.shared

    // Persistent User Preferences
    @AppStorage("bayan_arabic_font_size") private var arabicFontSize: Double = 26.0
    @AppStorage("bayan_tajweed_mode") private var isTajweedEnabled: Bool = false
    @AppStorage("bayan_show_translation") private var showTranslation: Bool = true
    @AppStorage("bayan_translation_source") private var translationSource: String = "Sahih International"
    @AppStorage("bayan_auto_advance_ayah") private var autoAdvanceAyah: Bool = true
    @AppStorage("bayan_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("bayan_live_activity_enabled") private var isLiveActivityEnabled: Bool = true
    @AppStorage("bayan_live_activity_mode") private var liveActivityMode: String = "lyrics"

    private var liveActivityModeTitle: String {
        switch liveActivityMode {
        case "lyricsAndTranslation": return "Lyrics & Translation"
        case "translationOnly": return "Translation Only"
        default: return "Lyrics"
        }
    }

    // UI Local State
    @State private var showingSignInSheet = false
    @State private var showingEditProfileSheet = false
    @State private var showingReciterPicker = false
    @State private var showingClearBookmarksAlert = false
    @State private var showingClearHistoryAlert = false
    @State private var showingClearCacheAlert = false
    @State private var showingExportShareSheet = false
    @State private var exportShareURL: URL? = nil
    @State private var cacheSizeBytes: Int64 = 0
    @State private var cacheClearedNotice = false
    @State private var updateService = BayanUpdateService.shared
    @State private var showingUpdateSheet = false

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.11).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Account & Identity Section
                        accountSection

                        // 2. Quran Reading & Typography Section
                        quranReadingSection

                        // 3. Audio Recitation & Qari Section
                        audioRecitationSection

                        // 4. Lock Screen & Live Activity Section
                        liveActivitySection

                        // 5. Prayer Times & Adhan Notifications Section
                        prayerTimesSection

                        // 5. Appearance, Themes & Language Section
                        appearanceSection

                        // 6. Storage, Cloud Backup & Data Section
                        storageAndDataSection

                        // 7. Haptics & Vibration Section
                        hapticsSection

                        // 8. About & Waqf Section
                        aboutSection
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                    .frame(maxWidth: 720)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(BayanTheme.goldSoft)
                }
            }
            .onAppear {
                refreshCacheSize()
            }
            .sheet(isPresented: $showingSignInSheet) {
                BayanSignInSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingEditProfileSheet) {
                EditProfileSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingReciterPicker) {
                reciterSelectionSheet
                    .presentationDetents([.large])
            }
            .sheet(item: $exportShareURL) { url in
                ShareActivityView(items: [url])
            }
            .alert("Clear All Bookmarks?", isPresented: $showingClearBookmarksAlert) {
                Button("Delete All", role: .destructive) {
                    bookmarkService.clearAllBookmarks()
                    triggerHaptic()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove all your saved bookmarks from this device and iCloud.")
            }
            .alert("Clear Recitation History?", isPresented: $showingClearHistoryAlert) {
                Button("Clear", role: .destructive) {
                    syncManager.clearRecognitionHistory()
                    triggerHaptic()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your identified audio recitation history list will be cleared.")
            }
            .alert("Clear Offline Audio Cache?", isPresented: $showingClearCacheAlert) {
                Button("Clear Cache", role: .destructive) {
                    downloadService.clearAllAudioCache()
                    refreshCacheSize()
                    triggerHaptic()
                    withAnimation {
                        cacheClearedNotice = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all offline downloaded recitation audio files to free up disk space.")
            }
            .sheet(isPresented: $showingUpdateSheet) {
                BayanUpdateSheet()
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - 1. Account & Identity Section
    private var accountSection: some View {
        settingsCard(title: "ACCOUNT & UMMAH IDENTITY", icon: "person.crop.circle.fill") {
            if authService.isSignedIn, let user = authService.currentUser {
                HStack(spacing: 12) {
                    Text(user.avatarEmoji)
                        .font(.system(size: 32))
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(user.name)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(BayanTheme.gold)
                        }

                        Text(user.email)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))

                        HStack(spacing: 4) {
                            Image(systemName: user.provider == .apple ? "apple.logo" : (user.provider == .google ? "globe" : "envelope.fill"))
                                .font(.system(size: 10))
                            Text("Signed in via \(user.provider.rawValue)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(spotifyGreen)
                    }

                    Spacer()

                    Button("Sign Out") {
                        authService.signOut()
                        triggerHaptic()
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Capsule())
                }
                .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sign in to backup your bookmarks, sync Khatmah progress across Apple devices, and connect with companions.")
                        .font(.system(size: 12.5))
                        .foregroundColor(.white.opacity(0.70))

                    Button {
                        showingSignInSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Sign In with Apple, Google, or Email")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(BayanTheme.gold)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Edit Profile Button
            Button {
                showingEditProfileSheet = true
            } label: {
                HStack {
                    Label("Edit Display Name, Handle & Bio", systemImage: "pencil")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Social Broadcast Toggle
            Toggle(isOn: $socialService.profile.isBroadcastingListening) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Live Recitation Broadcast")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Share the Surah and Ayah you are currently reciting with followed companions in real-time.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .tint(spotifyGreen)
        }
    }

    // MARK: - 2. Quran Reading & Typography Section
    private var quranReadingSection: some View {
        settingsCard(title: "QURAN READING & TYPOGRAPHY", icon: "book.pages.fill") {
            // Arabic Font Size Slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Arabic Verse Font Size")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(arabicFontSize)) pt")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(BayanTheme.goldSoft)
                }

                Slider(value: $arabicFontSize, in: 20...38, step: 1)
                    .tint(BayanTheme.gold)

                // Live Dynamic Text Preview Card
                VStack(spacing: 6) {
                    Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                        .font(.quran(size: CGFloat(arabicFontSize)))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text("ٱلرَّحْمَٰنُ ۝ عَلَّمَ ٱلْقُرْءَانَ ۝ خَلَقَ ٱلْإِنسَٰنَ")
                        .font(.quran(size: CGFloat(arabicFontSize)))
                        .foregroundColor(BayanTheme.goldSoft)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Divider().background(Color.white.opacity(0.1))

            // Tajweed Rules Toggle
            Toggle(isOn: $isTajweedEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tajweed Color-Coding Rules")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Colorize Ghunnah, Qalqalah, Idgham, and Madd letters according to traditional rules.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .tint(spotifyGreen)

            Divider().background(Color.white.opacity(0.1))

            // English Translation Toggle
            Toggle(isOn: $showTranslation) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show English Translation")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Display verse meaning below each Arabic Ayah.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .tint(spotifyGreen)

            if showTranslation {
                Divider().background(Color.white.opacity(0.1))

                // Translation Source
                HStack {
                    Text("Translation Source")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("Source", selection: $translationSource) {
                        Text("Sahih Intl").tag("Sahih International")
                        Text("Clear Quran").tag("The Clear Quran")
                        Text("Yusuf Ali").tag("Yusuf Ali")
                    }
                    .pickerStyle(.menu)
                    .tint(BayanTheme.goldSoft)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Auto-advance
            Toggle(isOn: $autoAdvanceAyah) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continuous Recitation (Auto-Advance)")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Automatically proceed to the next verse upon audio completion.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .tint(spotifyGreen)
        }
    }

    // MARK: - 3. Audio Recitation & Qari Section
    private var audioRecitationSection: some View {
        settingsCard(title: "AUDIO RECITATION & QARI", icon: "waveform") {
            // Reciter Selection Row
            Button {
                showingReciterPicker = true
            } label: {
                HStack(spacing: 12) {
                    Text("🗣️")
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Reciter (القارئ)")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(BayanTheme.gold)
                            .tracking(0.5)

                        Text(playerService.currentReciter.nameEnglish)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundColor(.white)

                        Text("\(playerService.currentReciter.nameArabic) • \(playerService.currentReciter.riwayah.rawValue)")
                            .font(.system(size: 11.5))
                            .foregroundColor(spotifyGreen)
                    }

                    Spacer()

                    Text("Change")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(spotifyGreen)
                        .clipShape(Capsule())
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Playback Speed
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recitation Speed")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Natural pitch preservation algorithm.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Picker("Speed", selection: Binding(
                    get: { playerService.playbackRate },
                    set: { newRate in
                        playerService.setPlaybackRate(newRate)
                        triggerHaptic()
                    }
                )) {
                    Text("0.75x").tag(Float(0.75))
                    Text("1.0x").tag(Float(1.0))
                    Text("1.25x").tag(Float(1.25))
                    Text("1.5x").tag(Float(1.5))
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
            }

            Divider().background(Color.white.opacity(0.1))

            // Dual Audio (English Voiceover)
            Toggle(isOn: Binding(
                get: { playerService.isDualAudioEnabled },
                set: { enabled in
                    playerService.isDualAudioEnabled = enabled
                    triggerHaptic()
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dual Audio Voiceover")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Play dignified English speech translation immediately following Arabic verse recitation.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .tint(spotifyGreen)

            Divider().background(Color.white.opacity(0.1))

            // Sleep Timer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bedtime Sleep Timer")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text(playerService.sleepTimerOption == .off ? "Off" : "Active: \(playerService.sleepTimerOption.title)")
                        .font(.system(size: 11.5))
                        .foregroundColor(playerService.sleepTimerOption == .off ? .white.opacity(0.55) : spotifyGreen)
                }

                Spacer()

                Menu {
                    ForEach(AudioPlayerService.SleepTimerOption.allCases, id: \.self) { option in
                        Button {
                            playerService.setSleepTimer(option)
                            triggerHaptic()
                        } label: {
                            HStack {
                                Text(option.title)
                                if playerService.sleepTimerOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: playerService.sleepTimerOption.iconName)
                        Text(playerService.sleepTimerOption.title)
                    }
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(BayanTheme.goldSoft)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - 4. Lock Screen & Live Activity Section
    private var liveActivitySection: some View {
        settingsCard(title: "LOCK SCREEN & LIVE ACTIVITY", icon: "lock.display") {
            NavigationLink {
                BayanLiveActivitySettingsView()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(spotifyGreen.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: "waveform.badge.magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(spotifyGreen)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live Activity (Lock Screen Lyrics)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text(isLiveActivityEnabled ? "On • \(liveActivityModeTitle)" : "Off")
                            .font(.system(size: 11.5))
                            .foregroundColor(isLiveActivityEnabled ? spotifyGreen : .white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
    }

    // MARK: - 5. Prayer Times & Adhan Notifications Section
    private var prayerTimesSection: some View {
        settingsCard(title: "PRAYER TIMES & ADHAN", icon: "clock.badge.checkmark.fill") {
            // Calculation Convention
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Calculation Method")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("Method", selection: Binding(
                        get: { prayerSettings.convention },
                        set: { newConv in
                            prayerSettings.convention = newConv
                            triggerHaptic()
                            refreshAdhan()
                        }
                    )) {
                        ForEach(CalculationConvention.allCases) { conv in
                            Text(conv.title).tag(conv)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BayanTheme.goldSoft)
                }
                Text(prayerSettings.convention.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Divider().background(Color.white.opacity(0.1))

            // Asr Juristic School
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Asr Juristic Method")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Picker("Asr School", selection: Binding(
                        get: { prayerSettings.asrSchool },
                        set: { newSchool in
                            prayerSettings.asrSchool = newSchool
                            triggerHaptic()
                            refreshAdhan()
                        }
                    )) {
                        ForEach(AsrJuristicSchool.allCases) { school in
                            Text(school.title).tag(school)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(BayanTheme.goldSoft)
                }
                Text(prayerSettings.asrSchool.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Divider().background(Color.white.opacity(0.1))

            // Adhan Notifications Toggle
            Toggle(isOn: Binding(
                get: { adhanService.isNotificationsEnabled },
                set: { enabled in
                    if enabled {
                        adhanService.requestPermission { _ in
                            refreshAdhan()
                        }
                    } else {
                        adhanService.isNotificationsEnabled = false
                    }
                    triggerHaptic()
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Adhan Local Push Notifications")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Receive prayer call reminders at exact solar calculated times.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .tint(spotifyGreen)

            Divider().background(Color.white.opacity(0.1))

            // Pre-Adhan 15min Reminder
            Toggle(isOn: Binding(
                get: { prayerSettings.isPreAdhanReminderEnabled },
                set: { enabled in
                    prayerSettings.isPreAdhanReminderEnabled = enabled
                    triggerHaptic()
                    refreshAdhan()
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("15-Minute Pre-Adhan Preparation")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Gentle reminder to make Wudu and prepare before prayer time.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .tint(spotifyGreen)
        }
    }

    // MARK: - 5. Appearance, Themes & Language Section
    private var appearanceSection: some View {
        settingsCard(title: "APPEARANCE & THEMES", icon: "paintpalette.fill") {
            // Theme Grid
            VStack(alignment: .leading, spacing: 10) {
                Text("Select Theme Canvas")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundColor(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(QuranTheme.allCases) { theme in
                            let isSelected = themeManager.currentTheme == theme
                            Button {
                                themeManager.setTheme(theme)
                                triggerHaptic()
                            } label: {
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(theme.previewBackground)
                                        .frame(width: 60, height: 44)
                                        .overlay(
                                            Text("ب")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(theme.previewTextColor)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(isSelected ? BayanTheme.gold : Color.white.opacity(0.15), lineWidth: isSelected ? 2.5 : 1)
                                        )

                                    Text(theme.title)
                                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? BayanTheme.gold : .white.opacity(0.7))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // App Language Selector
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("App Interface Language")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Changes layout direction and typography.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Picker("Language", selection: Binding(
                    get: { languageManager.currentLanguage },
                    set: { newLang in
                        languageManager.setLanguage(newLang)
                        triggerHaptic()
                    }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text("\(lang.flagEmoji) \(lang.rawValue)").tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .tint(BayanTheme.goldSoft)
            }
        }
    }

    // MARK: - 6. Storage, Cloud Backup & Data Section
    private var storageAndDataSection: some View {
        settingsCard(title: "STORAGE & ICLOUD DATA", icon: "externaldrive.fill") {
            // iCloud Sync Status
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(BayanTheme.gold)
                        Text("iCloud CloudKit Backup")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Text("Syncs bookmarks, Khatmah goals & reading position.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Button {
                    cloudSync.pushLocalChanges()
                    triggerHaptic()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Sync Now")
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(BayanTheme.gold)
                    .clipShape(Capsule())
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Offline Audio Cache Cleaner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Downloaded Audio Storage")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text(formatBytes(cacheSizeBytes))
                        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(cacheSizeBytes > 0 ? spotifyGreen : .white.opacity(0.5))
                }

                Spacer()

                Button("Clear Audio") {
                    showingClearCacheAlert = true
                }
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }

            Divider().background(Color.white.opacity(0.1))

            // Bookmarks Manager
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sacred Ayah Bookmarks")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("\(bookmarkService.bookmarks.count) saved verses")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Button {
                    if let url = bookmarkService.exportBookmarksJSON() {
                        exportShareURL = url
                        triggerHaptic()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                        .foregroundColor(BayanTheme.goldSoft)
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }

                Button("Clear") {
                    showingClearBookmarksAlert = true
                }
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(.red.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.red.opacity(0.12))
                .clipShape(Capsule())
            }

            Divider().background(Color.white.opacity(0.1))

            // Recitation Recognition History
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audio Identification Journal")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("\(syncManager.recentRecognitions.count) identified recitations")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Button("Clear History") {
                    showingClearHistoryAlert = true
                }
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - 7. Haptics & Vibration Section
    private var hapticsSection: some View {
        settingsCard(title: "HAPTICS & SENSORY", icon: "iphone.radiowaves.left.and.right") {
            Toggle(isOn: $hapticsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Interactive Haptic Feedback")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundColor(.white)
                    Text("Physical click vibration on digital Tasbih bead roll, bookmarks, and ayah navigation.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .tint(spotifyGreen)
        }
    }

    // MARK: - 8. About & Waqf Section
    private var aboutSection: some View {
        settingsCard(title: "ABOUT BAYAN", icon: "info.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("البيان • Bayan for iOS")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("Version \(updateService.currentVersion) (Build \(updateService.currentBuild)) • Waqf Fi Sabilillah")
                            .font(.system(size: 12))
                            .foregroundColor(BayanTheme.goldSoft)
                    }
                    Spacer()
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 22))
                        .foregroundColor(BayanTheme.gold)
                }

                // MARK: - Dynamic Update Banner if Newer Release Available
                if updateService.isUpdateAvailable {
                    Button {
                        showingUpdateSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(spotifyGreen.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(spotifyGreen)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("New Update Available!")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("v\(updateService.latestVersion)")
                                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                        .foregroundColor(BayanTheme.gold)
                                }
                                Text("Build \(updateService.latestBuild) • Tap to view & update")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Spacer()

                            Button {
                                updateService.openDownload()
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Update")
                                }
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(spotifyGreen)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(red: 0.12, green: 0.20, blue: 0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(spotifyGreen.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }

                Text("Developed with reverence as an ongoing charity (صدقة جارية) for the Muslim Ummah. Free from commercial advertisements forever.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))

                // MARK: - Check for Updates Control
                HStack {
                    Button {
                        Task {
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                            await updateService.checkForUpdates(silent: false)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if updateService.isChecking {
                                ProgressView()
                                    .scaleEffect(0.65)
                                    .tint(BayanTheme.gold)
                                Text("Checking GitHub...")
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Check for Updates")
                            }
                        }
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(BayanTheme.goldSoft)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    if !updateService.isChecking {
                        if updateService.isUpdateAvailable {
                            HStack(spacing: 4) {
                                Circle().fill(spotifyGreen).frame(width: 6, height: 6)
                                Text("Update Ready")
                                    .foregroundColor(spotifyGreen)
                            }
                            .font(.system(size: 11, weight: .bold))
                        } else if updateService.lastCheckedDate != nil {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(spotifyGreen)
                                Text("Up to date")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .font(.system(size: 11, weight: .medium))
                        }
                    }
                }
                .padding(.top, 2)

                HStack(spacing: 12) {
                    Button {
                        if let url = URL(string: "https://github.com/RAIKO05/BAYAN") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                            Text("Open Source GitHub")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    ShareLink(
                        item: URL(string: "https://github.com/RAIKO05/BAYAN/releases")!,
                        subject: Text("Bayan - The Holy Quran Companion"),
                        message: Text("Listen to holy recitations, read the Uthmanic Mushaf, and follow companions on Bayan: https://github.com/RAIKO05/BAYAN/releases")
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Bayan")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(spotifyGreen)
                        .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Helper Views & Reciter Sheet
    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(BayanTheme.gold)
                Text(title)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(BayanTheme.goldSoft)
                    .tracking(0.8)
            }

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.11, green: 0.12, blue: 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var reciterSelectionSheet: some View {
        NavigationStack {
            List(Reciter.standardCatalog) { reciter in
                let isSelected = playerService.currentReciter.id == reciter.id
                Button {
                    playerService.currentReciter = reciter
                    QuranSyncManager.shared.lastQariId = reciter.id
                    triggerHaptic()
                    showingReciterPicker = false
                } label: {
                    HStack(spacing: 12) {
                        Text(reciter.id == "omardiaa" ? "👑" : "🗣️")
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(reciter.nameEnglish)
                                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? BayanTheme.gold : .white)
                                if reciter.id == "omardiaa" {
                                    Text("FAVORITE")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(BayanTheme.gold)
                                        .clipShape(Capsule())
                                }
                            }

                            Text("\(reciter.nameArabic) • \(reciter.riwayah.rawValue) • \(reciter.style.rawValue)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(BayanTheme.gold)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select Reciter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        showingReciterPicker = false
                    }
                    .foregroundColor(BayanTheme.goldSoft)
                }
            }
        }
    }

    // MARK: - Internal Utilities
    private func refreshCacheSize() {
        cacheSizeBytes = downloadService.totalCacheSizeBytes()
    }

    private func refreshAdhan() {
        let defaults = UserDefaults(suiteName: "group.tools.rea.Bayan") ?? UserDefaults.standard
        let lat = defaults.double(forKey: "bayan_last_latitude") != 0.0 ? defaults.double(forKey: "bayan_last_latitude") : 33.5731
        let lng = defaults.double(forKey: "bayan_last_longitude") != 0.0 ? defaults.double(forKey: "bayan_last_longitude") : -7.5898
        let result = PrayerCalculationService.shared.calculate(for: Date(), lat: lat, lng: lng)
        adhanService.scheduleAdhanNotifications(prayerTimes: result.prayers)
    }

    private func triggerHaptic() {
        guard hapticsEnabled else { return }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 MB (No audio stored locally)" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: bytes)) used on device"
    }
}

// MARK: - ShareActivityView Wrapper
private struct ShareActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}