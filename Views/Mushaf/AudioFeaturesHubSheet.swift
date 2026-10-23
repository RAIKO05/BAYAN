import SwiftUI

// MARK: - Audio Features Hub Sheet
/// Direct implementation of Screenshot 2:
/// Showcases the 6 core pillars of the Bayan audio experience with 1-tap interactive launchers:
/// 1. 🎧 High-Quality Recitations (40 authentic reciters, Hafs & Warsh)
/// 2. 📖 Read & Understand Mode (Synchronized verse highlights, translations & Tafsir)
/// 3. 🌊 Ambient Soundscapes (Mix ocean waves, rain, or Haram ambiance)
/// 4. ⬇️ Offline Quran Manager (Download entire Surahs for flights/travel)
/// 5. 🌙 Bedtime Sleep Timer (Fade out audio gently at end of Ayah/Surah)
/// 6. 📡 Universal Cast & AirPlay (Stream to Apple TV, HomePod, Sonos, Google Cast)
public struct AudioFeaturesHubSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var playerService = AudioPlayerService.shared
    @State private var soundscapeService = AmbientSoundscapeService.shared
    @State private var castService = BayanCastService.shared
    @State private var showingReciterPicker: Bool = false
    @State private var showingReadAndUnderstand: Bool = false
    @State private var showingSleepTimer: Bool = false
    @State private var showingCastSheet: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Section Header
                        VStack(spacing: 4) {
                            Text("AUDIO EXPERIENCE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.4)
                                .foregroundColor(BayanTheme.goldSoft)

                            Text("6 Pillars of Bayan Audio")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            Text("Designed for deep spiritual focus, habit formation, and seamless listening.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                        // Pillar 1: High Quality Reciters
                        featureCard(
                            icon: "waveform.circle.fill",
                            color: BayanTheme.gold,
                            title: "High-Quality Recitations",
                            subtitle: "40 Authentic Reciters • Hafs & Warsh",
                            description: "Crystal-clear studio audio recordings with authentic portrait photos, riwayah selection, and instant previewing.",
                            buttonTitle: "Change Reciter",
                            action: { showingReciterPicker = true }
                        )

                        // Pillar 2: Read & Understand Mode
                        featureCard(
                            icon: "book.pages.fill",
                            color: Color(red: 0.18, green: 0.85, blue: 0.50),
                            title: "Read & Understand While Listening",
                            subtitle: "Synchronized Ayah Focus • 7 Languages",
                            description: "Immersive calligraphic font scaling, instant Tafsir Al-Muyassar, word-by-word breakdowns, and Ayah repeat counters.",
                            buttonTitle: "Open Reader",
                            action: { showingReadAndUnderstand = true }
                        )

                        // Pillar 3: Ambient Soundscapes
                        featureCard(
                            icon: "water.waves",
                            color: Color(red: 0.20, green: 0.85, blue: 0.95),
                            title: "Ambient Soundscapes",
                            subtitle: "Ocean Waves • Rain • Makkah Haram",
                            description: "Mix calming natural atmospheres underneath the reciter's voice with independent volume balance.",
                            buttonTitle: soundscapeService.currentSoundscape == .off ? "Enable Soundscape" : "Soundscape: \(soundscapeService.currentSoundscape.title)",
                            action: { soundscapeService.toggle() }
                        )

                        // Pillar 4: Offline Quran Downloads
                        featureCard(
                            icon: "arrow.down.circle.fill",
                            color: Color(red: 0.95, green: 0.55, blue: 0.20),
                            title: "Offline Quran Playback",
                            subtitle: "Zero Data Required • Airplane Mode",
                            description: "Full Surahs and Juzz pre-cached for uninterrupted listening during flights, commutes, and travel.",
                            buttonTitle: "Cached & Ready",
                            action: {}
                        )

                        // Pillar 5: Bedtime Sleep Timer
                        featureCard(
                            icon: "moon.zzz.fill",
                            color: Color(red: 0.70, green: 0.50, blue: 0.95),
                            title: "Bedtime Sleep Timer",
                            subtitle: "Gentle 2-Second Audio Fade-Out",
                            description: "Fall asleep peacefully to the Quran with automatic pause at the end of the current Ayah, Surah, or timer.",
                            buttonTitle: playerService.sleepTimerOption == .off ? "Set Timer" : "Active: \(playerService.sleepTimerOption.title)",
                            action: { showingSleepTimer = true }
                        )

                        // Pillar 6: Universal Cast & AirPlay
                        featureCard(
                            icon: "tv.and.mediabox",
                            color: Color(red: 0.35, green: 0.65, blue: 1.0),
                            title: "Universal Cast & AirPlay",
                            subtitle: "Apple TV • HomePod • Sonos • DLNA",
                            description: "Stream high-definition Quran audio seamlessly to smart speakers and home audio setups across all platforms.",
                            buttonTitle: castService.isCasting ? "Connected: \(castService.connectedDeviceName)" : "AirPlay / Cast",
                            action: { showingCastSheet = true }
                        )

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .navigationTitle("Audio Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .sheet(isPresented: $showingReciterPicker) {
                ReciterPickerSheet(selectedReciter: $playerService.currentReciter)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingReadAndUnderstand) {
                ReadAndUnderstandModalView()
            }
            .sheet(isPresented: $showingSleepTimer) {
                SleepTimerPickerSheet()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingCastSheet) {
                BayanCastSheet()
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func featureCard(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        description: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(color)
                }

                Spacer()
            }

            Text(description)
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.70))
                .lineSpacing(3)

            Button(action: action) {
                HStack {
                    Text(buttonTitle)
                        .font(.system(size: 12.5, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(color)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
