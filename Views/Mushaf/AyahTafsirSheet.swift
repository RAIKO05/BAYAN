import SwiftUI

// MARK: - Instant Ayah Tafsir & Reflection Sheet
// Displays authentic classical Tafsir (As-Sa'di / Ibn Kathir), English translation,
// revelation context, lessons, and audio Hifz repetition controls.
public struct AyahTafsirSheet: View {
    public let surah: Surah
    public let ayahNumber: Int
    @Environment(\.dismiss) private var dismiss

    @State private var playerService = AudioPlayerService.shared
    @State private var tafsirService = QuranTafsirService.shared
    @State private var selectedTab: TafsirTab = .arabic
    @State private var copiedNotice: Bool = false

    enum TafsirTab: String, CaseIterable {
        case arabic = "التفسير الميسر"
        case english = "English Reflection"
        case lessons = "فوائد الآية"
    }

    public init(surah: Surah, ayahNumber: Int) {
        self.surah = surah
        self.ayahNumber = ayahNumber
    }

    private var arabicText: String {
        QuranVerseText.formattedAyah(surahId: surah.id, ayahNumber: ayahNumber)
    }

    private var englishText: String {
        QuranVerseText.translation(surahId: surah.id, ayahNumber: ayahNumber)
    }

    private var entry: QuranTafsirEntry {
        tafsirService.tafsir(for: surah.id, ayahNumber: ayahNumber)
    }

    private var isPlayingThisAyah: Bool {
        playerService.isPlaying &&
        playerService.currentSurah?.id == surah.id &&
        playerService.currentAyah == ayahNumber
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background Obsidian & Emerald Glow
                BayanTheme.obsidian.ignoresSafeArea()
                RadialGradient(
                    colors: [BayanTheme.deepEmerald.opacity(0.4), Color.clear],
                    center: .top,
                    startRadius: 40,
                    endRadius: 400
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header Medallion
                        headerBanner

                        // Arabic Verse Display
                        arabicVerseCard

                        // English Translation Card
                        englishTranslationCard

                        // Tafsir & Reflection Segmented Section
                        tafsirContentSection

                        // Action Buttons (Play / Hifz Repeat / Bookmark / Share)
                        actionButtonsGrid

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("تفسير وتدبر • Tafsir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if copiedNotice {
                    Text("تم نسخ الآية والترجمة • Copied to Clipboard")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(BayanTheme.obsidian)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(BayanTheme.gold)
                        .clipShape(Capsule())
                        .shadow(color: BayanTheme.gold.opacity(0.4), radius: 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                }
            }
        }
    }

    // MARK: - Header Banner
    private var headerBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(surah.nameEnglish)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("•")
                        .foregroundColor(BayanTheme.goldSoft)
                    Text("Ayah \(ayahNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(BayanTheme.goldSoft)
                }

