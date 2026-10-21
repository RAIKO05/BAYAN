import SwiftUI

// MARK: - Spotify-Style Floating Audio Mini-Player Bar
// Pixel-perfect replica of the floating media pill:
// 1. Artwork thumbnail on left
// 2. Surah & Ayah title + Connected Reciter/Bluetooth subtext in vibrant mint green
// 3. Audio output / AirPlay device icon in vibrant mint green
// 4. Saved/Library checkmark badge in vibrant mint green (tappable to bookmark)
// 5. Crisp white Play / Pause button
// 6. Hairline edge progress bar along the bottom of the pill
public struct AudioMiniPlayerView: View {
    @State private var playerService = AudioPlayerService.shared
    @State private var bookmarkService = BookmarkService.shared
    @State private var showingReciterSheet = false
    @State private var showingNowPlayingSheet = false
    var onTapExpand: () -> Void

    public init(onTapExpand: @escaping () -> Void = {}) {
        self.onTapExpand = onTapExpand
    }

    private var isBookmarked: Bool {
        guard let surah = playerService.currentSurah else { return false }
        return bookmarkService.isBookmarked(surahId: surah.id, ayahNumber: playerService.currentAyah)
    }

    private var progressRatio: Double {
        let duration = max(playerService.duration, 1.0)
        let time = playerService.currentTime
        guard duration > 0 && !time.isNaN && !duration.isNaN else { return 0.0 }
        return min(max(time / duration, 0.0), 1.0)
    }

    // Spotify Vibrant Green
    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public var body: some View {
        if let surah = playerService.currentSurah {
            ZStack(alignment: .bottom) {
                // Main Capsule Card
                HStack(spacing: 12) {
                    // MARK: - Left: Cover Artwork Thumbnail
                    Button {
                        showingNowPlayingSheet = true
                        onTapExpand()
                    } label: {
                        ZStack {
                            // Rounded Square Artwork Frame
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.08, green: 0.16, blue: 0.14),
                                            Color(red: 0.02, green: 0.05, blue: 0.07)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 42, height: 42)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(BayanTheme.gold.opacity(0.35), lineWidth: 1)
                                )

                            // Calligraphic Emblem / Surah Number
                            VStack(spacing: 1) {
                                Image(systemName: "book.pages.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(BayanTheme.gold)
                                Text("\(surah.id)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(BayanTheme.goldSoft)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    // MARK: - Middle: Title & Connected Reciter/Device Text
                    Button {
                        showingNowPlayingSheet = true
                        onTapExpand()
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            // Line 1: Song / Surah Title
                            Text("Surah \(surah.nameEnglish) • Ayah \(playerService.currentAyah)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            // Line 2: Connected Audio Device / Reciter in Spotify Green
                            HStack(spacing: 5) {
                                Image(systemName: "headphones")
                                    .font(.system(size: 10, weight: .semibold))

                                Text(playerService.currentReciter.nameEnglish)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .foregroundColor(spotifyGreen)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 4)

                    // MARK: - Right: Controls Strip
                    HStack(spacing: 14) {
                        // 1. Audio Output / Device Picker Icon (Spotify style screen+speaker icon)
                        Button {
                            showingReciterSheet = true
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            Image(systemName: "tv.and.mediabox")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(spotifyGreen)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)

                        // 2. Saved / Library Checkmark Badge (Exact Spotify Green Circle with Checkmark)
                        Button {
                            handleBookmarkTap(surah: surah)
                        } label: {
                            ZStack {
                                if isBookmarked {
                                    Circle()
                                        .fill(spotifyGreen)
                                        .frame(width: 22, height: 22)

                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(.black)
                                } else {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 21, weight: .regular))
                                        .foregroundColor(.white.opacity(0.65))
                                }
                            }
                            .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)

                        // 3. Play / Pause Button (Crisp White)
                        Button {
                            playerService.togglePlayPause()
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        } label: {
                            Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 19, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.13, blue: 0.15).opacity(0.97))
                )
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.09), lineWidth: 0.8)
                )

                // MARK: - Hairline Progress Bar Along Bottom Edge
                GeometryReader { geo in
                    let w = geo.size.width
                    ZStack(alignment: .leading) {
                        // Background track
                        Rectangle()
                            .fill(Color.white.opacity(0.18))
                            .frame(height: 2.5)

                        // Active playback fill
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: max(0, w * CGFloat(progressRatio)), height: 2.5)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(height: 2.5)
                .padding(.horizontal, 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.45), radius: 14, x: 0, y: 7)
            .sheet(isPresented: $showingReciterSheet) {
                ReciterPickerSheet(selectedReciter: $playerService.currentReciter)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingNowPlayingSheet) {
                BayanNowPlayingSheet()
                    .presentationDragIndicator(.visible)
            }
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity.combined(with: .scale(scale: 0.95))
            ))
        }
    }

    private func handleBookmarkTap(surah: Surah) {
        let arabicText = QuranVerseText.formattedAyah(surahId: surah.id, ayahNumber: playerService.currentAyah)
        let transText = QuranVerseText.translation(surahId: surah.id, ayahNumber: playerService.currentAyah)

        bookmarkService.toggleBookmark(
            surahId: surah.id,
            ayahNumber: playerService.currentAyah,
            surahNameArabic: surah.nameArabic,
            surahNameEnglish: surah.nameEnglish,
            arabicText: arabicText,
            translationText: transText
        )
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}
