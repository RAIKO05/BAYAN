import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: TabItem = .identify
    @State private var playerService = AudioPlayerService.shared
    @State private var themeManager = AppThemeManager.shared

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
            case .qibla: return "Prayers"
            case .adkar: return "Adkar"
            case .history: return "History"
            }
        }

        public var icon: String {
            switch self {
            case .identify: return "waveform.circle.fill"
            case .mushaf: return "book.pages.fill"
            case .qibla: return "clock.badge.checkmark.fill"
            case .adkar: return "hand.raised.fill"
            case .history: return "clock.arrow.circlepath"
            }
        }
    }

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            // Theme Unified Canvas Background
            themeManager.currentTheme.backgroundColor.ignoresSafeArea()
            themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

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
                // Persistent Global Audio Mini Player (when recitation is active/loaded)
                AudioMiniPlayerView {
                    selectedTab = .mushaf
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
    @State private var themeManager = AppThemeManager.shared
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
                            .foregroundColor(isSelected ? themeManager.currentTheme.activeCardBorder : (themeManager.currentTheme.isDark ? .white.opacity(0.45) : Color(red: 0.40, green: 0.45, blue: 0.52)))

                        Text(tab.title)
                            .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? themeManager.currentTheme.activeCardBorder : (themeManager.currentTheme.isDark ? .white.opacity(0.45) : Color(red: 0.40, green: 0.45, blue: 0.52)))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(themeManager.currentTheme.activeCardFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(themeManager.currentTheme.activeCardBorder.opacity(0.5), lineWidth: 1)
                                )
                                .shadow(color: themeManager.currentTheme.activeCardBorder.opacity(0.2), radius: 8, x: 0, y: 2)
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