                Text("\(surah.revelationType.rawValue) • \(surah.revelationType.arabicTitle)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Arabic Surah Title
            Text(surah.nameArabic)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18, isGoldBorder: true)
    }

    // MARK: - Arabic Verse Card
    private var arabicVerseCard: some View {
        VStack(alignment: .trailing, spacing: 14) {
            HStack {
                // Ayah Medallion
                ZStack {
                    Circle()
                        .stroke(BayanTheme.gold.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                    Text("\(ayahNumber)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(BayanTheme.goldSoft)
                }

                Spacer()

                Text("النص القرآني")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(BayanTheme.goldSoft.opacity(0.8))
            }

            Text(arabicText)
                .font(.quran(size: 28))
                .multilineTextAlignment(.trailing)
                .lineSpacing(12)
                .foregroundColor(BayanTheme.goldSoft)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }

    // MARK: - English Translation Card
    private var englishTranslationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TRANSLATION (SAHIH INTERNATIONAL)")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(BayanTheme.goldSoft.opacity(0.85))
                Spacer()
            }

            Text(englishText)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }

    // MARK: - Tafsir & Reflection Section
    private var tafsirContentSection: some View {
        VStack(spacing: 12) {
            // Segmented Picker
            HStack(spacing: 6) {
                ForEach(TafsirTab.allCases, id: \.self) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        selectedTab = tab
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? BayanTheme.gold : Color.white.opacity(0.08))
                            .foregroundColor(isSelected ? BayanTheme.obsidian : .white.opacity(0.75))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.black.opacity(0.25))
            .clipShape(Capsule())

            // Content Panel
            VStack(alignment: .leading, spacing: 14) {
                switch selectedTab {
                case .arabic:
                    VStack(alignment: .trailing, spacing: 10) {
                        Text(entry.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(BayanTheme.goldSoft)
                            .multilineTextAlignment(.trailing)

                        Text(entry.arabicTafsir)
                            .font(.system(size: 16, weight: .regular))
                            .lineSpacing(8)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white.opacity(0.95))

                        if let context = entry.revelationContext {
                            Divider().overlay(Color.white.opacity(0.1))
                            Text("سبب النزول والفضل:")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(BayanTheme.electricCyan)
                            Text(context)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                case .english:
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entry.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BayanTheme.goldSoft)

                        Text(entry.englishTafsir)
                            .font(.system(size: 14.5, weight: .regular))
                            .lineSpacing(6)
                            .foregroundColor(.white.opacity(0.92))

                        if let context = entry.revelationContext {
                            Divider().overlay(Color.white.opacity(0.1))
                            Text("Context & Merits:")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(BayanTheme.electricCyan)
                            Text(context)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                case .lessons:
                    VStack(alignment: .trailing, spacing: 12) {
                        Text("الفوائد والدروس المستفادة:")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(BayanTheme.goldSoft)
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        ForEach(entry.keyLessons, id: \.self) { lesson in
                            HStack(alignment: .top, spacing: 8) {
                                Text(lesson)
                                    .font(.system(size: 14.5))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.trailing)
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(BayanTheme.gold)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(18)
            .liquidGlass(cornerRadius: 18)
        }
    }

    // MARK: - Action Buttons Grid
    private var actionButtonsGrid: some View {
        HStack(spacing: 12) {
            // Play / Pause Ayah
            Button {
                if isPlayingThisAyah {
                    playerService.togglePlayPause()
                } else {
                    playerService.play(surah: surah, ayah: ayahNumber)
                }
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isPlayingThisAyah ? "pause.fill" : "play.fill")
                    Text(isPlayingThisAyah ? "Pause" : "Play")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(BayanTheme.obsidian)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(BayanTheme.gold)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            // Hifz Repeat Mode
            Button {
                playerService.cycleRepeatMode()
                if !isPlayingThisAyah {
                    playerService.play(surah: surah, ayah: ayahNumber)
                }
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: playerService.repeatMode.iconName)
                    Text(playerService.repeatMode.title)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(playerService.repeatMode.isRepeating ? BayanTheme.gold : .white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(playerService.repeatMode.isRepeating ? BayanTheme.gold : Color.clear, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            // Bookmark Button
            Button {
                BookmarkService.shared.toggleBookmark(
                    surahId: surah.id,
                    ayahNumber: ayahNumber,
                    surahNameArabic: surah.nameArabic,
                    surahNameEnglish: surah.nameEnglish,
                    arabicText: arabicText,
                    translationText: englishText
                )
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            } label: {
                let isBookmarked = BookmarkService.shared.isBookmarked(surahId: surah.id, ayahNumber: ayahNumber)
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isBookmarked ? BayanTheme.gold : .white.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            // Copy / Share Button
            Button {
                copyAyahContent()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private func copyAyahContent() {
        let citation = "﴿\(arabicText)﴾\n\n\"\(englishText)\"\n\n[سورة \(surah.nameArabic) • Surah \(surah.nameEnglish) \(surah.id):\(ayahNumber)]\nShared via BAYAN"
        #if os(iOS)
        UIPasteboard.general.string = citation
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        withAnimation {
            copiedNotice = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                copiedNotice = false
            }
        }
    }
}
