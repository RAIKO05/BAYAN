import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: TabItem = .identify
    @State private var playerService = AudioPlayerService.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var languageManager = AppLanguageManager.shared
    @State private var showingLanguageSheet = false

    public enum TabItem: Hashable, CaseIterable {
        case identify
        case mushaf
        case qibla
        case adkar
        case you

        public var title: String {
            switch self {
            case .identify: return "Identify"
            case .mushaf: return "Mushaf"
            case .qibla: return "Prayers"
            case .adkar: return "Adhkar"
            case .you: return "You"
            }
        }

        public var icon: String {
            switch self {
            case .identify: return "waveform.circle.fill"
            case .mushaf: return "book.pages.fill"
            case .qibla: return "clock.badge.checkmark.fill"
            case .adkar: return "hands.sparkles.fill"
            case .you: return "person.crop.circle.fill"
            }
        }

        public var badgeText: String? {
            switch self {
            case .mushaf: return "1"
            case .adkar: return "9"
            default: return nil
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
                case .you:
                    HistoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Navigation Stack (Spotify Mini Player + WhatsApp Floating Pill Tab Bar)
            VStack(spacing: 8) {
                // Image 2: Spotify Floating Mini-Player Bar
                AudioMiniPlayerView {
                    selectedTab = .mushaf
                }

                // Image 1: WhatsApp Floating Capsule Tab Bar
                WhatsAppFloatingTabBar(selectedTab: $selectedTab)
            }
            .frame(maxWidth: 580)
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: playerService.isPlaying)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: playerService.currentSurah == nil)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .environment(\.layoutDirection, languageManager.currentLanguage.layoutDirection)
        .onAppear {
            checkSiriLaunchFlags()
            refreshDailyAdhanNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkSiriLaunchFlags()
            refreshDailyAdhanNotifications()
        }
        .onOpenURL { url in
            handleDeepLink(url: url)
        }
        .sheet(isPresented: $showingLanguageSheet) {
            LanguagePickerSheet()
                .presentationDetents([.medium])
        }
    }

    private func refreshDailyAdhanNotifications() {
        guard AdhanNotificationService.shared.isNotificationsEnabled else { return }
        let defaults = UserDefaults(suiteName: "group.tools.rea.Bayan") ?? UserDefaults.standard
        let lat = defaults.double(forKey: "bayan_last_latitude") != 0.0 ? defaults.double(forKey: "bayan_last_latitude") : 33.5731
        let lng = defaults.double(forKey: "bayan_last_longitude") != 0.0 ? defaults.double(forKey: "bayan_last_longitude") : -7.5898
        let result = PrayerCalculationService.shared.calculate(for: Date(), lat: lat, lng: lng)
        AdhanNotificationService.shared.scheduleAdhanNotifications(prayerTimes: result.prayers)
    }

    private func checkSiriLaunchFlags() {
        let defaults = UserDefaults(suiteName: "group.tools.rea.Bayan") ?? UserDefaults.standard
        if defaults.bool(forKey: "bayan_trigger_identify_on_launch") {
            defaults.set(false, forKey: "bayan_trigger_identify_on_launch")
            selectedTab = .identify
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                AudioRecognitionService.shared.startListening()
            }
        } else if defaults.bool(forKey: "bayan_trigger_resume_on_launch") {
            defaults.set(false, forKey: "bayan_trigger_resume_on_launch")
            selectedTab = .mushaf
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
        case "surah", "ayah":
            selectedTab = .mushaf
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let surahIdStr = components?.queryItems?.first(where: { $0.name == "id" || $0.name == "surah" })?.value
            let ayahIdStr = components?.queryItems?.first(where: { $0.name == "ayah" })?.value

            if let sId = Int(surahIdStr ?? ""), let surah = QuranDataService.shared.surah(for: sId) {
                let aId = Int(ayahIdStr ?? "") ?? 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    AudioPlayerService.shared.play(surah: surah, ayah: aId)
                }
            }
        case "prayer", "prayers", "qibla":
            selectedTab = .qibla
        case "adkar":
            selectedTab = .adkar
        case "history", "you", "saved":
            selectedTab = .you
        default:
            break
        }
    }
}

// MARK: - WhatsApp-Style Floating Pill Tab Bar (Image 1)
// Pixel-perfect replica of the floating capsule dock:
// 1. Dark translucent frosted glass capsule
// 2. Solid dark gray sliding selection pill for active tab (.matchedGeometryEffect)
// 3. Vibrant green notification badges with bold numbers
// 4. Circular profile avatar on 5th "You" tab
public struct WhatsAppFloatingTabBar: View {
    @Binding var selectedTab: MainTabView.TabItem
    @State private var themeManager = AppThemeManager.shared
    @Namespace private var tabNamespace

    // WhatsApp Iconic Green for Badges
    private let whatsAppGreen = Color(red: 0.15, green: 0.82, blue: 0.40)

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTabView.TabItem.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab

                Button {
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.76)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            // Icon or Avatar Circle
                            if tab == .you {
                                // "You" Circular Avatar (Exact Match to Image 1)
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.20, green: 0.22, blue: 0.26),
                                                    Color(red: 0.12, green: 0.14, blue: 0.17)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 27, height: 27)

                                    Image(systemName: "person.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                                }
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? Color.white.opacity(0.8) : Color.white.opacity(0.25), lineWidth: 1.2)
                                )
                                .padding(.top, 1)
                            } else {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : Color.white.opacity(0.60))
                                    .frame(width: 28, height: 26)
                            }

                            // Green Pill Badge with Number (Image 1 replica)
                            if let badge = tab.badgeText {
                                ZStack {
                                    Circle()
                                        .fill(whatsAppGreen)
                                        .frame(width: 17, height: 17)

                                    Text(badge)
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundColor(.black)
                                }
                                .offset(x: 10, y: -6)
                            }
                        }

                        // Label
                        Text(tab.title)
                            .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : Color.white.opacity(0.60))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                    .background {
                        if isSelected {
                            // Dark Charcoal Sliding Capsule Pill (Image 1 replica)
                            Capsule()
                                .fill(Color(red: 0.18, green: 0.19, blue: 0.23))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.09), lineWidth: 0.8)
                                )
                                .matchedGeometryEffect(id: "whatsappActivePill", in: tabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(height: 64)
        .background(
            Capsule()
                .fill(Color(red: 0.10, green: 0.11, blue: 0.13).opacity(0.90))
        )
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.48), radius: 18, x: 0, y: 8)
    }
}
