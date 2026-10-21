import SwiftUI

// MARK: - Daily Prayer Reading Segment
public struct PrayerReadingSegment: Identifiable {
    public let id = UUID()
    public let prayerName: String
    public let prayerNameArabic: String
    public let pageStart: Int
    public let pageEnd: Int
    public var isCompleted: Bool

    public var pagesCount: Int {
        max(1, (pageEnd - pageStart) + 1)
    }
}

// MARK: - Khatmah Reading Planner & Streak Engine
public struct KhatmahPlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var khatmahService = KhatmahService.shared
    @State private var showingSetupSheet: Bool = false
    @State private var selectedDayOffset: Int = 0

    var onOpenPage: (Int) -> Void

    private let goldPrimary = Color(red: 0.95, green: 0.80, blue: 0.40)
    private let goldSoft = Color(red: 0.78, green: 0.65, blue: 0.35)
    private let emerald = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init(onOpenPage: @escaping (Int) -> Void = { _ in }) {
        self.onOpenPage = onOpenPage
    }

    private var pagesPerDay: Int {
        khatmahService.dailyPageTarget
    }

    private var perPrayerQuota: Int {
        max(1, Int(ceil(Double(pagesPerDay) / 5.0)))
    }

    private var prayerSegments: [PrayerReadingSegment] {
        let prayers = [
            ("Fajr", "الفجر"),
            ("Dhuhr", "الظهر"),
            ("Asr", "العصر"),
            ("Maghrib", "المغرب"),
            ("Isha", "العشاء")
        ]

        var segments: [PrayerReadingSegment] = []
        var cursor = khatmahService.currentPage

        for p in prayers {
            let start = min(604, cursor)
            let end = min(604, cursor + perPrayerQuota - 1)
            let isDone = khatmahService.pagesReadToday >= (segments.count + 1) * perPrayerQuota
            segments.append(PrayerReadingSegment(
                prayerName: p.0,
                prayerNameArabic: p.1,
                pageStart: start,
                pageEnd: end,
                isCompleted: isDone
            ))
            cursor = end + 1
        }
        return segments
    }

    private var estimatedCompletionDateString: String {
        let calendar = Calendar.current
        let remainingDays = max(1, khatmahService.daysRemaining)
        if let completionDate = calendar.date(byAdding: .day, value: remainingDays, to: Date()) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: completionDate)
        }
        return "In \(remainingDays) days"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
                RadialGradient(
                    colors: [Color(red: 0.12, green: 0.18, blue: 0.14), Color.clear],
                    center: .top,
                    startRadius: 50,
                    endRadius: 400
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Hero Khatmah Status Card
                        heroStatusCard

                        // 2. Daily Streak & Weekly Consistency Banner
                        streakConsistencyBanner

                        // 3. Per-Prayer Daily Schedule Breakdown
                        dailyPrayerScheduleSection

                        // 4. Quick Action Button: Continue Reading
                        continueReadingButton

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("خطة الختمة • Khatmah Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSetupSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Adjust Goal")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(goldPrimary)
                    }
                }

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
            .sheet(isPresented: $showingSetupSheet) {
                KhatmahSetupSheet()
            }
        }
    }

    // MARK: - 1. Hero Khatmah Status Card
    private var heroStatusCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT PROGRESS")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.4)
                        .foregroundColor(goldPrimary)

                    Text("Page \(khatmahService.currentPage) of 604")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("Juz' \(khatmahService.currentJuz) • \(khatmahService.pagesRemaining) Pages Remaining")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                // Circular Progress Dial
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 8)
                        .frame(width: 74, height: 74)

                    Circle()
                        .trim(from: 0, to: CGFloat(khatmahService.progressFraction))
                        .stroke(
                            LinearGradient(
                                colors: [goldPrimary, emerald],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 74, height: 74)

                    Text(khatmahService.progressPercentString)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.12))

            // Sub-metrics: Target Pace & Estimated Completion
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Target")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                    Text("\(pagesPerDay) pages / day")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(goldSoft)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Target Completion")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                    Text(estimatedCompletionDateString)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(emerald)
                }
            }
        }
        .padding(18)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(goldPrimary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 2. Daily Streak & Consistency Banner
    private var streakConsistencyBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.orange)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Reading Streak Active")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("🔥 \(khatmahService.daysElapsed + 1) Days")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(Color.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .clipShape(Capsule())
                }

                Text("Consistency is beloved by Allah, even if small.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - 3. Per-Prayer Reading Schedule Breakdown
    private var dailyPrayerScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S PRAYER SCHEDULE")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(goldPrimary)

                Spacer()

                Text("(\(perPrayerQuota) Pages After Each Prayer)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(goldSoft)
            }

            VStack(spacing: 10) {
                ForEach(prayerSegments) { segment in
                    HStack(spacing: 14) {
                        // Checkmark Button
                        Button {
                            togglePrayerCompleted(segment: segment)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(segment.isCompleted ? emerald : Color.white.opacity(0.08))
                                    .frame(width: 28, height: 28)

                                Image(systemName: segment.isCompleted ? "checkmark" : "circle")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(segment.isCompleted ? Color.black : Color.white.opacity(0.4))
                            }
                        }

                        // Prayer Name & Page Range
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(segment.prayerName)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text(segment.prayerNameArabic)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(goldSoft)
                            }

                            Text("Pages \(segment.pageStart) – \(segment.pageEnd) • (\(segment.pagesCount) pages)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        // Open in Mushaf Action
                        Button {
                            onOpenPage(segment.pageStart)
                            dismiss()
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            HStack(spacing: 4) {
                                Text("Read")
                                    .font(.system(size: 12, weight: .bold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(goldPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(goldPrimary.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    // MARK: - 4. Continue Reading Button
    private var continueReadingButton: some View {
        Button {
            onOpenPage(khatmahService.currentPage)
            dismiss()
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Open Mushaf at Page \(khatmahService.currentPage)")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [goldPrimary, Color(red: 1.0, green: 0.88, blue: 0.55)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: goldPrimary.opacity(0.35), radius: 8, y: 3)
        }
    }

    private func togglePrayerCompleted(segment: PrayerReadingSegment) {
        if segment.isCompleted {
            khatmahService.pagesReadToday = max(0, khatmahService.pagesReadToday - segment.pagesCount)
        } else {
            khatmahService.pagesReadToday += segment.pagesCount
            khatmahService.logPagesRead(segment.pagesCount)
        }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}
