import SwiftUI

// MARK: - Daily Quran Goal & Top Reciter Card
/// Inspired by the "Replace Music With Quran" screen:
/// 1. Semicircular listening arc gauge (e.g. "Today's listening 2:32 of your 10-minute goal")
/// 2. Weekday streak indicators (Mon -> Sun)
/// 3. Top Reciter spotlight card with circular portrait photo & "Start listening"
public struct DailyQuranGoalCard: View {
    @State private var goalManager = QuranListeningGoalManager.shared
    @State private var playerService = AudioPlayerService.shared
    var onContinueListening: () -> Void

    public init(onContinueListening: @escaping () -> Void = {}) {
        self.onContinueListening = onContinueListening
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Title
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("REPLACE MUSIC WITH QURAN")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.4)
                        .foregroundColor(Color(red: 0.35, green: 0.65, blue: 1.0))

                    Text("استبدل الغناء بالقرآن")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(goalManager.streakDays) day streak")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            // Main Goal Gauge Card
            VStack(spacing: 12) {
                HStack {
                    Text("Daily goal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.70))
                    Spacer()
                    Text("\(goalManager.dailyGoalMinutes) min goal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BayanTheme.goldSoft)
                }

                // Semicircular Arc Gauge & Time
                ZStack {
                    // Gauge Background Arc
                    Circle()
                        .trim(from: 0.25, to: 0.75)
                        .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(90))

                    // Gauge Progress Arc
                    Circle()
                        .trim(from: 0.25, to: 0.25 + (goalManager.progressRatio * 0.50))
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.35, green: 0.65, blue: 1.0), BayanTheme.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalManager.progressRatio)

                    VStack(spacing: 2) {
                        Text("Today's listening")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.60))

                        Text(goalManager.formattedTodayTime)
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundColor(.white)

                        Text("of your \(goalManager.dailyGoalMinutes)-minute goal")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.50))
                    }
                }
                .frame(height: 100)
                .padding(.top, 4)

                // Continue Listening Button
                Button {
                    onContinueListening()
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: playerService.isPlaying ? "waveform" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(playerService.isPlaying ? "Currently Listening" : "Continue listening")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                // Weekday Streak Row
                HStack(spacing: 0) {
                    ForEach(goalManager.weekdayStatuses) { day in
                        VStack(spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(day.isAchieved ? Color.white.opacity(0.95) : (day.isToday ? Color.white.opacity(0.25) : Color.white.opacity(0.06)))
                                    .frame(width: 22, height: 22)

                                if day.isAchieved {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.black)
                                } else if day.isPast && !day.isAchieved {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white.opacity(0.40))
                                } else if day.isToday {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                        .frame(width: 14, height: 14)
                                }
                            }

                            Text(day.symbol)
                                .font(.system(size: 9, weight: day.isToday ? .bold : .medium))
                                .foregroundColor(day.isToday ? .white : .white.opacity(0.45))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 6)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.12, blue: 0.17).opacity(0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )

            // Top Reciter Card
            let top = goalManager.topReciter
            VStack(alignment: .leading, spacing: 8) {
                Text("Top reciter")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.70))
                    .padding(.horizontal, 4)

                HStack(spacing: 14) {
                    // Reciter Photo
                    ReciterAvatarView(
                        reciter: top.reciter,
                        size: 54,
                        isSelected: top.reciter.id == playerService.currentReciter.id,
                        borderWidth: 2
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(top.minutes) min • 114 surahs")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))

                        Text(top.reciter.nameEnglish)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(top.reciter.nameArabic)
                            .font(.system(size: 11))
                            .foregroundColor(BayanTheme.goldSoft)
                    }

                    Spacer()

                    // Start Listening Button
                    Button {
                        playerService.currentReciter = top.reciter
                        onContinueListening()
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Start")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.11, green: 0.13, blue: 0.18).opacity(0.90))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
        }
    }
}
