import SwiftUI

// MARK: - Word-by-Word Quran Meaning Sheet
/// Displays individual words of a Quranic verse with authentic calligraphy,
/// phonetic transliteration, direct vocabulary translation, root letters, and pronunciation.
struct WordByWordSheet: View {
    @Environment(\.dismiss) private var dismiss
    let surah: Surah
    let ayahNumber: Int

    @State private var wordService = QuranWordByWordService.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var words: [QuranWord] = []
    @State private var activeSpeakingWordId: String? = nil

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    init(surah: Surah, ayahNumber: Int) {
        self.surah = surah
        self.ayahNumber = ayahNumber
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Verse Context Banner
                        VStack(spacing: 10) {
                            HStack {
                                Text("\(surah.nameArabic) • Ayah \(ayahNumber)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(BayanTheme.gold)

                                Spacer()

                                Text("\(words.count) Words")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Capsule())
                            }

                            Text(QuranVerseText.formattedAyah(surahId: surah.id, ayahNumber: ayahNumber))
                                .font(.quran(size: 24))
                                .multilineTextAlignment(.center)
                                .lineSpacing(10)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)

                            Text(QuranVerseText.translation(surahId: surah.id, ayahNumber: ayahNumber))
                                .font(.system(size: 13.5))
                                .foregroundColor(.white.opacity(0.75))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.92))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(BayanTheme.gold.opacity(0.25), lineWidth: 1)
                                )
                        )

                        // MARK: - Word-by-Word Cards (Horizontal or Adaptive Grid)
                        VStack(spacing: 12) {
                            ForEach(words) { word in
                                wordCard(word: word)
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Word by Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BayanTheme.gold)
                    .font(.system(size: 14, weight: .bold))
                }
            }
            .onAppear {
                self.words = wordService.words(for: surah.id, ayahNumber: ayahNumber)
            }
        }
    }

    private func wordCard(word: QuranWord) -> some View {
        HStack(spacing: 14) {
            // Pronunciation Speaker Button
            Button {
                activeSpeakingWordId = word.id
                wordService.speakWord(word: word)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    if activeSpeakingWordId == word.id {
                        activeSpeakingWordId = nil
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(activeSpeakingWordId == word.id ? spotifyGreen.opacity(0.25) : Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(activeSpeakingWordId == word.id ? spotifyGreen : Color.white.opacity(0.1), lineWidth: 1)
                        )

                    Image(systemName: activeSpeakingWordId == word.id ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .font(.system(size: 17))
                        .foregroundColor(activeSpeakingWordId == word.id ? spotifyGreen : BayanTheme.gold)
                }
            }

            // Word Meanings & Grammar Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(word.transliteration)
                        .font(.system(size: 14, weight: .bold, design: .serif))
                        .foregroundColor(BayanTheme.gold)

                    if let role = word.grammarRole {
                        Text(role)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }

                    if let root = word.rootLetters {
                        HStack(spacing: 2) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 8))
                            Text(root)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(spotifyGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(spotifyGreen.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }

                Text(word.translation)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }

            Spacer()

            // Large Uthmanic Arabic Calligraphy Word
            VStack(alignment: .trailing, spacing: 2) {
                Text(word.arabic)
                    .font(.quran(size: 26))
                    .foregroundColor(activeSpeakingWordId == word.id ? spotifyGreen : .white)
                    .multilineTextAlignment(.trailing)

                Text("#\(word.wordIndex)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.11, green: 0.12, blue: 0.16).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(activeSpeakingWordId == word.id ? spotifyGreen.opacity(0.6) : Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}
