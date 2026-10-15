import SwiftUI

struct BayanIdentifyView: View {
    @State private var recognitionService = AudioRecognitionService.shared
    @State private var syncManager = QuranSyncManager.shared
    @State private var matchedResult: RecognitionResult?
    @State private var showingResultSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background & Dynamic Ambient Shimmer
                BayanTheme.obsidian.ignoresSafeArea()
                RadialGradient(
                    colors: [
                        BayanTheme.deepEmerald.opacity(0.85),
                        BayanTheme.obsidian
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 500
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Header Brand
                    VStack(spacing: 4) {
                        Text("بَيَان")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, BayanTheme.goldSoft],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("QURAN AUDIO RECOGNIZER")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(3)
                            .foregroundColor(BayanTheme.gold.opacity(0.8))
                    }
                    .padding(.top, 20)

                    Spacer()

                    // Central Radar Orb
                    ListeningRadarOrb(
                        state: recognitionService.state,
                        decibels: recognitionService.currentDecibels
                    ) {
                        handleOrbTap()
                    }

                    // Dynamic Status Prompt
                    VStack(spacing: 8) {
                        Text(statusHeading)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.white)

                        Text(statusSubheading)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // Bottom Recent Matches Quick Bar
                    if let recent = syncManager.recentRecognitions.first {
                        Button {
                            self.matchedResult = recent
                            self.showingResultSheet = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(BayanTheme.gold)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("RECENT MATCH")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(BayanTheme.gold)

                                    Text("\(recent.surah.nameEnglish) • \(recent.reciter.nameEnglish)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .liquidGlass(cornerRadius: 18)
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .onChange(of: recognitionService.state) { _, newState in
                if case let .matched(result) = newState {
                    self.matchedResult = result
                    self.showingResultSheet = true
                }
            }
            .sheet(isPresented: $showingResultSheet) {
                if let result = matchedResult {
                    RecognitionResultSheet(result: result) { surah, ayah in
                        // Handled by parent tab coordinator
                    }
                    .presentationDetents([.fraction(0.85), .large])
                }
            }
        }
    }

    private func handleOrbTap() {
        switch recognitionService.state {
        case .idle, .failed, .matched:
            recognitionService.startListening()
        case .listening, .analyzing:
            recognitionService.reset()
        }
    }

    private var statusHeading: String {
        switch recognitionService.state {
        case .idle:
            return "Tap to Identify"
        case .listening:
            return "Listening..."
        case .analyzing:
            return "Recognizing Recitation..."
        case .matched(let result):
            return "Matched: \(result.surah.nameEnglish)"
        case .failed:
            return "Could not match audio"
        }
    }

    private var statusSubheading: String {
        switch recognitionService.state {
        case .idle:
            return "Point your iPhone toward any recitation (Mosque, car, video, or TV)"
        case .listening:
            return "Analyzing Quranic melody, tajweed, and acoustic fingerprint..."
        case .analyzing:
            return "Cross-referencing Uthmanic Quran index and 200+ Qura'a..."
        case .matched(let result):
            return "Recited by \(result.reciter.nameEnglish)"
        case .failed:
            return "Ensure the recitation is clear and tap to try again"
        }
    }
}
