import SwiftUI

struct SurahDetailView: View {
    let surah: Surah
    var initialAyah: Int = 1

    @Environment(\.dismiss) private var dismiss

    @State private var playerService = AudioPlayerService.shared
    @State private var syncManager = QuranSyncManager.shared
    @State private var downloadService = QuranAudioDownloadService.shared
    @State private var activeAyah: Int = 1
    @State private var showingReciterSheet = false
    @State private var showingThemeSheet = false
    @State private var showingTajweedLegend = false
    @State private var showingHifzCompanion = false
    @State private var showingABLoopSheet = false
    @State private var selectedTafsirAyah: Int? = nil
    @State private var selectedWordsAyah: Int? = nil

    private var effectiveActiveAyah: Int {
        if playerService.currentSurah?.id == surah.id {
            return playerService.currentAyah
        }
        return activeAyah
    }

    @AppStorage("bayan_tajweed_mode") private var isTajweedEnabled: Bool = false
    @AppStorage("bayan_arabic_font_size") private var arabicFontSize: Double = 26.0
    @AppStorage("bayan_show_translation") private var showTranslation: Bool = true
    @State private var themeManager = AppThemeManager.shared

    private var currentTheme: QuranTheme {
        themeManager.currentTheme
    }

    private var downloadStatus: QuranAudioDownloadService.DownloadStatus {
        downloadService.downloadStatus(reciterId: playerService.currentReciter.id, surah: surah)
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

                        // Quick Control Strip: Tajweed, Hifz, Download
                        HStack(spacing: 10) {
                            // Tajweed Toggle Chip
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isTajweedEnabled.toggle()
                                }
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            } label: {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(isTajweedEnabled ? Color.green : Color.white.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                    Text("Tajweed")
                                        .font(.caption2.weight(.bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(isTajweedEnabled ? currentTheme.toolbarAccentColor.opacity(0.18) : Color.white.opacity(0.06))
                                .foregroundColor(isTajweedEnabled ? currentTheme.toolbarAccentColor : .white.opacity(0.8))
                                .clipShape(Capsule())
                            }

                            // Tajweed Guide Button (when active)
                            if isTajweedEnabled {
                                Button {
                                    showingTajweedLegend = true
                                } label: {
                                    Image(systemName: "questionmark.circle")
                                        .font(.caption)
                                        .foregroundColor(currentTheme.toolbarAccentColor)
                                }
                            }

                            Spacer()

                            // Hifz Companion Launch Button
                            Button {
                                showingHifzCompanion = true
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.caption2)
                                    Text("Hifz")
                                        .font(.caption2.weight(.bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.06))
                                .foregroundColor(.white.opacity(0.85))
                                .clipShape(Capsule())
                            }

                            // A-B Memorization Loop Button
                            Button {
                                showingABLoopSheet = true
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "repeat.1.ar")
                                        .font(.caption2)
                                    Text(playerService.isABLoopActive ? "Loop \(playerService.abStartAyah)-\(playerService.abEndAyah)" : "A-B Loop")
                                        .font(.caption2.weight(.bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(playerService.isABLoopActive ? currentTheme.toolbarAccentColor.opacity(0.22) : Color.white.opacity(0.06))
                                .foregroundColor(playerService.isABLoopActive ? currentTheme.toolbarAccentColor : .white.opacity(0.85))
                                .clipShape(Capsule())
                            }

                            // Offline Audio Download Button
                            Button {
                                handleDownloadTap()
                            } label: {
                                HStack(spacing: 5) {
                                    switch downloadStatus {
                                    case .notDownloaded:
                                        Image(systemName: "arrow.down.circle")
                                            .font(.caption2)
                                        Text("Download")
                                            .font(.caption2.weight(.bold))
                                    case .downloading(let progress):
                                        ProgressView()
                                            .scaleEffect(0.6)
                                        Text("\(Int(progress * 100))%")
                                            .font(.caption2.weight(.bold))
                                    case .downloaded:
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(currentTheme.toolbarAccentColor)
                                        Text("Offline")
                                            .font(.caption2.weight(.bold))
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.06))
                                .foregroundColor(.white.opacity(0.85))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)

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
                                    isTajweedEnabled: isTajweedEnabled,
                                    isActive: effectiveActiveAyah == ayahNum && playerService.isPlaying,
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
                                    },
                                    onWordsTap: {
                                        selectedWordsAyah = ayahNum
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
                    .frame(maxWidth: 820)
                    .padding(.top, 16)
                }
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 120) }
                .onChange(of: playerService.currentAyah) { _, newAyah in
                    if playerService.currentSurah?.id == surah.id {
                        activeAyah = newAyah
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            proxy.scrollTo(newAyah, anchor: .center)
                        }
                        syncManager.updateLastRead(
                            surahId: surah.id,
                            ayahId: newAyah,
                            page: surah.startPage,
                            qariId: playerService.currentReciter.id
                        )
                    }
                }
                .onAppear {
                    let targetAyah = (playerService.currentSurah?.id == surah.id) ? playerService.currentAyah : initialAyah
                    activeAyah = targetAyah
                    proxy.scrollTo(targetAyah, anchor: .center)
                    syncManager.updateLastRead(
                        surahId: surah.id,
                        ayahId: targetAyah,
                        page: surah.startPage,
                        qariId: playerService.currentReciter.id
                    )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(
            currentTheme.isDark ? Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.94) : currentTheme.backgroundColor.opacity(0.94),
            for: .navigationBar
        )
        .toolbar {
            // MARK: - Spotify-Style Circular Glass Back Button
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.20, green: 0.23, blue: 0.32).opacity(0.65))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                            )
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            }

            // MARK: - Centered Pinned Surah Header Title
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Surah \(surah.nameEnglish)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    Text(surah.nameArabic)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(currentTheme.toolbarAccentColor)
                }
            }

            // MARK: - Trailing Actions Inside Spotify-Style Glass Capsule
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 10) {
                    // Theme Appearance Picker Button
                    Button {
                        showingThemeSheet = true
                    } label: {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 13))
                            .foregroundColor(currentTheme.toolbarAccentColor)
                    }

                    // Hifz Repeat Mode Quick Toggle
                    Button {
                        playerService.cycleRepeatMode()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: playerService.repeatMode.iconName)
                                .font(.system(size: 13))
                            if playerService.repeatMode.isRepeating {
                                Text(playerService.repeatMode.title)
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundColor(playerService.repeatMode.isRepeating ? currentTheme.toolbarAccentColor : currentTheme.toolbarItemColor)
                    }

                    // Reciter Picker Button (Reciter side view emoji)
                    Button {
                        showingReciterSheet = true
                    } label: {
                        Text("🗣️")
                            .font(.system(size: 14))
                    }

                    // Favorite Button
                    Button {
                        syncManager.toggleFavorite(surahId: surah.id)
                    } label: {
                        Image(systemName: syncManager.favoriteSurahIds.contains(surah.id) ? "heart.fill" : "heart")
                            .font(.system(size: 13))
                            .foregroundColor(currentTheme.toolbarAccentColor)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(red: 0.20, green: 0.23, blue: 0.32).opacity(0.55))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                )
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
        .sheet(isPresented: $showingTajweedLegend) {
            TajweedLegendSheet()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingHifzCompanion) {
            HifzCompanionView(surah: surah, initialAyah: effectiveActiveAyah)
        }
        .sheet(isPresented: $showingABLoopSheet) {
            ABLoopSheet(surah: surah, initialAyah: effectiveActiveAyah)
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
        .sheet(isPresented: Binding(
            get: { selectedWordsAyah != nil },
            set: { if !$0 { selectedWordsAyah = nil } }
        )) {
            if let ayah = selectedWordsAyah {
                WordByWordSheet(surah: surah, ayahNumber: ayah)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func handleDownloadTap() {
        switch downloadStatus {
        case .notDownloaded:
            downloadService.downloadSurah(surah, reciter: playerService.currentReciter)
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
        case .downloading:
            // In progress
            break
        case .downloaded:
            downloadService.deleteDownloadedSurah(surah, reciterId: playerService.currentReciter.id)
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }
}

// Single Ayah Row
private struct AyahRow: View {
    let surah: Surah
    let ayahNumber: Int
    var theme: QuranTheme = .paper
    var isTajweedEnabled: Bool = false
    let isActive: Bool
    let onPlayTap: () -> Void
    var onTafsirTap: () -> Void = {}
    var onWordsTap: () -> Void = {}

    @AppStorage("bayan_arabic_font_size") private var arabicFontSize: Double = 26.0
    @AppStorage("bayan_show_translation") private var showTranslation: Bool = true

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

                // Words / Vocabulary Explorer
                Button(action: onWordsTap) {
                    HStack(spacing: 3) {
                        Image(systemName: "character.book.closed")
                            .font(.system(size: 11))
                        Text("Words")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(theme.toolbarAccentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    .clipShape(Capsule())
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

            // Arabic Verse: Plain or Tajweed Color-Coded
            if isTajweedEnabled {
                Text(TajweedEngine.shared.colorize(arabicText: ayahArabic))
                    .font(.quran(size: CGFloat(arabicFontSize)))
                    .multilineTextAlignment(.trailing)
                    .lineSpacing(12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onTapGesture {
                        onTafsirTap()
                    }
            } else {
                Text(ayahArabic)
                    .font(.quran(size: CGFloat(arabicFontSize)))
                    .multilineTextAlignment(.trailing)
                    .lineSpacing(12)
                    .foregroundColor(isActive ? theme.activeArabicTextColor : theme.arabicTextColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onTapGesture {
                        onTafsirTap()
                    }
            }

            // English Translation (Tappable for Tafsir, optional via settings)
            if showTranslation && !ayahEnglish.isEmpty {
                Text(ayahEnglish)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(theme.translationTextColor)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        onTafsirTap()
                    }
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
