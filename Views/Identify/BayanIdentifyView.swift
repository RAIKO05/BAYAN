import SwiftUI

struct BayanIdentifyView: View {
    @State private var recognitionService = AudioRecognitionService.shared
    @State private var syncManager = QuranSyncManager.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var matchedResult: RecognitionResult?
    @State private var showingResultSheet = false
    @State private var showingSearchSheet = false
    @State private var showingLanguageSheet = false
    @State private var showingThemeSheet = false
    @State private var showingSupportSheet = false
    @State private var languageManager = AppLanguageManager.shared

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
                    // Header Bar with Language, Brand, and Theme
                    HStack(alignment: .center) {
                        Button {
                            showingLanguageSheet = true
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            HStack(spacing: 5) {
                                Text(languageManager.currentLanguage.flagEmoji)
                                Text(languageManager.currentLanguage.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(BayanTheme.goldSoft)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(BayanTheme.gold.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Center Brand
                        VStack(spacing: 2) {
                            Text("بَيَان")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, BayanTheme.goldSoft],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Text("QURAN AUDIO RECOGNIZER")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(2.5)
                                .foregroundColor(BayanTheme.gold.opacity(0.8))
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button {
                                showingSupportSheet = true
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            } label: {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(BayanTheme.goldSoft)
                                    .padding(8)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(BayanTheme.gold.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)

                            Button {
                                showingThemeSheet = true
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            } label: {
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(BayanTheme.goldSoft)
                                    .padding(8)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(BayanTheme.gold.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

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

                    // Live Heard Words Indicator
                    if isListening && !recognitionService.liveTranscription.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                                .foregroundColor(BayanTheme.gold)
                            Text(recognitionService.liveTranscription)
                                .font(.system(size: 13, weight: .medium))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundColor(BayanTheme.goldSoft)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(BayanTheme.gold.opacity(0.35), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)
                    }

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
                            Text(isListening ? "STOP LISTENING" : "TAP TO IDENTIFY RECITATION")
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

                    // Manual Search / Type Verse Fallback Option
                    Button {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        showingSearchSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Type or Search Verse Text")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(BayanTheme.goldSoft.opacity(0.9))
                        .padding(.vertical, 4)
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
                .frame(maxWidth: 640)
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
            .sheet(isPresented: $showingSearchSheet) {
                VerseSearchSheet { result in
                    self.matchedResult = result
                    self.showingResultSheet = true
                }
                .presentationDetents([.fraction(0.85), .large])
            }
            .sheet(isPresented: $showingLanguageSheet) {
                LanguagePickerSheet()
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingThemeSheet) {
                ThemePickerSheet()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingSupportSheet) {
                SupportBayanSheet()
                    .presentationDetents([.large])
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
            return "tap_to_identify".localized
        case .listening:
            return "listening_recitation".localized
        case .analyzing:
            return "listening_recitation".localized
        case .matched(let result):
            return "\(result.surah.nameArabic) • \(result.surah.nameEnglish)"
        case .failed:
            return "no_recitation".localized
        }
    }

    private var statusSubheading: String {
        switch recognitionService.state {
        case .idle:
            return "point_iphone".localized
        case .listening:
            return "Analyzing Quranic melody, acoustic fingerprint, and tajweed..."
        case .analyzing:
            return "Cross-referencing Uthmanic Quran index and 200+ Qura'a..."
        case .matched(let result):
            return "\(result.reciter.nameEnglish)"
        case .failed(let reason):
            return reason
        }
    }
}
