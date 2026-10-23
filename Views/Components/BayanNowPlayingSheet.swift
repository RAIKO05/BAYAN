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
    @State private var showingSleepTimerSheet: Bool = false
    @State private var showingCastSheet: Bool = false
    @State private var showingReadAndUnderstand: Bool = false
    @State private var showingAudioFeaturesHub: Bool = false
    @State private var soundscapeService = AmbientSoundscapeService.shared
    @State private var castService = BayanCastService.shared
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
            // Dynamic Mood Atmosphere Background (Matching Spotify Midnight Indigo/Obsidian Canvas)
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.11, blue: 0.18),
                    Color(red: 0.05, green: 0.06, blue: 0.10),
                    Color(red: 0.03, green: 0.03, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - 1. Top Navigation Bar (Spotify Glass Header Style)
                HStack(alignment: .center) {
                    // Circular Translucent Glass Chevron Button
                    Button {
                        dismiss()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.22, green: 0.25, blue: 0.35).opacity(0.65))
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                )
                            Image(systemName: "chevron.down")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Header Context (Centered Title)
                    VStack(spacing: 2) {
                        Text("PLAYING FROM SURAH")
                            .font(.system(size: 9.5, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(.white.opacity(0.60))

                        Text("Surah \(currentSurah.nameEnglish) (\(currentSurah.nameArabic))")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Circular Translucent Glass More Options Button
                    Menu {
                        Button {
                            showingReadAndUnderstand = true
                        } label: {
                            Label("Read & Understand Mode", systemImage: "book.pages.fill")
                        }

                        Button {
                            showingAudioFeaturesHub = true
                        } label: {
                            Label("Audio Features Hub (6 Pillars)", systemImage: "sparkles")
                        }

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
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.22, green: 0.25, blue: 0.35).opacity(0.65))
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                )
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                // MARK: - 2. Upper Card: Cover Art, Title & Green Checkmark
                HStack(spacing: 14) {
                    // Reciter Portrait Button
                    Button {
                        showingReciterSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            ReciterAvatarView(
                                reciter: playerService.currentReciter,
                                size: 50,
                                isSelected: true,
                                borderWidth: 2.0,
                                hasGlow: true
                            )

                            Circle()
                                .fill(BayanTheme.gold)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.black)
                                )
                                .offset(x: 2, y: 2)
                        }
                    }
                    .buttonStyle(.plain)

                    // Title & Artist
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Surah \(currentSurah.nameEnglish) • Ayah \(playerService.currentAyah)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Button {
                            showingReciterSheet = true
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            HStack(spacing: 5) {
                                Text(playerService.currentReciter.nameEnglish)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                Text("(\(playerService.currentReciter.nameArabic))")
                                    .font(.system(size: 11))
                                    .foregroundColor(BayanTheme.goldSoft)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.40))
                            }
                        }
                        .buttonStyle(.plain)
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

                // MARK: - 4b. Secondary Audio Utilities (Speed, Dual Audio, Bedtime Sleep Timer)
                HStack(spacing: 0) {
                    // Recitation Speed Pill (0.75x, 1.0x, 1.25x, 1.5x)
                    Button {
                        playerService.cyclePlaybackRate()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "gauge.with.needle")
                                .font(.system(size: 11, weight: .bold))
                            Text(String(format: "%.2gx", playerService.playbackRate))
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(playerService.playbackRate != 1.0 ? spotifyGreen : .white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(playerService.playbackRate != 1.0 ? spotifyGreen.opacity(0.18) : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Dual Audio Mode (Arabic Recitation + English Translation Voiceover)
                    Button {
                        playerService.toggleDualAudio()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "globe")
                                .font(.system(size: 11, weight: .semibold))
                            Text("DUAL")
                                .font(.system(size: 10, weight: .heavy))
                            if playerService.isDualAudioEnabled {
                                Circle()
                                    .fill(playerService.isSpeakingTranslation ? Color.orange : spotifyGreen)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .foregroundColor(playerService.isDualAudioEnabled ? spotifyGreen : .white.opacity(0.65))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(playerService.isDualAudioEnabled ? spotifyGreen.opacity(0.18) : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Ambient Soundscapes Mixer Button
                    Button {
                        soundscapeService.toggle()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 4) {
                            Text(soundscapeService.currentSoundscape.emoji)
                                .font(.system(size: 11))
                            Text(soundscapeService.currentSoundscape == .off ? "Soundscape" : soundscapeService.currentSoundscape.title)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(soundscapeService.currentSoundscape != .off ? Color(red: 0.20, green: 0.85, blue: 0.95) : .white.opacity(0.65))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(soundscapeService.currentSoundscape != .off ? Color(red: 0.15, green: 0.45, blue: 0.65).opacity(0.35) : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }

                    Spacer()

                    // Bedtime Sleep Timer Button with Countdown
                    Button {
                        showingSleepTimerSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: playerService.sleepTimerOption != .off ? "moon.zzz.fill" : "moon.zzz")
                                .font(.system(size: 11, weight: .semibold))
                            if playerService.sleepTimerOption != .off {
                                if playerService.sleepTimerRemainingSeconds > 0 {
                                    Text(playerService.sleepTimerFormatted)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                } else {
                                    Text(playerService.sleepTimerOption == .endOfAyah ? "Ayah" : "Surah")
                                        .font(.system(size: 11, weight: .bold))
                                }
                            } else {
                                Text("Sleep")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                        .foregroundColor(playerService.sleepTimerOption != .off ? spotifyGreen : .white.opacity(0.65))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(playerService.sleepTimerOption != .off ? spotifyGreen.opacity(0.18) : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)

                // MARK: - 4c. Active A-B Memorization Loop Indicator
                if playerService.isABLoopActive {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat.1.ar")
                            .font(.system(size: 11, weight: .bold))
                        Text("A-B Loop: Ayah \(playerService.abStartAyah)-\(playerService.abEndAyah) • Pass \(playerService.abCurrentIteration)/\(playerService.abRepeatCount == Int.max ? "∞" : "\(playerService.abRepeatCount)")")
                            .font(.system(size: 11, weight: .bold))
                        Spacer()
                        Button("Stop") {
                            playerService.disableABLoop()
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red.opacity(0.9))
                    }
                    .foregroundColor(spotifyGreen)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(spotifyGreen.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }

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

                    // Read & Understand Quran Mode
                    Button {
                        showingReadAndUnderstand = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "character.book.closed.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Read & Understand")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(BayanTheme.gold)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(BayanTheme.gold.opacity(0.16))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(BayanTheme.gold.opacity(0.35), lineWidth: 0.8)
                        )
                    }

                    Spacer()

                    // Universal Cast & Device Output (AirPlay, Android & Windows DLNA)
                    Button {
                        showingCastSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: castService.isCasting ? castService.activeDeviceIcon : "tv.and.mediabox")
                                .font(.system(size: 15, weight: .semibold))
                            Text(castService.isCasting ? castService.connectedDeviceName : "Cast / AirPlay")
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                            if castService.isCasting {
                                Circle()
                                    .fill(spotifyGreen)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .foregroundColor(spotifyGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(spotifyGreen.opacity(0.14))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(spotifyGreen.opacity(0.35), lineWidth: 1)
                        )
                    }

                    Spacer()

                    // Reciter Quick Selector
                    Button {
                        showingReciterSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        ReciterAvatarView(
                            reciter: playerService.currentReciter,
                            size: 38,
                            isSelected: true,
                            borderWidth: 1.5,
                            hasGlow: true
                        )
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }
            .frame(maxWidth: 720)
        }
        .sheet(isPresented: $showingCastSheet) {
            BayanCastSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingReciterSheet) {
            ReciterPickerSheet(selectedReciter: $playerService.currentReciter)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingTafsirSheet) {
            AyahTafsirSheet(surah: currentSurah, ayahNumber: playerService.currentAyah)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingSleepTimerSheet) {
            SleepTimerPickerSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingReadAndUnderstand) {
            ReadAndUnderstandModalView()
        }
        .sheet(isPresented: $showingAudioFeaturesHub) {
            AudioFeaturesHubSheet()
                .presentationDetents([.medium, .large])
        }
        .gesture(
            DragGesture(minimumDistance: 25)
                .onEnded { value in
                    if value.translation.height > 90 {
                        dismiss()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }
                }
        )
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
                                    HStack(alignment: .top, spacing: 8) {
                                        Text(translation)
                                            .font(.system(size: isCurrent ? 14 : 12, weight: isCurrent ? .medium : .regular))
                                            .foregroundColor(isCurrent ? Color(red: 0.95, green: 0.82, blue: 0.45) : Color.white.opacity(0.25))
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        if isCurrent && playerService.isSpeakingTranslation {
                                            HStack(spacing: 4) {
                                                Image(systemName: "waveform")
                                                    .font(.system(size: 10, weight: .bold))
                                                Text("Voiceover")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            .foregroundColor(spotifyGreen)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(spotifyGreen.opacity(0.18))
                                            .clipShape(Capsule())
                                        }
                                    }
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

            // System & App Unified Sacred Artwork
            BayanArtworkView(surah: currentSurah, size: 285, cornerRadius: 26)

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

// MARK: - Bedtime Sleep Timer Selection Sheet
public struct SleepTimerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var playerService = AudioPlayerService.shared

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(AudioPlayerService.SleepTimerOption.allCases, id: \.title) { option in
                        Button {
                            playerService.setSleepTimer(option)
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                            dismiss()
                        } label: {
                            HStack {
                                Label {
                                    Text(option.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                } icon: {
                                    Image(systemName: option.iconName)
                                        .foregroundColor(playerService.sleepTimerOption == option ? spotifyGreen : Color.white.opacity(0.6))
                                }

                                Spacer()

                                if playerService.sleepTimerOption == option {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(spotifyGreen)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }
                } header: {
                    Text("Select Duration")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.6))
                } footer: {
                    Text("Audio volume will gently fade out over 2 seconds before pausing playback when the timer completes.")
                        .font(.system(size: 11))
                        .foregroundColor(Color.white.opacity(0.45))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.08, green: 0.08, blue: 0.10).ignoresSafeArea())
            .navigationTitle("Bedtime Sleep Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(spotifyGreen)
                }
            }
        }
    }
}
