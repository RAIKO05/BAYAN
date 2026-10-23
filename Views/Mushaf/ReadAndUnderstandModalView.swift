import SwiftUI

// MARK: - Read & Understand Quran While Listening (Modal View)
/// Direct implementation of Screenshot 4:
/// - Floating focus card for the currently playing Ayah
/// - Large, scalable Uthmanic Arabic calligraphy with (A- / A+) font controls
/// - Multi-language translation quick-switcher pills (English, Tafsir Al-Muyassar, French, Spanish, Turkish, Indonesian, Urdu)
/// - Ambient Soundscapes mixing pills (Waves, Rain, Haram, Breeze, Off) with live volume slider
/// - Ayah repetition controller pills (1x, 3x, 5x, ∞ Loop)
/// - One-tap Word-by-Word & Tafsir sheets
/// - Audio playback scrubber and gapless navigation
public struct ReadAndUnderstandModalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var playerService = AudioPlayerService.shared
    @State private var translationService = QuranTranslationService.shared
    @State private var soundscapeService = AmbientSoundscapeService.shared
    @State private var bookmarkService = BookmarkService.shared
    @State private var showingWordByWord: Bool = false
    @State private var showingFullTafsir: Bool = false
    @State private var showingReciterPicker: Bool = false
    @State private var showingSoundscapeSlider: Bool = false
    @State private var ayahFontSize: CGFloat = 28.0
    @State private var isDraggingScrubber: Bool = false
    @State private var dragPosition: Double = 0.0

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
        NavigationStack {
            ZStack {
                // Sacred Deep Obsidian & Indigo Background
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.09, blue: 0.15),
                        Color(red: 0.04, green: 0.05, blue: 0.08),
                        Color(red: 0.02, green: 0.03, blue: 0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Top Header Row
                    topHeaderView

                    // MARK: - Filter Pills (Language & Soundscapes)
                    filterPillsSection

                    // MARK: - Soundscape Volume Slider (Expandable)
                    if showingSoundscapeSlider && soundscapeService.currentSoundscape != .off {
                        soundscapeSliderView
                    }

                    // MARK: - Center Verse Content
                    verseContentView
                        .frame(maxHeight: .infinity)

                    // MARK: - Audio Playback Dock
                    playbackDockView
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingWordByWord) {
                WordByWordSheet(surah: currentSurah, ayahNumber: playerService.currentAyah)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingFullTafsir) {
                AyahTafsirSheet(surah: currentSurah, ayahNumber: playerService.currentAyah)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingReciterPicker) {
                ReciterPickerSheet(selectedReciter: $playerService.currentReciter)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - 1. Top Header Row
    private var topHeaderView: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text("READ & UNDERSTAND")
                    .font(.system(size: 9.5, weight: .bold))
                    .tracking(1.4)
                    .foregroundColor(BayanTheme.goldSoft)

                Text("Surah \(currentSurah.nameEnglish) (\(currentSurah.nameArabic))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Font size controls
            HStack(spacing: 6) {
                Button {
                    if ayahFontSize > 22 {
                        ayahFontSize -= 2
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }
                } label: {
                    Text("A-")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                }

                Button {
                    if ayahFontSize < 44 {
                        ayahFontSize += 2
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }
                } label: {
                    Text("A+")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - 2. Filter Pills Section (Language & Soundscapes)
    private var filterPillsSection: some View {
        VStack(spacing: 8) {
            // Language Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuranTranslationLanguage.allCases) { lang in
                        let isSelected = translationService.selectedLanguage == lang
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                translationService.selectedLanguage = lang
                            }
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            HStack(spacing: 5) {
                                Text(lang.flagEmoji)
                                    .font(.system(size: 11))
                                Text(lang.title)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            }
                            .foregroundColor(isSelected ? .black : .white.opacity(0.85))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                isSelected ?
                                AnyShapeStyle(BayanTheme.gold) :
                                AnyShapeStyle(Color.white.opacity(0.10))
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isSelected ? BayanTheme.gold : Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }

            // Soundscape Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(AmbientSoundscape.allCases) { sound in
                        let isSelected = soundscapeService.currentSoundscape == sound
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if soundscapeService.currentSoundscape == sound && sound != .off {
                                    showingSoundscapeSlider.toggle()
                                } else {
                                    soundscapeService.selectSoundscape(sound)
                                    if sound != .off {
                                        showingSoundscapeSlider = true
                                    } else {
                                        showingSoundscapeSlider = false
                                    }
                                }
                            }
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        } label: {
                            HStack(spacing: 4) {
                                Text(sound.emoji)
                                    .font(.system(size: 11))
                                Text(sound.title)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                if isSelected && sound != .off {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 9))
                                }
                            }
                            .foregroundColor(isSelected && sound != .off ? Color(red: 0.20, green: 0.85, blue: 0.95) : .white.opacity(0.75))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                isSelected && sound != .off ?
                                Color(red: 0.15, green: 0.45, blue: 0.65).opacity(0.35) :
                                Color.white.opacity(0.06)
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(
                                    isSelected && sound != .off ?
                                    Color(red: 0.20, green: 0.85, blue: 0.95).opacity(0.6) :
                                    Color.white.opacity(0.10),
                                    lineWidth: 1
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Expandable Soundscape Volume Slider
    private var soundscapeSliderView: some View {
        HStack(spacing: 12) {
            Image(systemName: soundscapeService.currentSoundscape.iconName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(red: 0.20, green: 0.85, blue: 0.95))

            Text("Soundscape Volume")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Slider(
                value: Binding(
                    get: { Double(soundscapeService.volume) },
                    set: { soundscapeService.volume = Float($0) }
                ),
                in: 0.05...1.0
            )
            .tint(Color(red: 0.20, green: 0.85, blue: 0.95))

            Text("\(Int(soundscapeService.volume * 100))%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.40))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }

    // MARK: - 3. Verse Content View
    private var verseContentView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(1...currentSurah.totalAyahs, id: \.self) { ayahNum in
                        let isCurrent = playerService.currentAyah == ayahNum
                        let arabic = QuranVerseText.formattedAyah(surahId: currentSurah.id, ayahNumber: ayahNum)
                        let translation = translationService.translation(for: currentSurah.id, ayahNumber: ayahNum)

                        VStack(spacing: 14) {
                            // Ayah Badge & Jump Button
                            HStack {
                                Text("Ayah \(ayahNum) of \(currentSurah.totalAyahs)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(isCurrent ? BayanTheme.gold : .white.opacity(0.50))

                                Spacer()

                                if isCurrent {
                                    HStack(spacing: 4) {
                                        Image(systemName: "waveform")
                                            .font(.system(size: 10, weight: .bold))
                                        Text("RECITING NOW")
                                            .font(.system(size: 9.5, weight: .heavy))
                                    }
                                    .foregroundColor(spotifyGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(spotifyGreen.opacity(0.18))
                                    .clipShape(Capsule())
                                }
                            }

                            // Large Calligraphic Arabic Verse
                            Text(arabic)
                                .font(.system(size: isCurrent ? ayahFontSize : ayahFontSize * 0.88, weight: .semibold, design: .serif))
                                .foregroundColor(isCurrent ? .white : .white.opacity(0.45))
                                .multilineTextAlignment(.trailing)
                                .lineSpacing(12)
                                .frame(maxWidth: .infinity, alignment: .trailing)

                            // Synchronized Translation / Tafsir
                            Text(translation)
                                .font(.system(
                                    size: isCurrent ? 15 : 13,
                                    weight: isCurrent ? .medium : .regular
                                ))
                                .foregroundColor(
                                    isCurrent ?
                                    Color(red: 0.95, green: 0.88, blue: 0.65) :
                                    Color.white.opacity(0.35)
                                )
                                .multilineTextAlignment(translationService.selectedLanguage.isRightToLeft ? .trailing : .leading)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: translationService.selectedLanguage.isRightToLeft ? .trailing : .leading
                                )

                            // In-Card Action Bar (when active)
                            if isCurrent {
                                HStack(spacing: 8) {
                                    Button {
                                        showingWordByWord = true
                                    } label: {
                                        Label("Word by Word", systemImage: "character.book.closed")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.85))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.10))
                                            .clipShape(Capsule())
                                    }

                                    Button {
                                        showingFullTafsir = true
                                    } label: {
                                        Label("Full Tafsir", systemImage: "book.pages")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.85))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.10))
                                            .clipShape(Capsule())
                                    }

                                    Spacer()

                                    // Ayah Repeat Controller Pills (1x, 3x, 5x, ∞)
                                    repetitionPickerView
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isCurrent ? Color.white.opacity(0.08) : Color.white.opacity(0.02))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    isCurrent ? BayanTheme.gold.opacity(0.65) : Color.white.opacity(0.05),
                                    lineWidth: isCurrent ? 1.5 : 0.8
                                )
                        )
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            playerService.play(surah: currentSurah, ayah: ayahNum)
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        }
                        .id(ayahNum)
                    }
                }
                .padding(.vertical, 12)
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

    // MARK: - Repetition Picker View (1x, 3x, 5x, ∞)
    private var repetitionPickerView: some View {
        HStack(spacing: 4) {
            repeatPill(title: "1x", mode: .off)
            repeatPill(title: "3x", mode: .repeatAyah(count: 3))
            repeatPill(title: "5x", mode: .repeatAyah(count: 5))
            repeatPill(title: "∞", mode: .repeatAyah(count: Int.max))
        }
    }

    private func repeatPill(title: String, mode: AudioPlayerService.RepeatMode) -> some View {
        let isSelected: Bool = {
            switch (playerService.repeatMode, mode) {
            case (.off, .off): return true
            case (.repeatAyah(let c1), .repeatAyah(let c2)): return c1 == c2
            default: return false
            }
        }()

        return Button {
            playerService.setRepeatMode(mode)
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .black : .white.opacity(0.70))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(isSelected ? BayanTheme.gold : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Audio Playback Dock
    private var playbackDockView: some View {
        VStack(spacing: 8) {
            // Scrubber
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 4)

                    Capsule()
                        .fill(BayanTheme.gold)
                        .frame(width: max(0, w * CGFloat(currentProgress)), height: 4)
                }
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
                        }
                )
            }
            .frame(height: 14)
            .padding(.horizontal, 20)

            // Reciter & Controls Row
            HStack(spacing: 0) {
                // Reciter Thumbnail
                Button {
                    showingReciterPicker = true
                } label: {
                    HStack(spacing: 8) {
                        ReciterAvatarView(
                            reciter: playerService.currentReciter,
                            size: 38,
                            isSelected: true,
                            borderWidth: 1.5,
                            hasGlow: true
                        )

                        VStack(alignment: .leading, spacing: 1) {
                            Text(playerService.currentReciter.nameEnglish)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(playerService.currentReciter.riwayah)
                                .font(.system(size: 10))
                                .foregroundColor(BayanTheme.goldSoft)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Playback Controls
                HStack(spacing: 16) {
                    Button {
                        playerService.previousAyah()
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Button {
                        playerService.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(BayanTheme.gold)
                                .frame(width: 48, height: 48)
                            Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: playerService.isPlaying ? 0 : 1.5)
                        }
                    }

                    Button {
                        playerService.nextAyah()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Bookmark & Share Actions
                HStack(spacing: 12) {
                    Button {
                        toggleBookmark()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 18))
                            .foregroundColor(isBookmarked ? BayanTheme.gold : .white.opacity(0.65))
                    }

                    Button {
                        copyOrShareAyah()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(
            Color(red: 0.05, green: 0.06, blue: 0.10)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func toggleBookmark() {
        let arabic = QuranVerseText.formattedAyah(surahId: currentSurah.id, ayahNumber: playerService.currentAyah)
        let trans = translationService.translation(for: currentSurah.id, ayahNumber: playerService.currentAyah)

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

    private func copyOrShareAyah() {
        #if os(iOS)
        let arabic = QuranVerseText.formattedAyah(surahId: currentSurah.id, ayahNumber: playerService.currentAyah)
        let trans = translationService.translation(for: currentSurah.id, ayahNumber: playerService.currentAyah)
        let fullText = "\(arabic)\n\n\(trans)\n— [Surah \(currentSurah.nameEnglish) (\(currentSurah.nameArabic)) • Ayah \(playerService.currentAyah)]\nRecited by \(playerService.currentReciter.nameEnglish)\nShared via Bayan"
        UIPasteboard.general.string = fullText
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
