import SwiftUI

// MARK: - Global Audio Mini-Player View
// Persistent Spotify-style mini-player floating above the navigation dock
// Features: Real-time progress scrubber, ±15s seek, Play/Pause, Surah/Reciter info
public struct AudioMiniPlayerView: View {
    @State private var playerService = AudioPlayerService.shared
    @State private var isDragging: Bool = false
    @State private var dragPosition: Double = 0.0
    var onTapExpand: () -> Void

    public init(onTapExpand: @escaping () -> Void = {}) {
        self.onTapExpand = onTapExpand
    }

    public var body: some View {
        if let surah = playerService.currentSurah {
            VStack(spacing: 4) {
                // MARK: - Interactive Audio Progress Scrubber
                GeometryReader { geometry in
                    let totalWidth = geometry.size.width
                    let activeTime = isDragging ? dragPosition : playerService.currentTime
                    let safeDuration = max(playerService.duration, 1.0)
                    let progress = min(max(activeTime / safeDuration, 0.0), 1.0)

                    ZStack(alignment: .leading) {
                        // Background Track
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: isDragging ? 6 : 3.5)

                        // Progress Fill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [BayanTheme.goldSoft, BayanTheme.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, totalWidth * CGFloat(progress)), height: isDragging ? 6 : 3.5)

                        // Drag Thumb Orb
                        if isDragging {
                            Circle()
                                .fill(BayanTheme.gold)
                                .frame(width: 14, height: 14)
                                .shadow(color: BayanTheme.gold.opacity(0.6), radius: 4)
                                .offset(x: min(max(0, totalWidth * CGFloat(progress) - 7), totalWidth - 14))
                        }
                    }
                    .frame(height: 18)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                let clampedX = min(max(0, value.location.x), totalWidth)
                                let ratio = clampedX / totalWidth
                                dragPosition = Double(ratio) * safeDuration
                            }
                            .onEnded { value in
                                let clampedX = min(max(0, value.location.x), totalWidth)
                                let ratio = clampedX / totalWidth
                                let finalSeekTime = Double(ratio) * safeDuration
                                playerService.seek(to: finalSeekTime)
                                isDragging = false
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            }
                    )
                }
                .frame(height: 14)
                .padding(.horizontal, 14)

                // Elapsed and Remaining Time Indicators
                HStack {
                    let displayTime = isDragging ? dragPosition : playerService.currentTime
                    let duration = max(playerService.duration, 1.0)
                    Text(formatTime(displayTime))
                    Spacer()
                    Text("-" + formatTime(max(0, duration - displayTime)))
                }
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
                .padding(.horizontal, 16)

                // MARK: - Metadata & Playback Controls Row
                HStack(spacing: 10) {
                    // Tappable Info Area
                    Button(action: onTapExpand) {
                        HStack(spacing: 10) {
                            // Animated Waveform Orb
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [BayanTheme.gold.opacity(0.3), BayanTheme.deepEmerald.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Circle().stroke(BayanTheme.gold.opacity(0.5), lineWidth: 1)
                                    )

                                Image(systemName: playerService.isPlaying ? "waveform" : "music.note")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(BayanTheme.goldSoft)
                                    .symbolEffect(.variableColor.iterative, isActive: playerService.isPlaying)
                            }

                            // Surah & Reciter Text
                            VStack(alignment: .leading, spacing: 1.5) {
                                HStack(spacing: 6) {
                                    Text(surah.nameEnglish)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text("•")
                                        .font(.system(size: 9))
                                        .foregroundColor(BayanTheme.goldSoft)

                                    Text(surah.nameArabic)
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundColor(BayanTheme.goldSoft)
                                }

                                HStack(spacing: 4) {
                                    Text(playerService.currentReciter.nameEnglish)
                                        .font(.system(size: 10.5))
                                        .foregroundColor(.white.opacity(0.7))
                                        .lineLimit(1)

                                    Text("•")
                                        .font(.system(size: 8))
                                        .foregroundColor(.white.opacity(0.4))

                                    Text("Ayah \(playerService.currentAyah)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(BayanTheme.electricCyan)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 4)

                    // Skip Backward 15s Button
                    Button {
                        playerService.skipBackward(by: 15)
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    // Play / Pause Toggle Button
                    Button {
                        playerService.togglePlayPause()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(BayanTheme.obsidian)
                            .frame(width: 34, height: 34)
                            .background(BayanTheme.gold)
                            .clipShape(Circle())
                            .shadow(color: BayanTheme.gold.opacity(0.4), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)

                    // Skip Forward 15s Button
                    Button {
                        playerService.skipForward(by: 15)
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    // Hifz Repeat Mode Button (Memorization Loop)
                    Button {
                        playerService.cycleRepeatMode()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: playerService.repeatMode.iconName)
                                .font(.system(size: 12, weight: .semibold))
                            if playerService.repeatMode.isRepeating {
                                Text(playerService.repeatMode.title)
                                    .font(.system(size: 9, weight: .bold))
                            }
                        }
                        .foregroundColor(playerService.repeatMode.isRepeating ? BayanTheme.obsidian : .white.opacity(0.8))
                        .padding(.horizontal, playerService.repeatMode.isRepeating ? 7 : 0)
                        .frame(height: 28)
                        .frame(minWidth: 28)
                        .background(playerService.repeatMode.isRepeating ? BayanTheme.gold : Color.white.opacity(0.08))
                        .clipShape(Capsule())
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
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
            }
            .padding(.top, 8)
            .liquidGlass(cornerRadius: 24, isGoldBorder: true)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity.combined(with: .scale(scale: 0.95))
            ))
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "00:00" }
        let total = Int(max(0, seconds))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
