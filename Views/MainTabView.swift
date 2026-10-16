import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: TabItem = .identify
    @State private var playerService = AudioPlayerService.shared

    public enum TabItem: Hashable, CaseIterable {
        case identify
        case mushaf
        case qibla
        case adkar
        case history

        public var title: String {
            switch self {
            case .identify: return "Identify"
            case .mushaf: return "Mushaf"
            case .qibla: return "Qibla"
            case .adkar: return "Adkar"
            case .history: return "History"
            }
        }

        public var icon: String {
            switch self {
            case .identify: return "waveform.circle.fill"
            case .mushaf: return "book.pages.fill"
            case .qibla: return "safari.fill" // Compass icon
            case .adkar: return "hand.raised.fill" // Hand icon
            case .history: return "clock.arrow.circlepath"
            }
        }
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content Area
            Group {
                switch selectedTab {
                case .identify:
                    BayanIdentifyView()
                case .mushaf:
                    MushafRootView()
                case .qibla:
                    QiblaView()
                case .adkar:
                    AdkarView()
                case .history:
                    HistoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Liquid Glass Navigation Dock
            VStack(spacing: 8) {
                // Floating Liquid Glass Mini Player (when recitation is loaded)
                if let surah = playerService.currentSurah {
                    LiquidGlassMiniPlayerBar(
                        surah: surah,
                        ayah: playerService.currentAyah,
                        reciter: playerService.currentReciter,
                        isPlaying: playerService.isPlaying,
                        onTogglePlayPause: {
                            playerService.togglePlayPause()
                        },
                        onTapBody: {
                            selectedTab = .mushaf
                        },
                        onDismiss: {
                            playerService.stop()
                            playerService.currentSurah = nil
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }

                // Floating Liquid Glass Tab Bar
                LiquidGlassTabBar(selectedTab: $selectedTab)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: playerService.isPlaying)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: playerService.currentSurah == nil)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onOpenURL { url in
            handleDeepLink(url: url)
        }
    }

    private func handleDeepLink(url: URL) {
        guard url.scheme == "bayan" else { return }
        switch url.host {
        case "identify":
            selectedTab = .identify
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                AudioRecognitionService.shared.startListening()
            }
        case "resume":
            selectedTab = .mushaf
        default:
            break
        }
    }
}

// MARK: - Floating Liquid Glass Tab Bar
public struct LiquidGlassTabBar: View {
    @Binding var selectedTab: MainTabView.TabItem
    @Namespace private var tabNamespace

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(MainTabView.TabItem.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? BayanTheme.goldSoft : .white.opacity(0.45))

                        Text(tab.title)
                            .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? BayanTheme.goldSoft : .white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(BayanTheme.gold.opacity(0.16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(BayanTheme.gold.opacity(0.4), lineWidth: 1)
                                )
                                .shadow(color: BayanTheme.gold.opacity(0.2), radius: 8, x: 0, y: 2)
                                .matchedGeometryEffect(id: "activeTabBackground", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 58)
        .liquidGlass(cornerRadius: 32, isGoldBorder: true)
    }
}

// MARK: - Floating Liquid Glass Mini Player Bar
public struct LiquidGlassMiniPlayerBar: View {
    let surah: Surah
    let ayah: Int
    let reciter: Reciter
    let isPlaying: Bool
    var onTogglePlayPause: () -> Void
    var onTapBody: () -> Void
    var onDismiss: () -> Void

    public var body: some View {
        HStack(spacing: 12) {
            // Disc / Animated Waveform
            Button(action: onTapBody) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [BayanTheme.gold.opacity(0.25), BayanTheme.deepEmerald.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle().stroke(BayanTheme.gold.opacity(0.4), lineWidth: 1)
                            )

                        Image(systemName: isPlaying ? "waveform" : "music.note")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(BayanTheme.goldSoft)
                            .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(surah.nameEnglish) • Ayah \(ayah)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text(reciter.nameEnglish)
                                .font(.system(size: 10.5))
                                .foregroundColor(.white.opacity(0.65))
                                .lineLimit(1)

                            Text("•")
                                .font(.system(size: 9))
                                .foregroundColor(BayanTheme.gold)

                            Text(isPlaying ? "Reciting" : "Paused")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(isPlaying ? BayanTheme.gold : .white.opacity(0.4))
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Play / Pause Toggle Button
            Button(action: onTogglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(BayanTheme.obsidian)
                    .frame(width: 34, height: 34)
                    .background(BayanTheme.gold)
                    .clipShape(Circle())
                    .shadow(color: BayanTheme.gold.opacity(0.35), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            // Close / Dismiss Button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 52)
        .liquidGlass(cornerRadius: 26, isGoldBorder: true)
    }
}
