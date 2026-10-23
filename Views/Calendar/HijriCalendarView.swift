import SwiftUI

// MARK: - Islamic Hijri Calendar & Sunnah Fasting Tracker View
public struct HijriCalendarView: View {
    public let latitude: Double
    public let longitude: Double

    @State private var calendarService = HijriCalendarService.shared
    @State private var notificationService = FastingNotificationService.shared
    @State private var themeManager = AppThemeManager.shared

    @State private var activeHijriMonth: Int
    @State private var activeHijriYear: Int
    @State private var selectedDayForDetail: HijriDay? = nil
    @State private var showingOffsetSheet: Bool = false

    private let spotifyGreen = Color(red: 0.18, green: 0.85, blue: 0.50)
    private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let weekdayArabic = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]

    public init(latitude: Double = 33.5731, longitude: Double = -7.5898) {
        self.latitude = latitude
        self.longitude = longitude
        let current = HijriCalendarService.shared.currentHijriDay()
        _activeHijriMonth = State(initialValue: current.hijriMonth)
        _activeHijriYear = State(initialValue: current.hijriYear)
    }

    private var monthDays: [HijriDay] {
        calendarService.days(forHijriMonth: activeHijriMonth, year: activeHijriYear)
    }

    private var activeMonthArabic: String {
        calendarService.monthNamesArabic[activeHijriMonth] ?? "شهر"
    }

    private var activeMonthEnglish: String {
        calendarService.monthNamesEnglish[activeHijriMonth] ?? "Month"
    }

    private var isCurrentMonthSacred: Bool {
        calendarService.sacredMonths.contains(activeHijriMonth)
    }

    private var gregorianDateRangeString: String {
        guard let first = monthDays.first?.date, let last = monthDays.last?.date else { return "" }
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "en_US")
        let fYear = DateFormatter()
        fYear.dateFormat = "yyyy"
        return "\(f.string(from: first)) – \(f.string(from: last)), \(fYear.string(from: last))"
    }

    private var firstWeekdayOffset: Int {
        guard let firstDate = monthDays.first?.date else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: firstDate) // 1 = Sunday
        return weekday - 1
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // MARK: 1. Month Header & Navigation
                monthNavigationHeader
                    .padding(.top, 4)

                // MARK: 2. Fasting Tracker & Sacred Month Bar
                fastingTrackerStatusBar

                // MARK: 3. 7-Column Hijri Calendar Grid
                calendarGridCard

                // MARK: 4. Next Recommended Sunnah Fast Card
                nextSunnahFastCard
                    .padding(.bottom, 120) // Clearance for floating tab bar
            }
            .frame(maxWidth: 780)
            .padding(.horizontal, 16)
        }
        .sheet(item: $selectedDayForDetail) { day in
            HijriDayDetailSheet(day: day, latitude: latitude, longitude: longitude)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingOffsetSheet) {
            moonSightingAdjustmentSheet
                .presentationDetents([.fraction(0.35)])
        }
    }

    // MARK: - Month Navigation Header
    private var monthNavigationHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(activeMonthArabic) \(activeHijriYear) هـ")
                        .font(.quran(size: 22))
                        .foregroundColor(BayanTheme.gold)

                    if isCurrentMonthSacred {
                        Text("شهرٌ حَرَام")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(BayanTheme.goldSoft)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BayanTheme.gold.opacity(0.18))
                            .clipShape(Capsule())
                    }
                }

                Text("\(activeMonthEnglish) \(activeHijriYear) AH • \(gregorianDateRangeString)")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
            }

            Spacer()

            HStack(spacing: 8) {
                // Moon Offset Adjustment Button
                Button {
                    showingOffsetSheet = true
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 10))
                        Text(calendarService.dayOffset == 0 ? "Offset" : "\(calendarService.dayOffset > 0 ? "+" : "")\(calendarService.dayOffset)d")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Previous Month
                Button {
                    navigateMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.prayerTextColor)
                        .frame(width: 32, height: 32)
                        .background(themeManager.currentTheme.cardBorder.opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Next Month
                Button {
                    navigateMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.prayerTextColor)
                        .frame(width: 32, height: 32)
                        .background(themeManager.currentTheme.cardBorder.opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Fasting Tracker Status Bar
    private var fastingTrackerStatusBar: some View {
        HStack(spacing: 12) {
            // Days Fasted in Month
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(spotifyGreen)
                    .font(.system(size: 14))

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(calendarService.monthlyFastedCount(hijriMonth: activeHijriMonth, year: activeHijriYear)) Days Fasted")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("In \(activeMonthEnglish)")
                        .font(.system(size: 10.5))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Notification Bell Toggle
            Button {
                notificationService.isFastingRemindersEnabled.toggle()
                if notificationService.isFastingRemindersEnabled {
                    notificationService.requestAuthorization()
                }
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: notificationService.isFastingRemindersEnabled ? "bell.badge.fill" : "bell.slash")
                        .font(.system(size: 14))
                        .foregroundColor(notificationService.isFastingRemindersEnabled ? BayanTheme.gold : .white.opacity(0.4))

                    Text(notificationService.isFastingRemindersEnabled ? "Alerts On" : "Alerts")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(notificationService.isFastingRemindersEnabled ? BayanTheme.gold : .white.opacity(0.6))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(notificationService.isFastingRemindersEnabled ? BayanTheme.gold.opacity(0.15) : Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 7-Column Hijri Calendar Grid Card
    private var calendarGridCard: some View {
        VStack(spacing: 12) {
            // Weekday Headers
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { idx in
                    VStack(spacing: 2) {
                        Text(weekdaySymbols[idx])
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(idx == 5 ? BayanTheme.gold : .white.opacity(0.6)) // Friday = idx 5
                        Text(weekdayArabic[idx])
                            .font(.system(size: 9))
                            .foregroundColor(idx == 5 ? BayanTheme.goldSoft : .white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 6)

            Divider()
                .background(Color.white.opacity(0.08))

            // Days Matrix
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                // Leading blank cells for offset
                ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                    Color.clear
                        .frame(height: 58)
                }

                // Month Day Cells
                ForEach(monthDays) { day in
                    dayCell(day: day)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.10, green: 0.11, blue: 0.15).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // Single Day Cell
    private func dayCell(day: HijriDay) -> some View {
        let isFasted = calendarService.isFasted(date: day.date)
        let isSunnah = day.fastingType.isRecommendedFast

        return Button {
            selectedDayForDetail = day
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            VStack(spacing: 2) {
                // Top Tag: Fasting sprout or checkmark
                HStack(spacing: 2) {
                    if isFasted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(spotifyGreen)
                    } else if isSunnah {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 8))
                            .foregroundColor(spotifyGreen)
                    }

                    Spacer()

                    // Gregorian Date number
                    Text("\(Calendar.current.component(.day, from: day.date))")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 4)

                // Large Hijri Day Number
                Text("\(day.hijriDay)")
                    .font(.system(size: 16, weight: day.isToday ? .heavy : .bold, design: .rounded))
                    .foregroundColor(day.isToday ? BayanTheme.gold : (isFasted ? spotifyGreen : .white))

                // Lunar Phase or Event Dot
                if day.islamicEvent != nil {
                    Circle()
                        .fill(BayanTheme.gold)
                        .frame(width: 4, height: 4)
                } else {
                    Image(systemName: day.lunarPhase.icon)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(day.isToday ? BayanTheme.gold.opacity(0.18) : (isFasted ? spotifyGreen.opacity(0.12) : Color.white.opacity(0.04)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        day.isToday ? BayanTheme.gold : (isSunnah ? spotifyGreen.opacity(0.4) : Color.white.opacity(0.06)),
                        lineWidth: day.isToday ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Next Recommended Sunnah Fast Card
    private var nextSunnahFastCard: some View {
        Group {
            if let nextFast = calendarService.nextUpcomingSunnahFast() {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(spotifyGreen.opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 18))
                            .foregroundColor(spotifyGreen)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Next Recommended Fast (الصيام القادم)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(spotifyGreen)

                        Text("\(nextFast.fastingType.titleArabic) • \(nextFast.formattedHijriArabic)")
                            .font(.system(size: 13.5, weight: .bold))
                            .foregroundColor(.white)

                        Text(nextFast.fastingType.titleEnglish)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()

                    Button {
                        selectedDayForDetail = nextFast
                    } label: {
                        Text("View")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(BayanTheme.gold)
                            .clipShape(Capsule())
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.10, green: 0.12, blue: 0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(spotifyGreen.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }

    // MARK: - Moon Sighting Adjustment Sheet
    private var moonSightingAdjustmentSheet: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            Text("Moon Sighting Offset (تعديل رؤية الهلال)")
                .font(.headline.weight(.bold))
                .foregroundColor(.white)

            Text("Adjust Hijri calendar by ±1 or ±2 days to match your local country's moon sighting authority.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 12) {
                ForEach([-2, -1, 0, 1, 2], id: \.self) { val in
                    Button {
                        calendarService.dayOffset = val
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Text(val == 0 ? "Standard" : "\(val > 0 ? "+" : "")\(val)d")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(calendarService.dayOffset == val ? .black : .white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(calendarService.dayOffset == val ? BayanTheme.gold : Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(red: 0.08, green: 0.09, blue: 0.12).ignoresSafeArea())
    }

    private func navigateMonth(by step: Int) {
        var m = activeHijriMonth + step
        var y = activeHijriYear
        if m < 1 {
            m = 12
            y -= 1
        } else if m > 12 {
            m = 1
            y += 1
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            activeHijriMonth = m
            activeHijriYear = y
        }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
