import SwiftUI

struct RecognitionResultSheet: View {
    let result: RecognitionResult
    var onOpenInMushaf: (Surah, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var playerService = AudioPlayerService.shared

    var body: some View {
        ZStack {
            // Background
            BayanTheme.obsidian.ignoresSafeArea()
            RadialGradient(
                colors: [BayanTheme.deepEmerald.opacity(0.8), Color.clear],
                center: .top,
                startRadius: 50,
                endRadius: 450
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header Handle
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)

                    // Match Confidence Badge
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(BayanTheme.gold)
                        Text("IDENTIFIED WITH \(Int(result.confidence * 100))% CONFIDENCE")
                            .font(.caption2.weight(.bold))
                            .tracking(1.5)
                            .foregroundColor(BayanTheme.goldSoft)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(BayanTheme.gold.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(BayanTheme.gold.opacity(0.3), lineWidth: 1))

                    // Surah Main Card
                    VStack(spacing: 12) {
                        Text(result.surah.nameArabic)
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("\(result.surah.nameEnglish) • Ayah \(result.startAyah)–\(result.endAyah)")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(BayanTheme.goldSoft)

                        // Reciter Tag
                        HStack(spacing: 8) {
                            Image(systemName: "person.wave.2.fill")
                                .foregroundColor(BayanTheme.gold)
                            Text(result.reciter.nameEnglish)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.9))
                            Text("(\(result.reciter.riwayah.rawValue))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .liquidGlass(isGoldBorder: true)
                    .padding(.horizontal)

                    // Arabic Text Box
                    VStack(alignment: .trailing, spacing: 14) {
                        HStack {
                            // Bookmark Favorite Toggle
                            Button {
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                                BookmarkService.shared.toggleBookmark(
                                    surahId: result.surah.id,
                                    ayahNumber: result.startAyah,
                                    surahNameArabic: result.surah.nameArabic,
                                    surahNameEnglish: result.surah.nameEnglish,
                                    arabicText: result.arabicSnippet,
                                    translationText: result.translationSnippet
                                )
                            } label: {
                                let isBookmarked = BookmarkService.shared.isBookmarked(surahId: result.surah.id, ayahNumber: result.startAyah)
                                HStack(spacing: 5) {
                                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(isBookmarked ? BayanTheme.gold : .white.opacity(0.6))
                                    Text(isBookmarked ? "Saved" : "Save Ayah")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(isBookmarked ? BayanTheme.goldSoft : .white.opacity(0.7))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(isBookmarked ? BayanTheme.gold.opacity(0.18) : Color.white.opacity(0.08)))
                                .overlay(Capsule().stroke(isBookmarked ? BayanTheme.gold.opacity(0.4) : Color.clear, lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Label("النص القرآني", systemImage: "text.book.closed.fill")
                                .font(.caption.weight(.bold))
                                .foregroundColor(BayanTheme.gold)
                        }

                        Text(result.arabicSnippet)
                            .font(.system(size: 24, weight: .regular, design: .serif))
                            .lineSpacing(12)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)

                        Divider().overlay(Color.white.opacity(0.15))

                        Text(result.translationSnippet)
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                    .liquidGlass()
                    .padding(.horizontal)

                    // Audio Playback & Actions
                    VStack(spacing: 14) {
                        Button {
                            playerService.play(
                                surah: result.surah,
                                ayah: result.startAyah,
                                reciter: result.reciter
                            )
                        } label: {
                            HStack {
                                Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                                Text(playerService.isPlaying ? "PAUSE RECITATION" : "PLAY RECITATION")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [BayanTheme.gold, BayanTheme.gold.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(BayanTheme.obsidian)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: BayanTheme.gold.opacity(0.35), radius: 10, y: 5)
                        }

                        Button {
                            dismiss()
                            onOpenInMushaf(result.surah, result.startAyah)
                        } label: {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Open in Full Quran")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
