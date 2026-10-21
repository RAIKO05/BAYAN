import SwiftUI

struct HifzCompanionView: View {
    @Environment(\.dismiss) private var dismiss
    public let initialSurah: Surah
    public let initialAyah: Int

    @State private var currentAyahNumber: Int
    @State private var hifzMode: HifzMode = .wordReveal
    @State private var revealedIndices: Set<Int> = []
    @State private var masteredAyahs: Set<Int> = []
    @State private var isPlayingAudio: Bool = false

    public enum HifzMode: String, CaseIterable, Identifiable {
        case wordReveal = "Word Reveal • كشف الكلمات"
        case firstLetter = "First Letter • الحرف الأول"
        case fullBlank = "Full Recall • استرجاع كامل"

        public var id: String { rawValue }
    }

    public init(surah: Surah, initialAyah: Int = 1) {
        self.initialSurah = surah
        self.initialAyah = initialAyah
        _currentAyahNumber = State(initialValue: initialAyah)
    }

    private var currentVerseWords: [String] {
        let text = QuranVerseText.arabic(surahId: initialSurah.id, ayahNumber: currentAyahNumber)
        return text.split(separator: " ").map(String.init)
    }

    private var isAyahMastered: Bool {
        masteredAyahs.contains(currentAyahNumber)
    }

    private func toggleMastery() {
        if isAyahMastered {
            masteredAyahs.remove(currentAyahNumber)
        } else {
            masteredAyahs.insert(currentAyahNumber)
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                BayanTheme.obsidian.ignoresSafeArea()

                VStack(spacing: 16) {
                    // Mode Picker
                    Picker("Hifz Mode", selection: $hifzMode) {
                        ForEach(HifzMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Header Info
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(initialSurah.nameEnglish) • Ayah \(currentAyahNumber)")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                            Text("Surah \(initialSurah.id) • \(initialSurah.nameArabic)")
                                .font(.caption)
                                .foregroundColor(BayanTheme.goldSoft)
                        }

                        Spacer()

                        Button {
                            toggleMastery()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isAyahMastered ? "checkmark.seal.fill" : "seal")
                                    .font(.subheadline)
                                Text(isAyahMastered ? "Mastered" : "Mark Mastered")
                                    .font(.caption.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isAyahMastered ? BayanTheme.gold : Color.white.opacity(0.08))
                            .foregroundColor(isAyahMastered ? BayanTheme.obsidian : .white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20)

                    // Verse Memorization Card
                    ScrollView {
                        VStack(spacing: 20) {
                            // Flow of Words / Masked Tokens
                            HifzWordsFlowView(
                                words: currentVerseWords,
                                mode: hifzMode,
                                revealedIndices: $revealedIndices
                            )
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(isAyahMastered ? BayanTheme.gold.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
                            )
                            .padding(.horizontal)

                            // Quick Action Tools
                            HStack(spacing: 12) {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        revealedIndices.removeAll()
                                    }
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                } label: {
                                    Label("Hide All", systemImage: "eye.slash.fill")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.08))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }

                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        revealedIndices = Set(0..<currentVerseWords.count)
                                    }
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                } label: {
                                    Label("Reveal All", systemImage: "eye.fill")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.08))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }

                                Spacer()

                                // Audio verification button
                                Button {
                                    if AudioPlayerService.shared.isPlaying {
                                        AudioPlayerService.shared.pause()
                                    } else {
                                        AudioPlayerService.shared.play(surah: initialSurah, ayah: currentAyahNumber)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: AudioPlayerService.shared.isPlaying ? "pause.fill" : "play.fill")
                                        Text(AudioPlayerService.shared.isPlaying ? "Pause" : "Listen")
                                    }
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(BayanTheme.gold)
                                    .foregroundColor(BayanTheme.obsidian)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 20)

                            // Verse Translation
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Translation")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(BayanTheme.goldSoft)
                                Text(QuranVerseText.translation(surahId: initialSurah.id, ayahNumber: currentAyahNumber))
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }

                    // Navigation Bar (Previous / Next Ayah)
                    HStack(spacing: 24) {
                        Button {
                            if currentAyahNumber > 1 {
                                withAnimation {
                                    currentAyahNumber -= 1
                                    revealedIndices.removeAll()
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.backward.circle.fill")
                                .font(.system(size: 38))
                                .foregroundColor(currentAyahNumber > 1 ? BayanTheme.gold : Color.white.opacity(0.2))
                        }
                        .disabled(currentAyahNumber <= 1)

                        Text("Ayah \(currentAyahNumber) / \(initialSurah.totalAyahs)")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)

                        Button {
                            if currentAyahNumber < initialSurah.totalAyahs {
                                withAnimation {
                                    currentAyahNumber += 1
                                    revealedIndices.removeAll()
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.forward.circle.fill")
                                .font(.system(size: 38))
                                .foregroundColor(currentAyahNumber < initialSurah.totalAyahs ? BayanTheme.gold : Color.white.opacity(0.2))
                        }
                        .disabled(currentAyahNumber >= initialSurah.totalAyahs)
                    }
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Hifz Companion (تحفيظ القرآن)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BayanTheme.gold)
                }
            }
        }
    }
}

// MARK: - Flow of Arabic Words with Tap-to-Reveal
private struct HifzWordsFlowView: View {
    let words: [String]
    let mode: HifzCompanionView.HifzMode
    @Binding var revealedIndices: Set<Int>

    var body: some View {
        // RTL wrap layout for Arabic words
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70, maximum: 140), spacing: 8)], spacing: 10) {
            ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                let isRevealed = revealedIndices.contains(index)

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        if isRevealed {
                            revealedIndices.remove(index)
                        } else {
                            revealedIndices.insert(index)
                        }
                    }
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    ZStack {
                        if isRevealed || mode == .fullBlank {
                            Text(word)
                                .font(.custom("AmiriQuran-Regular", size: 21))
                                .foregroundColor(isRevealed ? .white : Color.white.opacity(0.01))
                        } else if mode == .firstLetter {
                            let firstLetter = String(word.prefix(1))
                            Text("\(firstLetter)...")
                                .font(.custom("AmiriQuran-Regular", size: 20))
                                .foregroundColor(BayanTheme.goldSoft)
                        } else {
                            // Masked word pill
                            RoundedRectangle(cornerRadius: 8)
                                .fill(BayanTheme.gold.opacity(0.2))
                                .frame(height: 28)
                                .overlay(
                                    Image(systemName: "questionmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(BayanTheme.gold)
                                )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isRevealed ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isRevealed ? BayanTheme.gold.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
