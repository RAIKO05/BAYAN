import SwiftUI

// MARK: - Global Audio Mini-Player View
// Persistent Spotify-style mini-player floating above the navigation dock
public struct AudioMiniPlayerView: View {
    @State private var playerService = AudioPlayerService.shared
    var onTapExpand: () -> Void

    public init(onTapExpand: @escaping () -> Void = {}) {
        self.onTapExpand = onTapExpand
    }

    public var body: some View {
        if let surah = playerService.currentSurah {
            HStack(spacing: 12) {
                // Tappable info area
                Button(action: onTapExpand) {
                    HStack(spacing: 12) {
                        // Animated Waveform Orb / Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [BayanTheme.gold.opacity(0.3), BayanTheme.deepEmerald.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle().stroke(BayanTheme.gold.opacity(0.5), lineWidth: 1)
                                )

                            Image(systemName: playerService.isPlaying ? "waveform" : "music.note")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(BayanTheme.goldSoft)
                                .symbolEffect(.variableColor.iterative, isActive: playerService.isPlaying)
                        }

                        // Surah & Reciter Text
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(surah.nameEnglish)
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)

                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(BayanTheme.goldSoft)

                                Text(surah.nameArabic)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(BayanTheme.goldSoft)
                            }

                            HStack(spacing: 4) {
                                Text(playerService.currentReciter.nameEnglish)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)

                                Text("•")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.4))

                                Text("Ayah \(playerService.currentAyah)")
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(BayanTheme.electricCyan)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Play / Pause Toggle Button
                Button {
                    playerService.togglePlayPause()
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                } label: {
                    Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(BayanTheme.obsidian)
                        .frame(width: 36, height: 36)
                        .background(BayanTheme.gold)
                        .clipShape(Circle())
                        .shadow(color: BayanTheme.gold.opacity(0.4), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                // Close Button
                Button {
                    playerService.stop()
                    playerService.currentSurah = nil
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.65))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .liquidGlass(cornerRadius: 26, isGoldBorder: true)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity.combined(with: .scale(scale: 0.95))
            ))
        }
    }
}
