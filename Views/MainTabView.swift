import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: TabItem = .identify

    public enum TabItem: Hashable {
        case identify
        case mushaf
        case history
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Identify (Shazam Mode)
            BayanIdentifyView()
                .tabItem {
                    Label("Identify", systemImage: "waveform.circle.fill")
                }
                .tag(TabItem.identify)

            // Tab 2: Full Holy Quran (Mushaf with all Reciters & Last Read Sync)
            MushafRootView()
                .tabItem {
                    Label("Quran", systemImage: "book.pages.fill")
                }
                .tag(TabItem.mushaf)

            // Tab 3: Recognition History
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(TabItem.history)
        }
        .tint(BayanTheme.gold)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
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
