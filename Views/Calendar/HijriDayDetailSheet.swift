import SwiftUI

// MARK: - Hijri Day Detail & Fasting Intention Sheet
public struct HijriDayDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let day: HijriDay
    public let latitude: Double
    public let longitude: Double

    @State private var calendarService = HijriCalendarService.shared
    @State private var calculationService = PrayerCalculationService.shared
    @State private var prayerSettings = PrayerSettingsManager.shared
    @State private var themeManager = AppThemeManager.shared

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)

    public init(day: HijriDay, latitude: Double = 33.5731, longitude: Double = -7.5898) {
        self.day = day
        self.latitude = latitude
        self.longitude = longitude
    }

    private var isFasted: Bool {
        calendarService.isFasted(date: day.date)
    }

    private var prayerResult: PrayerTimesDayResult {
        calculationService.calculate(
            for: day.date,
            lat: latitude,
            lng: longitude,
            convention: prayerSettings.convention,
            asrSchool: prayerSettings.asrSchool
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                        eventBanner
                        fastingInfoCard
                        fastingActionButton
                        timetableCard
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BayanTheme.gold)
                    .font(.system(size: 14, weight: .bold))
                }
            }
        }
    }

    // MARK: - Subviews
    private var headerCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text(day.lunarPhase.nameArabic)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(BayanTheme.gold)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: day.lunarPhase.icon)
                        .font(.system(size: 14))
                    Text("\(day.lunarIlluminationPercent)%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }

            Text(day.formattedHijriArabic)
                .font(.quran(size: 26))
                .foregroundColor(BayanTheme.gold)
                .multilineTextAlignment(.center)
                .padding(.vertical, 4)

            Text(day.formattedHijriEnglish)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text(prayerResult.gregorianDateString)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.65))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.10, green: 0.12, blue: 0.16).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(day.isToday ? BayanTheme.gold : Color.white.opacity(0.08), lineWidth: day.isToday ? 1.5 : 1)
                )
        )
    }

    @ViewBuilder
    private var eventBanner: some View {
        if let event = day.islamicEvent {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundColor(BayanTheme.gold)

                Text(event)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(BayanTheme.gold.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(BayanTheme.gold.opacity(0.35), lineWidth: 1)
                    )
            )
        }
    }

    @ViewBuilder
    private var fastingInfoCard: some View {
        if day.fastingType.isRecommendedFast {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 16))
                        .foregroundColor(spotifyGreen)

                    Text(day.fastingType.titleArabic)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(spotifyGreen)

                    Spacer()

                    Text(day.fastingType.titleEnglish)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }

                if let virtue = day.fastingType.hadithVirtue {
                    Text(virtue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(4)
                        .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(spotifyGreen.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(spotifyGreen.opacity(0.35), lineWidth: 1)
                    )
            )
        } else if day.fastingType == .prohibited {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                Text(day.fastingType.hadithVirtue ?? "Prohibited Fasting Day")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(14)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private var fastingActionButton: some View {
        if day.fastingType != .prohibited {
            Button {
                calendarService.toggleFasted(date: day.date)
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: isFasted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .bold))
                    Text(isFasted ? "Fasted (صمتُ هذا اليوم • الحمد لله)" : "Mark as Fasted (سجل صيام اليوم)")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(isFasted ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isFasted ? spotifyGreen : Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isFasted ? spotifyGreen : Color.white.opacity(0.15), lineWidth: 1)
                )
            }
        }
    }

    private var timetableCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Fasting Timetable")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(BayanTheme.gold)

                Spacer()

                Text(prayerResult.conventionName)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 14) {
                if let fajr = prayerResult.prayers.first(where: { $0.type == .fajr }) {
                    timeBox(title: "Suhoor Ends (Fajr)", time: fajr.timeString, arabic: "الإمساك / الفجر", icon: "sun.haze.fill", color: .cyan)
                }

                if let maghrib = prayerResult.prayers.first(where: { $0.type == .maghrib }) {
                    timeBox(title: "Iftar (Maghrib)", time: maghrib.timeString, arabic: "الإفطار / المغرب", icon: "sunset.fill", color: .orange)
                }
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
    }

    private func timeBox(title: String, time: String, arabic: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
            }

            Text(time)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(arabic)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
