import SwiftUI

struct HistoryView: View {
    @State private var syncManager = QuranSyncManager.shared
    @State private var playerService = AudioPlayerService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                BayanTheme.obsidian.ignoresSafeArea()
                RadialGradient(
                    colors: [BayanTheme.deepEmerald.opacity(0.35), Color.clear],
                    center: .top,
                    startRadius: 50,
                    endRadius: 400
                )
                .ignoresSafeArea()

                if syncManager.recentRecognitions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 64))
                            .foregroundColor(BayanTheme.gold.opacity(0.5))

                        Text("No Recognitions Yet")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)

                        Text("Recitations you identify in the Listen tab will be automatically saved here for quick review.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(syncManager.recentRecognitions) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(item.surah.nameArabic)
                                        .font(.title3.weight(.bold))
                                        .foregroundColor(BayanTheme.goldSoft)

                                    Spacer()

                                    Text(item.recognizedAt, format: .dateTime.month().day().hour().minute())
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Text("\(item.surah.nameEnglish) • Ayah \(item.startAyah)–\(item.endAyah)")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                HStack(spacing: 8) {
                                    Image(systemName: "person.wave.2.fill")
                                        .foregroundColor(BayanTheme.gold)
                                    Text(item.reciter.nameEnglish)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                Text(item.arabicSnippet)
                                    .font(.system(size: 16, design: .serif))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .trailing)

                                // Quick Play Action
                                let isThisItemPlaying = playerService.isPlaying && playerService.currentSurah?.id == item.surah.id
                                Button {
                                    if isThisItemPlaying {
                                        playerService.togglePlayPause()
                                    } else {
                                        playerService.play(
                                            surah: item.surah,
                                            ayah: item.startAyah,
                                            reciter: item.reciter
                                        )
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: isThisItemPlaying ? "pause.fill" : "play.fill")
                                        Text(isThisItemPlaying ? "Pause" : "Play Recitation")
                                    }
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(BayanTheme.obsidian)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(BayanTheme.gold)
                                    .clipShape(Capsule())
                                }
                                .padding(.top, 4)
                            }
                            .padding(16)
                            .liquidGlass(cornerRadius: 18)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 120) }
                }
            }
            .navigationTitle("Recognized History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
