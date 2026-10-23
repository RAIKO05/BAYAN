import SwiftUI

// MARK: - Hi-Res / Dolby Hi-Fi Audio Quality Sheet
public struct AudioQualitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var playerService = AudioPlayerService.shared

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Master Technical Badge Card
                        masterAudioBadge

                        // Profiles Selection List
                        profilesSection

                        // Technical Specs Details
                        specsSection

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Hi-Res & Dolby Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(spotifyGreen)
                }
            }
        }
    }

    private var masterAudioBadge: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(BayanTheme.gold)

                Text(playerService.audioQualityProfile.badgeText)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(BayanTheme.gold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(BayanTheme.gold.opacity(0.15))
            .clipShape(Capsule())

            Text("Master High-Fidelity Recitation")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.white)

            Text("Configured for 48,000 Hz studio output, zero bitrate throttling, and Dolby 3D spatial acoustic reproduction.")
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.70))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(BayanTheme.gold.opacity(0.30), lineWidth: 1)
                )
        )
    }

    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio Profiles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 10) {
                ForEach(AudioQualityProfile.allCases) { profile in
                    let isSelected = playerService.audioQualityProfile == profile
                    Button {
                        playerService.setAudioQualityProfile(profile)
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? spotifyGreen.opacity(0.20) : Color.white.opacity(0.06))
                                    .frame(width: 42, height: 42)

                                Image(systemName: profile.iconName)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(isSelected ? spotifyGreen : .white.opacity(0.70))
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(profile.title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)

                                Text(profile.subtitle)
                                    .font(.system(size: 11.5))
                                    .foregroundColor(.white.opacity(0.60))
                            }

                            Spacer()

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(spotifyGreen)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSelected ? spotifyGreen.opacity(0.08) : Color.white.opacity(0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? spotifyGreen.opacity(0.40) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var specsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Hardware Master Specs")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.80))

            VStack(spacing: 8) {
                specRow(title: "Sample Rate", value: "48.0 kHz Studio Clock")
                specRow(title: "Bitrate Cap", value: "Unlimited / Max (320 kbps)")
                specRow(title: "Pitch Algorithm", value: "TimeDomain (Pristine Formants)")
                specRow(title: "Buffer Latency", value: "5.0 ms Ultra-Low Jitter")
                specRow(title: "Spatial Audio", value: "Apple CoreAudio & Dolby Ready")
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }

    private func specRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.60))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(spotifyGreen)
        }
    }
}
