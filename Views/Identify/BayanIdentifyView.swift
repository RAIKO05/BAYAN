import SwiftUI

struct BayanIdentifyView: View {
    @State private var recognitionService = AudioRecognitionService.shared
    @State private var syncManager = QuranSyncManager.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var matchedResult: RecognitionResult?
    @State private var showingResultSheet = false

    private var isListening: Bool {
        if case .listening = recognitionService.state { return true }
        if case .analyzing = recognitionService.state { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background & Dynamic Ambient Shimmer
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 24) {
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
                    .padding(.top, 16)

                    Spacer(minLength: 10)

                    // Central Radar Orb (Directly Tappable with Haptics)
                    ListeningRadarOrb(
                        state: recognitionService.state,
                        decibels: recognitionService.currentDecibels
                    ) {
                        triggerIdentifyAction()
                    }

                    // Dynamic Status Prompt (Also Tappable)
                    Button {
                        triggerIdentifyAction()
                    } label: {
                        VStack(spacing: 6) {
                            Text(statusHeading)
                                .font(.title3.weight(.bold))
                                .foregroundColor(.white)

                            Text(statusSubheading)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                        }
                    }
                    .buttonStyle(.plain)

                    // Dedicated Primary Action Button
                    Button {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        #endif
                        triggerIdentifyAction()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: isListening ? "stop.fill" : "waveform.badge.magnifyingglass")
                                .font(.system(size: 16, weight: .bold))
                            Text(isListening ? "STOP LISTENING" : "TAP TO IDENTIFY RECITAITON")
                                .font(.system(size: 13, weight: .bold))
                                .tracking(1.2)
                        }
                        .foregroundColor(isListening ? .white : BayanTheme.obsidian)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(isListening ? Color.red.opacity(0.85) : BayanTheme.gold)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: isListening ? Color.red.opacity(0.35) : BayanTheme.gold.opacity(0.4), radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 10)

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
                .padding(.bottom, 100)
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

    private func triggerIdentifyAction() {
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
            return "Listening to Recitation..."
        case .analyzing:
            return "Recognizing Verse..."
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
            return "Analyzing Quranic melody, acoustic fingerprint, and tajweed..."
        case .analyzing:
            return "Cross-referencing Uthmanic Quran index and 200+ Qura'a..."
        case .matched(let result):
            return "Recited by \(result.reciter.nameEnglish)"
        case .failed(let reason):
            return reason
        }
    }
}
