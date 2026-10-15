import SwiftUI

struct ListeningRadarOrb: View {
    var state: AudioRecognitionService.State
    var decibels: Float
    var onTap: () -> Void

    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    private var isListening: Bool {
        if case .listening = state { return true }
        if case .analyzing = state { return true }
        return false
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Expanding Background Ripple Waves
                if isListening {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                RadialGradient(
                                    colors: [
                                        BayanTheme.gold.opacity(0.35 - Double(index) * 0.1),
                                        BayanTheme.emeraldGlow.opacity(0.2 - Double(index) * 0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 80,
                                    endRadius: 180 + CGFloat(index * 45)
                                ),
                                lineWidth: 2
                            )
                            .scaleEffect(isListening ? (1.0 + CGFloat(decibels) * 0.45 + CGFloat(index) * 0.2) : 1.0)
                            .opacity(isListening ? (1.0 - Double(index) * 0.25) : 0.0)
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.25),
                                value: decibels
                            )
                    }
                }

                // Rotating Ambient Glow Disk
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                BayanTheme.emeraldGlow.opacity(0.6),
                                BayanTheme.gold.opacity(0.7),
                                BayanTheme.electricCyan.opacity(0.4),
                                BayanTheme.emeraldGlow.opacity(0.6)
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 175, height: 175)
                    .blur(radius: isListening ? 30 : 15)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }

                // Main Frosted Liquid Glass Orb
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 165, height: 165)
                    .overlay(
                        Circle()
                            .stroke(
                                isListening ? BayanTheme.glassGoldStroke : BayanTheme.glassStroke,
                                lineWidth: 2.5
                            )
                    )
                    .shadow(
                        color: isListening ? BayanTheme.gold.opacity(0.45) : BayanTheme.emeraldGlow.opacity(0.35),
                        radius: 25,
                        x: 0,
                        y: 10
                    )

                // Central Icon / Logo
                VStack(spacing: 6) {
                    Image(systemName: isListening ? "waveform" : "waveform.circle.fill")
                        .font(.system(size: 58, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, BayanTheme.goldSoft],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.variableColor.iterative, isActive: isListening)

                    Text(isListening ? "بَيَان" : "LISTEN")
                        .font(.caption2.weight(.black))
                        .tracking(2.5)
                        .foregroundColor(BayanTheme.goldSoft)
                }
            }
            .frame(width: 320, height: 320)
        }
        .buttonStyle(.plain)
    }
}
