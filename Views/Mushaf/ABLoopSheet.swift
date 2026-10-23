import SwiftUI

// MARK: - A-B Verse Memorization (Hifz) Loop Sheet
/// Intuitive range repeater enabling students and reciters to loop any passage of verses (A to B)
/// for repetitive auditory memorization, with iteration counts and seamless playback.
struct ABLoopSheet: View {
    @Environment(\.dismiss) private var dismiss
    let surah: Surah
    let initialAyah: Int

    @State private var playerService = AudioPlayerService.shared
    @State private var startAyah: Int
    @State private var endAyah: Int
    @State private var repeatCount: Int = 3 // 3, 5, 10, or Int.max

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    init(surah: Surah, initialAyah: Int = 1) {
        self.surah = surah
        self.initialAyah = initialAyah
        let initialStart = min(max(1, initialAyah), surah.totalAyahs)
        let initialEnd = min(initialStart + 2, surah.totalAyahs)
        _startAyah = State(initialValue: initialStart)
        _endAyah = State(initialValue: initialEnd)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.07, blue: 0.09).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Header Card
                        VStack(spacing: 6) {
                            HStack {
                                Image(systemName: "repeat.1.ar")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(BayanTheme.gold)

                                Text("A-B Verse Memorization Loop")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(surah.nameArabic)")
                                    .font(.quran(size: 18))
                                    .foregroundColor(BayanTheme.goldSoft)
                            }

                            Text("Repeats a continuous verse range between Ayah A and B to lock verses into memory before moving forward.")
                                .font(.system(size: 12.5))
                                .foregroundColor(.white.opacity(0.65))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(red: 0.10, green: 0.12, blue: 0.16).opacity(0.85))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )

                        // MARK: - Active Status Banner (If Loop Is Running)
                        if playerService.isABLoopActive {
                            HStack(spacing: 12) {
                                Image(systemName: "waveform.badge.magnifyingglass")
                                    .font(.system(size: 20))
                                    .foregroundColor(spotifyGreen)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Loop Currently Active")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(spotifyGreen)

                                    Text("Ayahs \(playerService.abStartAyah) to \(playerService.abEndAyah) • Pass \(playerService.abCurrentIteration) of \(playerService.abRepeatCount == Int.max ? "∞" : "\(playerService.abRepeatCount)")")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                }

                                Spacer()

                                Button {
                                    playerService.disableABLoop()
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    #endif
                                } label: {
                                    Text("Stop")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.red.opacity(0.35))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(spotifyGreen.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(spotifyGreen.opacity(0.35), lineWidth: 1)
                                    )
                            )
                        }

                        // MARK: - Verse Range Selectors (A & B)
                        VStack(spacing: 14) {
                            // Start Ayah (A)
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Point A (Start Ayah)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))

                                    Text("Ayah \(startAyah)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(BayanTheme.gold)
                                }

                                Spacer()

                                Stepper("", value: $startAyah, in: 1...surah.totalAyahs)
                                    .labelsHidden()
                                    .onChange(of: startAyah) { _, newVal in
                                        if newVal > endAyah {
                                            endAyah = newVal
                                        }
                                    }
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            // End Ayah (B)
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Point B (End Ayah)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))

                                    Text("Ayah \(endAyah)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(BayanTheme.gold)
                                }

                                Spacer()

                                Stepper("", value: $endAyah, in: startAyah...surah.totalAyahs)
                                    .labelsHidden()
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(red: 0.10, green: 0.11, blue: 0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )

                        // MARK: - Quick Presets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick Presets")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))

                            HStack(spacing: 8) {
                                presetButton("Current Ayah", range: initialAyah...initialAyah)
                                presetButton("3 Ayahs", range: startAyah...min(startAyah + 2, surah.totalAyahs))
                                presetButton("5 Ayahs", range: startAyah...min(startAyah + 4, surah.totalAyahs))
                                presetButton("Surah", range: 1...surah.totalAyahs)
                            }
                        }

                        // MARK: - Repeat Iterations Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Repeat Iterations")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))

                            HStack(spacing: 10) {
                                repeatOptionButton(count: 3, label: "3x")
                                repeatOptionButton(count: 5, label: "5x")
                                repeatOptionButton(count: 10, label: "10x")
                                repeatOptionButton(count: Int.max, label: "∞ Continuous")
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(red: 0.10, green: 0.11, blue: 0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )

                        // MARK: - Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                playerService.enableABLoop(startAyah: startAyah, endAyah: endAyah, count: repeatCount)
                                #if os(iOS)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                #endif
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Start A-B Memorization (\(startAyah) → \(endAyah))")
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(BayanTheme.gold)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }

                            if playerService.isABLoopActive {
                                Button {
                                    playerService.disableABLoop()
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                    dismiss()
                                } label: {
                                    Text("Turn Off Range Repeat")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.red.opacity(0.85))
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Memorization Loop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(BayanTheme.gold)
                    .font(.system(size: 14, weight: .bold))
                }
            }
            .onAppear {
                if playerService.isABLoopActive {
                    self.startAyah = playerService.abStartAyah
                    self.endAyah = playerService.abEndAyah
                    self.repeatCount = playerService.abRepeatCount
                }
            }
        }
    }

    private func presetButton(_ title: String, range: ClosedRange<Int>) -> some View {
        Button {
            startAyah = max(1, min(range.lowerBound, surah.totalAyahs))
            endAyah = max(startAyah, min(range.upperBound, surah.totalAyahs))
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func repeatOptionButton(count: Int, label: String) -> some View {
        let isSelected = self.repeatCount == count
        return Button {
            self.repeatCount = count
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? BayanTheme.gold : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
