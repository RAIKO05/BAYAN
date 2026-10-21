import SwiftUI
import AudioToolbox

// MARK: - Bead Theme Styling
public enum TasbihBeadTheme: String, CaseIterable, Identifiable {
    case obsidian = "Obsidian Gold"
    case emerald = "Imperial Emerald"
    case sandalwood = "Warm Sandalwood"
    case pearl = "Opalescent Pearl"

    public var id: String { rawValue }

    public var beadGradient: LinearGradient {
        switch self {
        case .obsidian:
            return LinearGradient(
                colors: [Color(red: 0.28, green: 0.28, blue: 0.32), Color(red: 0.08, green: 0.08, blue: 0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .emerald:
            return LinearGradient(
                colors: [Color(red: 0.18, green: 0.65, blue: 0.42), Color(red: 0.04, green: 0.28, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .sandalwood:
            return LinearGradient(
                colors: [Color(red: 0.72, green: 0.48, blue: 0.30), Color(red: 0.38, green: 0.22, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pearl:
            return LinearGradient(
                colors: [Color(red: 0.96, green: 0.94, blue: 0.92), Color(red: 0.75, green: 0.72, blue: 0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    public var beadStrokeColor: Color {
        switch self {
        case .obsidian: return Color(red: 0.95, green: 0.80, blue: 0.40).opacity(0.4)
        case .emerald: return Color(red: 0.95, green: 0.80, blue: 0.40).opacity(0.6)
        case .sandalwood: return Color(red: 0.95, green: 0.80, blue: 0.40).opacity(0.3)
        case .pearl: return Color(red: 0.90, green: 0.70, blue: 0.75).opacity(0.5)
        }
    }
}

// MARK: - Preset Dhikr Item
public struct TasbihPreset: Identifiable, Hashable {
    public let id = UUID()
    public let arabic: String
    public let transliteration: String
    public let target: Int
    public let virtue: String

    public static let standardPresets: [TasbihPreset] = [
        TasbihPreset(
            arabic: "سُبْحَانَ اللَّهِ",
            transliteration: "Subhan Allah",
            target: 33,
            virtue: "Glory be to Allah (33x after prayer)"
        ),
        TasbihPreset(
            arabic: "الْحَمْدُ لِلَّهِ",
            transliteration: "Alhamdulillah",
            target: 33,
            virtue: "All praise is for Allah (33x after prayer)"
        ),
        TasbihPreset(
            arabic: "اللَّهُ أَكْبَرُ",
            transliteration: "Allahu Akbar",
            target: 34,
            virtue: "Allah is the Greatest (34x after prayer)"
        ),
        TasbihPreset(
            arabic: "أَسْتَغْفِرُ اللَّهَ",
            transliteration: "Astaghfirullah",
            target: 100,
            virtue: "I seek Allah's forgiveness (100x daily)"
        ),
        TasbihPreset(
            arabic: "لَا إِلَهَ إِلَّا اللَّهُ",
            transliteration: "La ilaha illa Allah",
            target: 100,
            virtue: "Best dhikr is La ilaha illa Allah"
        ),
        TasbihPreset(
            arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
            transliteration: "Subhan Allahi wa bihamdih",
            target: 100,
            virtue: "Sins forgiven even if like foam of the sea"
        ),
        TasbihPreset(
            arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ",
            transliteration: "Salawat on Prophet ﷺ",
            target: 100,
            virtue: "Allah blesses you 10 times for each"
        ),
        TasbihPreset(
            arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ",
            transliteration: "Hasbunallahu wa ni'mal wakeel",
            target: 33,
            virtue: "Sufficient for us is Allah"
        ),
        TasbihPreset(
            arabic: "تَسْبِيحٌ حُرٌّ (عَدٌّ مَفْتُوحٌ)",
            transliteration: "Free Continuous Tasbih",
            target: 1000,
            virtue: "Count freely with unlimited target"
        )
    ]
}

// MARK: - Interactive 3D Digital Tasbih View
public struct DigitalTasbihView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentCount: Int = 0
    @State private var targetCount: Int = 33
    @State private var selectedPresetIndex: Int = 0
    @State private var beadTheme: TasbihBeadTheme = .obsidian
    @State private var isBlindCountingMode: Bool = false
    @State private var isSoundEnabled: Bool = false
    @State private var totalLifetimeCounts: Int = 0
    @State private var beadAngleOffset: Double = 0.0
    @State private var dragAccumulator: Double = 0.0

    private let goldPrimary = Color(red: 0.95, green: 0.80, blue: 0.40)
    private let goldSoft = Color(red: 0.78, green: 0.65, blue: 0.35)
    private let emerald = Color(red: 0.18, green: 0.85, blue: 0.50)

    private var activePreset: TasbihPreset {
        TasbihPreset.standardPresets[selectedPresetIndex]
    }

    private var progressFraction: Double {
        guard targetCount > 0 else { return 0 }
        return min(1.0, Double(currentCount % targetCount) / Double(targetCount))
    }

    public init() {}

    public var body: some View {
        ZStack {
            if isBlindCountingMode {
                // MARK: Blind Counting Mode (Pure OLED Black)
                blindCountingView
            } else {
                // MARK: Normal 3D Physical Rosary Mode
                fullBeadInterfaceView
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadSavedStats()
        }
    }

    // MARK: - Full 3D Rosary Interface
    private var fullBeadInterfaceView: some View {
        ZStack {
            // Background Obsidian & Subtle Ambient Gradient
            Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0.10, green: 0.16, blue: 0.14), Color.clear],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Top Navigation & Quick Controls Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Text("الْمَسْبَحَةُ الإلِكْترُونِيَّة")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(goldPrimary)

                    Spacer()

                    // Blind Mode Toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isBlindCountingMode = true
                        }
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 12))
                            Text("Blind")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(goldPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(goldPrimary.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                // 2. Preset Phrase Carousel Selector
                Menu {
                    ForEach(TasbihPreset.standardPresets.indices, id: \.self) { idx in
                        let p = TasbihPreset.standardPresets[idx]
                        Button {
                            selectPreset(index: idx)
                        } label: {
                            HStack {
                                Text(p.arabic + " (\(p.target))")
                                if selectedPresetIndex == idx {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activePreset.arabic)
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                            Text(activePreset.transliteration + " • Target: \(targetCount)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(goldSoft)
                        }

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(goldPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(goldPrimary.opacity(0.35), lineWidth: 1)
                    )
                }
                .padding(.top, 10)

                Spacer()

                // 3. Central 3D Bead Rosary Loop & Counter Display
                ZStack {
                    // Central Numeric Counter Orb
                    VStack(spacing: 2) {
                        Text("\(currentCount)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())

                        Text("/ \(targetCount)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(goldSoft)

                        Text(activePreset.virtue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 160)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                    .frame(width: 170, height: 170)
                    .background(
                        Circle()
                            .fill(Color(red: 0.08, green: 0.10, blue: 0.14))
                            .shadow(color: Color.black.opacity(0.6), radius: 16)
                    )
                    .overlay(
                        Circle()
                            .trim(from: 0, to: CGFloat(progressFraction))
                            .stroke(
                                AngularGradient(
                                    colors: [goldPrimary, emerald, goldPrimary],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progressFraction)
                    )

                    // 3D Circular Beaded String
                    circularBeadString
                }
                .frame(width: 320, height: 320)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            let delta = value.translation.height - dragAccumulator
                            beadAngleOffset += delta * 0.4
                            dragAccumulator = value.translation.height

                            if abs(delta) > 18 {
                                incrementCount()
                                dragAccumulator = value.translation.height
                            }
                        }
                        .onEnded { _ in
                            dragAccumulator = 0
                        }
                )
                .onTapGesture {
                    incrementCount()
                }

                Spacer()

                // 4. Bottom Controls: Sound, Theme, Reset & Lifetime Stats
                VStack(spacing: 14) {
                    HStack(spacing: 16) {
                        // Sound FX Toggle
                        Button {
                            isSoundEnabled.toggle()
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            Image(systemName: isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isSoundEnabled ? emerald : .white.opacity(0.6))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }

                        // Bead Material Theme Picker
                        Menu {
                            ForEach(TasbihBeadTheme.allCases) { theme in
                                Button {
                                    beadTheme = theme
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                } label: {
                                    HStack {
                                        Text(theme.rawValue)
                                        if beadTheme == theme {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(beadTheme.beadGradient)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                                Text(beadTheme.rawValue)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                        }

                        // Reset Counter Button
                        Button {
                            resetCount()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(goldSoft)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                    }

                    // Total Lifetime Dhikr Counter
                    Text("Total Recorded: \(totalLifetimeCounts) Tasbih")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: 580)
        }
    }

    // MARK: - Circular 3D Bead Rosary Loop
    private var circularBeadString: some View {
        let beadCount = 33
        let radius: CGFloat = 130

        return ZStack {
            ForEach(0..<beadCount, id: \.self) { i in
                let angle = Double(i) * (360.0 / Double(beadCount)) + beadAngleOffset
                let rad = angle * .pi / 180.0
                let x = radius * CGFloat(cos(rad))
                let y = radius * CGFloat(sin(rad))
                let isDivider = (i == 0 || i == 11 || i == 22)

                ZStack {
                    if isDivider {
                        // Gold Metallic Divider Bead
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.90, blue: 0.55), Color(red: 0.65, green: 0.48, blue: 0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 18, height: 18)
                            .shadow(color: goldPrimary.opacity(0.5), radius: 4)
                    } else {
                        // Normal Physical Rosary Bead
                        Circle()
                            .fill(beadTheme.beadGradient)
                            .frame(width: 15, height: 15)
                            .overlay(
                                Circle()
                                    .stroke(beadTheme.beadStrokeColor, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.4), radius: 3, x: 1, y: 2)
                    }
                }
                .offset(x: x, y: y)
            }
        }
    }

    // MARK: - Blind Counting Mode (Full Screen Tap for Mosques & Bedtime)
    private var blindCountingView: some View {
        ZStack {
            // Absolute Pure Black Screen
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    // Exit Blind Mode
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isBlindCountingMode = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.fill")
                            Text("Exit Blind Mode")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(goldPrimary.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 8) {
                    Text(activePreset.arabic)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(.white.opacity(0.35))

                    Text("\(currentCount)")
                        .font(.system(size: 96, weight: .black, design: .rounded))
                        .foregroundColor(currentCount >= targetCount ? emerald : .white.opacity(0.25))

                    Text("Target: \(targetCount)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(goldSoft.opacity(0.4))
                }

                Spacer()

                VStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Tap anywhere on the screen with your eyes closed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.bottom, 40)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            incrementCount()
        }
    }

    // MARK: - Actions & Persistence
    private func incrementCount() {
        currentCount += 1
        totalLifetimeCounts += 1
        withAnimation(.easeOut(duration: 0.15)) {
            beadAngleOffset += (360.0 / 33.0)
        }

        #if os(iOS)
        if currentCount % targetCount == 0 && targetCount > 0 {
            // Celebration Milestone Haptics
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            // Physical Bead Click Haptic
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }

        if isSoundEnabled {
            AudioServicesPlaySystemSound(1104) // Tink sound
        }
        #endif

        saveStats()
    }

    private func resetCount() {
        currentCount = 0
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        saveStats()
    }

    private func selectPreset(index: Int) {
        selectedPresetIndex = index
        targetCount = TasbihPreset.standardPresets[index].target
        currentCount = 0
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        saveStats()
    }

    private func loadSavedStats() {
        let defaults = UserDefaults.standard
        currentCount = defaults.integer(forKey: "bayan_tasbih_current_count")
        totalLifetimeCounts = defaults.integer(forKey: "bayan_tasbih_lifetime_count")
        let savedIndex = defaults.integer(forKey: "bayan_tasbih_preset_index")
        if savedIndex >= 0 && savedIndex < TasbihPreset.standardPresets.count {
            selectedPresetIndex = savedIndex
            targetCount = TasbihPreset.standardPresets[savedIndex].target
        }
        isSoundEnabled = defaults.bool(forKey: "bayan_tasbih_sound_enabled")
        if let savedTheme = defaults.string(forKey: "bayan_tasbih_theme"),
           let theme = TasbihBeadTheme(rawValue: savedTheme) {
            beadTheme = theme
        }
    }

    private func saveStats() {
        let defaults = UserDefaults.standard
        defaults.set(currentCount, forKey: "bayan_tasbih_current_count")
        defaults.set(totalLifetimeCounts, forKey: "bayan_tasbih_lifetime_count")
        defaults.set(selectedPresetIndex, forKey: "bayan_tasbih_preset_index")
        defaults.set(isSoundEnabled, forKey: "bayan_tasbih_sound_enabled")
        defaults.set(beadTheme.rawValue, forKey: "bayan_tasbih_theme")
    }
}
