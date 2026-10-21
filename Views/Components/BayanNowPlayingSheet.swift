import SwiftUI

// MARK: - Spotify-Style Full-Screen Now Playing Sheet with Synchronized Lyrics
// Replicates Spotify's iconic full-screen player:
// 1. Top bar with collapse chevron, header title, and more options
// 2. Header card with cover art thumbnail, Surah & Ayah title, and green saved checkmark
// 3. Center: Synchronized Lyrics (Quran Verses) with active verse highlighted in bold white
//    and upcoming/preceding verses dimmed/blurred; tapping any line jumps playback
// 4. Toggle between Lyrics View and Full Cover Artwork View
// 5. Draggable audio scrubber with elapsed & remaining time labels
// 6. Full playback controls (Repeat/Hifz loop, Previous Ayah, Large Play/Pause, Next Ayah)
// 7. Bottom bar with Lyrics toggle (speech bubble), AirPlay output, and Surah index
public struct BayanNowPlayingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var playerService = AudioPlayerService.shared
    @State private var bookmarkService = BookmarkService.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var showingLyricsMode: Bool = true
    @State private var showingReciterSheet: Bool = false
    @State private var showingTafsirSheet: Bool = false
    @State private var isDraggingScrubber: Bool = false
    @State private var dragPosition: Double = 0.0

    // Spotify Vibrant Green Token
    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    private var currentSurah: Surah {
        playerService.currentSurah ?? Surah.sampleFatihah
    }

    private var isBookmarked: Bool {
        bookmarkService.isBookmarked(surahId: currentSurah.id, ayahNumber: playerService.currentAyah)
    }

    private var safeDuration: Double {
        max(playerService.duration, 1.0)
    }

    private var currentProgress: Double {
        let activeTime = isDraggingScrubber ? dragPosition : playerService.currentTime
        return min(max(activeTime / safeDuration, 0.0), 1.0)
    }

    public init() {}

    public var body: some View {
        ZStack {
            // Dynamic Mood Atmosphere Background (matching album artwork)
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.11, blue: 0.06),
                    Color(red: 0.08, green: 0.08, blue: 0.10),
                    Color(red: 0.04, green: 0.04, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - 1. Top Navigation Bar
                HStack {
                    // Chevron Down to collapse
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }

                    Spacer()

                    // Header Context
                    VStack(spacing: 2) {
                        Text("PLAYING FROM SURAH")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(.white.opacity(0.65))

                        Text("Surah \(currentSurah.nameEnglish) (\(currentSurah.nameArabic))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // More Options Button
                    Menu {
                        Button {
                            showingTafsirSheet = true
                        } label: {
                            Label("View Tafsir & Insights", systemImage: "book.pages")
                        }

                        Button {
                            showingReciterSheet = true
                        } label: {
                            Label("Change Reciter", systemImage: "person.wave.2")
                        }

                        Button {
                            #if os(iOS)
                            let text = "\(QuranVerseText.arabic(surahId: currentSurah.id, ayahNumber: playerService.currentAyah))\n\n\(QuranVerseText.translation(surahId: currentSurah.id, ayahNumber: playerService.currentAyah))"
                            UIPasteboard.general.string = text
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            Label("Copy Ayah Text", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // MARK: - 2. Upper Card: Cover Art, Title & Green Checkmark
                HStack(spacing: 14) {
                    // Thumbnail Artwork
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.22, green: 0.16, blue: 0.08),
                                        Color(red: 0.08, green: 0.06, blue: 0.03)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(BayanTheme.gold.opacity(0.4), lineWidth: 1)
                            )

                        VStack(spacing: 1) {
                            Text("القرآن")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(BayanTheme.gold)
                            Text("\(currentSurah.id)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(BayanTheme.goldSoft)
                        }
                    }
                    .shadow(color: Color.black.opacity(0.35), radius: 6, y: 3)

                    // Title & Artist
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Surah \(currentSurah.nameEnglish) • Ayah \(playerService.currentAyah)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(playerService.currentReciter.nameEnglish)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.70))
                            .lineLimit(1)
                    }

                    Spacer()

                    // Saved Checkmark Badge in Spotify Green
                    Button {
                        toggleBookmark()
                    } label: {
                        ZStack {
                            if isBookmarked {
                                Circle()
                                    .fill(spotifyGreen)
                                    .frame(width: 26, height: 26)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(.black)
                            } else {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                .padding(.bottom, 10)

                // MARK: - 3. Center Content Area (Lyrics Mode OR Full Cover Art Mode)
                ZStack {
                    if showingLyricsMode {
                        // MARK: Real-Time Synchronized Quran "Lyrics" (Verses)
                        lyricsScrollView
                    } else {
                        // MARK: Full Large Cover Art Mode
                        coverArtView
                    }
                }
                .frame(maxHeight: .infinity)

                // MARK: - 4. Interactive Scrubber & Time Labels
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        let w = geo.size.width
                        ZStack(alignment: .leading) {
                            // Background rail
                            Capsule()
                                .fill(Color.white.opacity(0.20))
                                .frame(height: isDraggingScrubber ? 6 : 4)

                            // Active progress fill
                            Capsule()
                                .fill(Color.white)
                                .frame(width: max(0, w * CGFloat(currentProgress)), height: isDraggingScrubber ? 6 : 4)

                            // Thumb knob
                            if isDraggingScrubber {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                    .shadow(color: Color.black.opacity(0.4), radius: 4)
                                    .offset(x: min(max(0, w * CGFloat(currentProgress) - 7), w - 14))
                            }
                        }
                        .frame(height: 20)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDraggingScrubber = true
                                    let clampedX = min(max(0, value.location.x), w)
                                    dragPosition = (clampedX / w) * safeDuration
                                }
                                .onEnded { value in
                                    let clampedX = min(max(0, value.location.x), w)
                                    let finalTime = (clampedX / w) * safeDuration
                                    playerService.seek(to: finalTime)
                                    isDraggingScrubber = false
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                }
                        )
                    }
                    .frame(height: 18)

                    // Time labels
                    HStack {
                        let activeTime = isDraggingScrubber ? dragPosition : playerService.currentTime
                        Text(formatTime(activeTime))
                        Spacer()
                        Text("-" + formatTime(max(0, safeDuration - activeTime)))
                    }
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.60))
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                // MARK: - 5. Playback Controls Row
                HStack(spacing: 0) {
                    // Repeat / Hifz Memorization Loop Toggle
                    Button {
                        playerService.cycleRepeatMode()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: playerService.repeatMode.iconName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(playerService.repeatMode.isRepeating ? spotifyGreen : .white.opacity(0.70))
                            .frame(maxWidth: .infinity)
                    }

                    // Previous Ayah
                    Button {
                        playerService.previousAyah()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }

                    // Main Large Play / Pause Circle
                    Button {
                        playerService.togglePlayPause()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 64, height: 64)
                                .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)

                            Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color.black)
                                .offset(x: playerService.isPlaying ? 0 : 2)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Next Ayah
                    Button {
                        playerService.nextAyah()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }

                    // Tafsir Quick Action
                    Button {
                        showingTafsirSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "book.pages")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // MARK: - 6. Bottom Utility Dock
                HStack {
                    // Lyrics Toggle Button (Speech bubble with quotation)
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showingLyricsMode.toggle()
                        }
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(showingLyricsMode ? spotifyGreen : .white.opacity(0.55))
                            .frame(width: 40, height: 40)
                    }

                    Spacer()

                    // Connected Device / Reciter Output
                    Button {
                        showingReciterSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "tv.and.mediabox")
                                .font(.system(size: 15, weight: .semibold))
                            Text(playerService.currentReciter.nameEnglish)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                        }
                        .foregroundColor(spotifyGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(spotifyGreen.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Queue / Surah Index
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showingReciterSheet) {
            ReciterPickerSheet(selectedReciter: $playerService.currentReciter)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingTafsirSheet) {
            AyahTafsirSheet(surah: currentSurah, ayahNumber: playerService.currentAyah)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Synchronized Lyrics View (Quran Verses)
    private var lyricsScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 24) {
                    ForEach(1...currentSurah.totalAyahs, id: \.self) { ayahNum in
                        let isCurrent = playerService.currentAyah == ayahNum
                        let arabicText = QuranVerseText.arabic(surahId: currentSurah.id, ayahNumber: ayahNum)
                        let translation = QuranVerseText.translation(surahId: currentSurah.id, ayahNumber: ayahNum)

                        Button {
                            playerService.play(surah: currentSurah, ayah: ayahNum)
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        } label: {
                            VStack(alignment: .trailing, spacing: 8) {
                                // Arabic Verse Line
                                Text(arabicText)
                                    .font(.system(size: isCurrent ? 26 : 22, weight: isCurrent ? .bold : .medium, design: .serif))
                                    .foregroundColor(isCurrent ? .white : Color.white.opacity(0.38))
                                    .multilineTextAlignment(.trailing)
                                    .lineSpacing(10)
                                    .blur(radius: isCurrent ? 0 : 0.35)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                // Translation (shown when active or lightly dimmed)
                                if !translation.isEmpty {
                                    Text(translation)
                                        .font(.system(size: isCurrent ? 14 : 12, weight: isCurrent ? .medium : .regular))
                                        .foregroundColor(isCurrent ? Color(red: 0.95, green: 0.82, blue: 0.45) : Color.white.opacity(0.25))
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 22)
                            .padding(.vertical, 6)
                            .background(isCurrent ? Color.white.opacity(0.06) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .id(ayahNum)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .onChange(of: playerService.currentAyah) { _, newAyah in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                    proxy.scrollTo(newAyah, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(playerService.currentAyah, anchor: .center)
            }
        }
    }

    // MARK: - Full Cover Artwork View
    private var coverArtView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                // Outer Ambient Glow
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.30, green: 0.20, blue: 0.08),
                                Color(red: 0.10, green: 0.08, blue: 0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)
                    .shadow(color: Color.black.opacity(0.6), radius: 24, y: 12)

                // Gold Filigree Border
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                BayanTheme.gold,
                                BayanTheme.gold.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 280, height: 280)

                // Illuminated Central Motifs
                VStack(spacing: 12) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(BayanTheme.gold)

                    Text(currentSurah.nameArabic)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text(currentSurah.revelationType.arabicTitle + " • " + "\(currentSurah.totalAyahs) آية")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(BayanTheme.goldSoft)
                }
            }

            Spacer()
        }
    }

    private func toggleBookmark() {
        let arabic = QuranVerseText.formattedAyah(surahId: currentSurah.id, ayahNumber: playerService.currentAyah)
        let trans = QuranVerseText.translation(surahId: currentSurah.id, ayahNumber: playerService.currentAyah)

        bookmarkService.toggleBookmark(
            surahId: currentSurah.id,
            ayahNumber: playerService.currentAyah,
            surahNameArabic: currentSurah.nameArabic,
            surahNameEnglish: currentSurah.nameEnglish,
            arabicText: arabic,
            translationText: trans
        )
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "0:00" }
        let total = Int(max(0, seconds))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
