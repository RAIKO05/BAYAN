import SwiftUI

// MARK: - Khatmah Progress Card View
// Displayed inside MushafRootView. Provides a visual ring progress,
// daily page targets, and 1-tap page logging.
public struct KhatmahCardView: View {
    @State private var khatmahService = KhatmahService.shared
    @State private var showingSetupSheet: Bool = false
    @State private var showingCloudSyncSheet: Bool = false
    @State private var showingPlannerSheet: Bool = false
    var onResumeReading: (Surah, Int) -> Void

    public init(onResumeReading: @escaping (Surah, Int) -> Void = { _, _ in }) {
        self.onResumeReading = onResumeReading
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Header Row: Title & Goal Settings Button
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("خطة ختم القرآن")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("Quran Khatmah Goal • Day \(khatmahService.daysElapsed + 1) of \(khatmahService.targetDays)")
                        .font(.system(size: 11))
                        .foregroundColor(BayanTheme.goldSoft.opacity(0.85))
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        showingCloudSyncSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(BayanTheme.gold)
                            .padding(8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingSetupSheet = true
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(BayanTheme.gold)
                            .padding(8)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Center Row: Progress Gauge + Stats
            HStack(spacing: 16) {
                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 5)
                        .frame(width: 58, height: 58)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(khatmahService.progressFraction))
                        .stroke(
                            LinearGradient(
                                colors: [BayanTheme.goldSoft, BayanTheme.gold],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 58, height: 58)

                    Text(khatmahService.progressPercentString)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                // Stats Column
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Page \(khatmahService.currentPage)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("/ 604")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))

                        Text("•")
                            .foregroundColor(.white.opacity(0.3))

                        Text("Juz' \(khatmahService.currentJuz)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(BayanTheme.goldSoft)
                    }

                    // Daily Goal Pill
                    HStack(spacing: 4) {
                        Image(systemName: khatmahService.pagesLeftToday == 0 ? "checkmark.circle.fill" : "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(khatmahService.pagesLeftToday == 0 ? .green : BayanTheme.gold)

                        if khatmahService.pagesLeftToday == 0 {
                            Text("Today's target achieved!")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        } else {
                            Text("\(khatmahService.pagesLeftToday) pages left today (Target: \(khatmahService.dailyTargetPages)/day)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                }

                Spacer()
            }

            // Bottom Actions: +1 Page & Resume Reading
            HStack(spacing: 10) {
                // Quick +1 Page Button
                Button {
                    khatmahService.incrementPage()
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("+1 Page")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(BayanTheme.gold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Resume Reading Button
                Button {
                    let surah = khatmahService.currentSurah()
                    onResumeReading(surah, 1)
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                        Text("Open Surah \(khatmahService.currentSurah().nameEnglish)")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Daily Prayer Schedule Planner Button
                Button {
                    showingPlannerSheet = true
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                        Text("Schedule")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.18, green: 0.85, blue: 0.50))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.18, green: 0.85, blue: 0.50).opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20, isGoldBorder: true)
        .sheet(isPresented: $showingPlannerSheet) {
            KhatmahPlannerView { page in
                let surah = QuranDataService.shared.allSurahs.last(where: { $0.startPage <= page }) ?? khatmahService.currentSurah()
                onResumeReading(surah, 1)
            }
        }
        .sheet(isPresented: $showingSetupSheet) {
            KhatmahSetupSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingCloudSyncSheet) {
            CloudSyncSheet()
                .presentationDetents([.fraction(0.68), .large])
        }
    }
}
