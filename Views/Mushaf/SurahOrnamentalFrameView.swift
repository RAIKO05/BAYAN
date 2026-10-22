import SwiftUI

// MARK: - Traditional Mushaf Ornamental Surah Header Frame
/// An authentic Islamic cartouche frame displaying the Surah title and metadata,
/// styled after the King Fahd Complex (Medina Mushaf) ornate cartouches.
public struct SurahOrnamentalFrameView: View {
    public let surah: Surah
    public var theme: QuranTheme = .paper

    @State private var playerService = AudioPlayerService.shared

    public init(surah: Surah, theme: QuranTheme = .paper) {
        self.surah = surah
        self.theme = theme
    }

    private var isPlayingThisSurah: Bool {
        playerService.isPlaying && playerService.currentSurah?.id == surah.id
    }

    private var surahTitleArabic: String {
        let trimmed = surah.nameArabic.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("سُورَةُ") || trimmed.hasPrefix("سورة") {
            return trimmed
        }
        return "سُورَةُ \(trimmed)"
    }

    private var ayahCountArabic: String {
        "آيَاتُهَا \(QuranVerseText.toArabicIndic(surah.totalAyahs))"
    }

    public var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Cartouche Background
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(theme.activeCardBorder.opacity(0.85), lineWidth: 1.5)
                    )
                    .overlay(
                        // Inner inset decorative border
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(theme.activeCardBorder.opacity(0.35), lineWidth: 1)
                            .padding(4)
                    )
                    .shadow(color: Color.black.opacity(theme.isDark ? 0.35 : 0.06), radius: 10, y: 4)

                // Ornamental Corner Accents & Header Content
                VStack(spacing: 6) {
                    HStack {
                        // Left Ornamental Finial
                        Text("۞")
                            .font(.system(size: 14))
                            .foregroundColor(theme.activeCardBorder)
                            .padding(.leading, 14)

                        Spacer()

                        // Surah Revelation & Ayah Count Metadata (Right-aligned in traditional Mushaf)
                        HStack(spacing: 6) {
                            Text(surah.revelationType.arabicTitle)
                                .font(.system(size: 13, weight: .bold))
                            Text("•")
                            Text(ayahCountArabic)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(theme.headerSubtitleColor)
                        .padding(.trailing, 14)
                    }
                    .padding(.top, 10)

                    // Calligraphic Surah Name in Amiri Quran
                    HStack(spacing: 12) {
                        Text("✤")
                            .font(.system(size: 16))
                            .foregroundColor(theme.activeCardBorder.opacity(0.7))

                        Text(surahTitleArabic)
                            .font(.quranBold(size: 34))
                            .foregroundColor(theme.headerTitleColor)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)

                        Text("✤")
                            .font(.system(size: 16))
                            .foregroundColor(theme.activeCardBorder.opacity(0.7))
                    }
                    .padding(.horizontal, 20)

                    // English Subtitle
                    Text("\(surah.nameEnglish) • \(surah.nameTranslation)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.headerSubtitleColor)
                        .padding(.bottom, 6)

                    // MARK: - Play Full Surah Button (With No Stops)
                    HStack(spacing: 10) {
                        Button {
                            togglePlayFullSurah()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isPlayingThisSurah ? "pause.fill" : "play.fill")
                                    .font(.system(size: 13, weight: .bold))

                                Text(isPlayingThisSurah ? "Pause Recitation" : "Play Full Surah")
                                    .font(.system(size: 13, weight: .bold))

                                if isPlayingThisSurah {
                                    HStack(spacing: 3) {
                                        Text("•")
                                        Text("Ayah \(playerService.currentAyah)/\(surah.totalAyahs)")
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .opacity(0.85)
                                }
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [BayanTheme.gold, BayanTheme.goldSoft],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: BayanTheme.gold.opacity(0.35), radius: 6, y: 2)
                        }
                        .buttonStyle(.plain)

                        if playerService.currentSurah?.id == surah.id && playerService.currentAyah > 1 {
                            Button {
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                                playerService.repeatMode = .off
                                playerService.play(surah: surah, ayah: 1)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "backward.end.fill")
                                        .font(.system(size: 10))
                                    Text("From Ayah 1")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(theme.activeCardBorder)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    private func togglePlayFullSurah() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif

        if isPlayingThisSurah {
            playerService.pause()
        } else if playerService.currentSurah?.id == surah.id {
            playerService.resume()
        } else {
            // Start playing from Ayah 1 with continuous sequential progression (no stops)
            playerService.repeatMode = .off
            playerService.play(surah: surah, ayah: 1)
        }
    }
}
