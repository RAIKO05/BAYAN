import SwiftUI

// MARK: - Listening History & Detailed Stats Sheet
/// Direct implementation of Screenshot 1:
/// - 7-day interactive bar chart (Mon-Sun) displaying listening minutes per day
/// - Daily average, total hours, streak milestone badges
/// - Daily goal customization (5, 10, 15, 20, 30, 45, 60 min)
/// - Top reciters leaderboard with real portrait photos
/// - Daily Quran habit reminder notification schedule
public struct ListeningStatsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var goalManager = QuranListeningGoalManager.shared
    @State private var playerService = AudioPlayerService.shared

    private let goalOptions: [Int] = [5, 10, 15, 20, 30, 45, 60]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Sacred Deep Obsidian & Slate Background
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        // MARK: - 1. Hero Ring & Today's Metric Card
                        todayProgressCard

                        // MARK: - 2. 7-Day Listening Bar Chart
                        weeklyChartCard

                        // MARK: - 3. Key Milestone Metrics (2x2 Grid)
                        metricsGridCard

                        // MARK: - 4. Daily Goal Customizer
                        goalSelectorCard

                        // MARK: - 5. Top Reciters Leaderboard
                        topRecitersSection

                        // MARK: - 6. Daily Habit Notification Reminder
                        dailyReminderCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Quran Habit & Stats")
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
        }
    }

    // MARK: - 1. Hero Ring & Today's Metric Card
    private var todayProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("REPLACE MUSIC WITH QURAN")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.4)
                        .foregroundColor(Color(red: 0.35, green: 0.65, blue: 1.0))

                    Text("Today's Quran Listening")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                    Text("\(goalManager.streakDays) Days")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange.opacity(0.18))
                .clipShape(Capsule())
            }

            // Circular Progress Arc
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 14)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0.0, to: CGFloat(goalManager.progressRatio))
                    .stroke(
                        LinearGradient(
                            colors: [Color(red: 0.35, green: 0.65, blue: 1.0), BayanTheme.gold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalManager.progressRatio)

                VStack(spacing: 2) {
                    Text(goalManager.formattedTodayTime)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    Text("of \(goalManager.dailyGoalMinutes) min goal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.60))

                    Text("\(Int(goalManager.progressRatio * 100))%")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(BayanTheme.goldSoft)
                }
            }
            .frame(height: 150)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - 2. 7-Day Listening Bar Chart
    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This Week's Activity")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("Goal: \(goalManager.dailyGoalMinutes)m/day")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(BayanTheme.goldSoft)
            }

            // Bar Chart Columns
            let statuses = goalManager.weekdayStatuses
            let maxMins = max(Double(goalManager.dailyGoalMinutes) * 1.5, (statuses.map(\.minutes).max() ?? 30.0) * 1.1)

            HStack(alignment: .bottom, spacing: 10) {
                ForEach(statuses) { day in
                    VStack(spacing: 6) {
                        // Minute text
                        Text("\(Int(day.minutes))m")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(day.isToday ? BayanTheme.gold : .white.opacity(0.6))

                        // Column Bar
                        let barHeight = CGFloat(min(120.0, max(12.0, (day.minutes / maxMins) * 120.0)))
                        ZStack(alignment: .bottom) {
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 22, height: 120)

                            Capsule()
                                .fill(
                                    day.isToday ?
                                    LinearGradient(colors: [BayanTheme.gold, Color.orange], startPoint: .top, endPoint: .bottom) :
                                    (day.isAchieved ?
                                        LinearGradient(colors: [Color(red: 0.18, green: 0.85, blue: 0.50), Color(red: 0.10, green: 0.65, blue: 0.40)], startPoint: .top, endPoint: .bottom) :
                                        LinearGradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.12)], startPoint: .top, endPoint: .bottom)
                                    )
                                )
                                .frame(width: 22, height: barHeight)
                        }

                        // Weekday Symbol
                        Text(day.symbol)
                            .font(.system(size: 11, weight: day.isToday ? .heavy : .medium))
                            .foregroundColor(day.isToday ? .white : .white.opacity(0.55))

                        // Status dot
                        Circle()
                            .fill(day.isAchieved ? Color(red: 0.18, green: 0.85, blue: 0.50) : Color.white.opacity(0.15))
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 170)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - 3. Key Milestone Metrics (2x2 Grid)
    private var metricsGridCard: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricItem(title: "TOTAL QURAN TIME", value: goalManager.formattedTotalHours, icon: "clock.fill", color: BayanTheme.gold)
            metricItem(title: "DAILY AVERAGE", value: "\(goalManager.dailyAverageMinutes) min", icon: "chart.line.uptrend.xyaxis", color: Color(red: 0.35, green: 0.65, blue: 1.0))
            metricItem(title: "CURRENT STREAK", value: "\(goalManager.streakDays) Days", icon: "flame.fill", color: .orange)
            metricItem(title: "BEST STREAK", value: "\(goalManager.longestStreakDays) Days", icon: "trophy.fill", color: Color(red: 0.18, green: 0.85, blue: 0.50))
        }
    }

    private func metricItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 9.5, weight: .bold))
                .tracking(0.8)
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                )
        )
    }

    // MARK: - 4. Daily Goal Customizer
    private var goalSelectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Your Daily Listening Goal")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(goalOptions, id: \.self) { mins in
                        let isSelected = goalManager.dailyGoalMinutes == mins
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                goalManager.dailyGoalMinutes = mins
                            }
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            #endif
                        } label: {
                            Text("\(mins) min")
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .black : .white.opacity(0.85))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? BayanTheme.gold : Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - 5. Top Reciters Leaderboard
    private var topRecitersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Top Quran Reciters")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 10) {
                ForEach(goalManager.topRecitersLeaderboard.prefix(4), id: \.reciter.id) { item in
                    HStack(spacing: 12) {
                        ReciterAvatarView(
                            reciter: item.reciter,
                            size: 46,
                            isSelected: playerService.currentReciter.id == item.reciter.id,
                            borderWidth: 1.5,
                            hasGlow: playerService.currentReciter.id == item.reciter.id
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.reciter.nameEnglish)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)

                            Text("\(item.reciter.riwayah) • \(item.minutes) min listened")
                                .font(.system(size: 11))
                                .foregroundColor(BayanTheme.goldSoft)
                        }

                        Spacer()

                        Button {
                            playerService.currentReciter = item.reciter
                            if let s = playerService.currentSurah {
                                playerService.play(surah: s, ayah: playerService.currentAyah, reciter: item.reciter)
                            }
                            #if os(iOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            #endif
                        } label: {
                            Text("Listen")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(BayanTheme.gold)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.03))
                    )
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - 6. Daily Habit Notification Reminder
    private var dailyReminderCard: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $goalManager.isDailyReminderEnabled) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 16))
                        .foregroundColor(BayanTheme.gold)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Listening Reminder")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Text("Receive an inspiring daily nudge to hit your Quran goal")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
            }
            .tint(Color(red: 0.18, green: 0.85, blue: 0.50))

            if goalManager.isDailyReminderEnabled {
                Divider().background(Color.white.opacity(0.1))

                HStack {
                    Text("Reminder Time")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()

                    DatePicker("", selection: $goalManager.dailyReminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .colorScheme(.dark)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
