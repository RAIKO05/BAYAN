import SwiftUI

struct SurahDetailView: View {
    let surah: Surah
    var initialAyah: Int = 1

    @State private var playerService = AudioPlayerService.shared
    @State private var syncManager = QuranSyncManager.shared
    @State private var activeAyah: Int = 1
    @State private var showingReciterSheet = false
    @State private var showingThemeSheet = false
    @State private var selectedTafsirAyah: Int? = nil

    @AppStorage("bayan_quran_theme") private var savedThemeRaw: String = QuranTheme.paper.rawValue

    private var currentTheme: QuranTheme {
        QuranTheme(rawValue: savedThemeRaw) ?? .paper
    }

    var body: some View {
        ZStack {
            // Theme Background Canvas
            Group {
                if currentTheme == .dark {
                    BayanTheme.obsidian.ignoresSafeArea()
                    RadialGradient(
                        colors: [BayanTheme.deepEmerald.opacity(0.4), Color.clear],
                        center: .top,
                        startRadius: 50,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                } else if currentTheme == .paper {
                    currentTheme.backgroundColor.ignoresSafeArea()
                    RadialGradient(
                        colors: [Color(red: 0.99, green: 0.97, blue: 0.90).opacity(0.6), Color.clear],
                        center: .top,
                        startRadius: 50,
                        endRadius: 500
                    )
                    .ignoresSafeArea()
                } else {
                    currentTheme.backgroundColor.ignoresSafeArea()
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Surah Header Banner
                        VStack(spacing: 12) {
                            Text(surah.nameArabic)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(currentTheme.headerTitleColor)

                            Text("\(surah.nameEnglish) • \(surah.nameTranslation)")
                                .font(.subheadline)
                                .foregroundColor(currentTheme.headerSubtitleColor)

                            HStack(spacing: 12) {
                                Label("\(surah.totalAyahs) Ayahs", systemImage: "text.alignleft")
                                Text("•")
                                Label(surah.revelationType.arabicTitle, systemImage: "building.columns.fill")
                                Text("•")
                                Label("Page \(surah.startPage)", systemImage: "book.pages")
                            }
                            .font(.caption)
                            .foregroundColor(currentTheme.headerInfoColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(currentTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(currentTheme.activeCardBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(currentTheme.isDark ? 0.3 : 0.06), radius: 12, y: 6)
                        .padding(.horizontal)

                        // Bismillah (except Surah At-Tawbah #9)
                        if surah.id != 9 && surah.id != 1 {
                            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                                .font(.system(size: 26, weight: .medium, design: .serif))
                                .foregroundColor(currentTheme.bismillahColor)
                                .padding(.vertical, 8)
                        }

                        // All Ayahs in Surah
                        LazyVStack(spacing: 16) {
                            ForEach(1...surah.totalAyahs, id: \.self) { ayahNum in
                                AyahRow(
                                    surah: surah,
                                    ayahNumber: ayahNum,
                                    theme: currentTheme,
                                    isActive: activeAyah == ayahNum && playerService.isPlaying,
                                    onPlayTap: {
                                        if playerService.isPlaying && playerService.currentSurah?.id == surah.id && playerService.currentAyah == ayahNum {
                                            playerService.togglePlayPause()
                                        } else {
                                            activeAyah = ayahNum
                                            playerService.play(surah: surah, ayah: ayahNum)
                                        }
                                    },
                                    onTafsirTap: {
                                        selectedTafsirAyah = ayahNum
                                        #if os(iOS)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        #endif
                                    }
                                )
                                .id(ayahNum)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 120)
                    }
                    .padding(.top, 16)
                }
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 120) }
                .onAppear {
                    activeAyah = initialAyah
                    proxy.scrollTo(initialAyah, anchor: .center)
                    syncManager.updateLastRead(
                        surahId: surah.id,
                        ayahId: initialAyah,
                        page: surah.startPage,
                        qariId: playerService.currentReciter.id
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    // Theme Appearance Picker Button
                    Button {
                        showingThemeSheet = true
                    } label: {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(currentTheme.toolbarAccentColor)
                    }

                    // Hifz Repeat Mode Quick Toggle
                    Button {
                        playerService.cycleRepeatMode()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: playerService.repeatMode.iconName)
                            if playerService.repeatMode.isRepeating {
                                Text(playerService.repeatMode.title)
                                    .font(.system(size: 11, weight: .bold))
                            }
                        }
                        .foregroundColor(playerService.repeatMode.isRepeating ? currentTheme.toolbarAccentColor : currentTheme.toolbarItemColor)
                    }

                    // Reciter Picker Button
                    Button {
                        showingReciterSheet = true
                    } label: {
                        Image(systemName: "person.wave.2.fill")
                            .foregroundColor(currentTheme.toolbarAccentColor)
                    }

                    // Favorite Button
                    Button {
                        syncManager.toggleFavorite(surahId: surah.id)
                    } label: {
                        Image(systemName: syncManager.favoriteSurahIds.contains(surah.id) ? "heart.fill" : "heart")
                            .foregroundColor(currentTheme.toolbarAccentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingThemeSheet) {
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)

                QuranThemeSelectorCard(selectedTheme: Binding(
                    get: { currentTheme },
                    set: { savedThemeRaw = $0.rawValue }
                ))
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(currentTheme.backgroundColor.ignoresSafeArea())
            .presentationDetents([.fraction(0.32), .medium])
        }
        .sheet(isPresented: $showingReciterSheet) {
            ReciterPickerSheet(selectedReciter: $playerService.currentReciter)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: Binding(
            get: { selectedTafsirAyah != nil },
            set: { if !$0 { selectedTafsirAyah = nil } }
        )) {
            if let ayah = selectedTafsirAyah {
                AyahTafsirSheet(surah: surah, ayahNumber: ayah)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

// Single Ayah Row
private struct AyahRow: View {
    let surah: Surah
    let ayahNumber: Int
    var theme: QuranTheme = .paper
    let isActive: Bool
    let onPlayTap: () -> Void
    var onTafsirTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            HStack {
                Button(action: onPlayTap) {
                    Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(isActive ? theme.activeCardBorder : theme.toolbarItemColor.opacity(0.7))
                }

                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    BookmarkService.shared.toggleBookmark(
                        surahId: surah.id,
                        ayahNumber: ayahNumber,
                        surahNameArabic: surah.nameArabic,
                        surahNameEnglish: surah.nameEnglish,
                        arabicText: sampleArabicAyah(ayahNumber: ayahNumber),
                        translationText: sampleEnglishAyah(ayahNumber: ayahNumber)
                    )
                } label: {
                    let isBookmarked = BookmarkService.shared.isBookmarked(surahId: surah.id, ayahNumber: ayahNumber)
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16))
                        .foregroundColor(isBookmarked ? theme.toolbarAccentColor : theme.toolbarItemColor.opacity(0.45))
                }
                .padding(.leading, 6)

                // Tafsir & Reflection Button
                Button(action: onTafsirTap) {
                    HStack(spacing: 3) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 13))
                        Text("Tafsir")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(theme.toolbarAccentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    .clipShape(Capsule())
                }
                .padding(.leading, 6)

                Spacer()

                // Ayah Medallion
                ZStack {
                    Circle()
                        .stroke(theme.medallionBorder, lineWidth: 1.2)
                        .frame(width: 30, height: 30)
                    Text("\(ayahNumber)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(theme.medallionText)
                }
            }

            // Arabic Verse (Tappable for Tafsir)
            Text(sampleArabicAyah(ayahNumber: ayahNumber))
                .font(.system(size: 24, weight: .regular, design: .serif))
                .multilineTextAlignment(.trailing)
                .lineSpacing(10)
                .foregroundColor(isActive ? theme.activeArabicTextColor : theme.arabicTextColor)
                .onTapGesture {
                    onTafsirTap()
                }

            // English Translation (Tappable for Tafsir)
            Text(sampleEnglishAyah(ayahNumber: ayahNumber))
                .font(.callout)
                .foregroundColor(theme.translationTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture {
                    onTafsirTap()
                }
        }
        .padding(18)
        .background(isActive ? theme.activeCardFill : theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isActive ? theme.activeCardBorder : theme.cardBorder, lineWidth: isActive ? 1.5 : 1)
        )
        .shadow(color: Color.black.opacity(theme.isDark ? 0.25 : 0.05), radius: 10, y: 4)
    }

    private func sampleArabicAyah(ayahNumber: Int) -> String {
        QuranVerseText.arabic(surahId: surah.id, ayahNumber: ayahNumber)
    }

    private func sampleEnglishAyah(ayahNumber: Int) -> String {
        QuranVerseText.translation(surahId: surah.id, ayahNumber: ayahNumber)
    }
}
