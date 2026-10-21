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

    @State private var themeManager = AppThemeManager.shared

    private var currentTheme: QuranTheme {
        themeManager.currentTheme
    }

    var body: some View {
        ZStack {
            // Theme Background Canvas
            Group {
                currentTheme.backgroundColor.ignoresSafeArea()
                currentTheme.backgroundGradient.ignoresSafeArea()
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Surah Header Banner (Authentic Mushaf Ornamental Cartouche)
                        SurahOrnamentalFrameView(surah: surah, theme: currentTheme)

                        // Bismillah (except Surah At-Tawbah #9 and Surah Al-Fatihah #1 where it is Ayah 1)
                        if surah.id != 9 && surah.id != 1 {
                            Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ")
                                .font(.quran(size: 28))
                                .foregroundColor(currentTheme.bismillahColor)
                                .multilineTextAlignment(.center)
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
                    get: { themeManager.currentTheme },
                    set: { themeManager.setTheme($0) }
                ))
                .padding(.horizontal, 16)

                Spacer()
            }
            .background(currentTheme.backgroundColor.ignoresSafeArea())
            .presentationDetents([.fraction(0.42), .medium])
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

    private var ayahArabic: String {
        QuranVerseText.formattedAyah(surahId: surah.id, ayahNumber: ayahNumber)
    }

    private var ayahEnglish: String {
        QuranVerseText.translation(surahId: surah.id, ayahNumber: ayahNumber)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 14) {
            // Verse Header Bar (Reference: Surah:Ayah identifier on left, Action buttons on right)
            HStack(spacing: 8) {
                // Surah:Ayah Badge (e.g. 12:1)
                Text("\(surah.id):\(ayahNumber)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(theme.medallionText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(theme.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    .clipShape(Capsule())

                Spacer()

                // Share Button
                ShareLink(item: "\(ayahArabic)\n\n\(ayahEnglish)\n\n[Surah \(surah.nameEnglish) \(surah.id):\(ayahNumber) - Bayan]") {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundColor(theme.toolbarItemColor.opacity(0.7))
                        .frame(width: 28, height: 28)
                }

                // Copy Button
                Button {
                    #if os(iOS)
                    UIPasteboard.general.string = "\(ayahArabic)\n\n\(ayahEnglish)"
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(theme.toolbarItemColor.opacity(0.7))
                        .frame(width: 28, height: 28)
                }

                // Bookmark Button
                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    BookmarkService.shared.toggleBookmark(
                        surahId: surah.id,
                        ayahNumber: ayahNumber,
                        surahNameArabic: surah.nameArabic,
                        surahNameEnglish: surah.nameEnglish,
                        arabicText: ayahArabic,
                        translationText: ayahEnglish
                    )
                } label: {
                    let isBookmarked = BookmarkService.shared.isBookmarked(surahId: surah.id, ayahNumber: ayahNumber)
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15))
                        .foregroundColor(isBookmarked ? theme.toolbarAccentColor : theme.toolbarItemColor.opacity(0.7))
                        .frame(width: 28, height: 28)
                }

                // Play / Recitation Button
                Button(action: onPlayTap) {
                    Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isActive ? theme.activeCardBorder : theme.toolbarItemColor.opacity(0.7))
                        .frame(width: 28, height: 28)
                }

                // Tafsir & Reflection Button
                Button(action: onTafsirTap) {
                    HStack(spacing: 3) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 12))
                        Text("Tafsir")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(theme.toolbarAccentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    .clipShape(Capsule())
                }
            }

            // Arabic Verse with Authentic Uthmanic Font & Inline End Medallion
            Text(ayahArabic)
                .font(.quran(size: 26))
                .multilineTextAlignment(.trailing)
                .lineSpacing(12)
                .foregroundColor(isActive ? theme.activeArabicTextColor : theme.arabicTextColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .onTapGesture {
                    onTafsirTap()
                }

            // English Translation (Tappable for Tafsir)
            Text(ayahEnglish)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(theme.translationTextColor)
                .lineSpacing(4)
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
}
