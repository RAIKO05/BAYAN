import SwiftUI
import Combine

// MARK: - Prayers Dashboard View (Fully Synchronized with App Theme)
public struct PrayersDashboardView: View {
    @State private var selectedDate: Date = Date()
    @State private var completedPrayers: Set<String> = []
    @State private var trackerService = PrayerTrackerService.shared
    @State private var calculationService = PrayerCalculationService.shared
    @State private var adhanService = AdhanAudioService.shared
    @State private var themeManager = AppThemeManager.shared
    @State private var prayerSettings = PrayerSettingsManager.shared
    @State private var showingSettingsSheet = false
    @State private var lastTriggeredPrayerKey: String = ""

    // Location coordinates (defaults to Casablanca, Morocco, or passed from location manager)
    public var latitude: Double = 33.5731
    public var longitude: Double = -7.5898

    public init(latitude: Double = 33.5731, longitude: Double = -7.5898) {
        self.latitude = latitude
        self.longitude = longitude
    }

    private var result: PrayerTimesDayResult {
        calculationService.calculate(
            for: selectedDate,
            lat: latitude,
            lng: longitude,
            convention: prayerSettings.convention,
            asrSchool: prayerSettings.asrSchool
        )
    }

    private var completedCount: Int {
        completedPrayers.count
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // MARK: 1. Date Navigation Header (Clear spacing below mode pill)
                dateHeaderRow
                    .padding(.top, 8)

                // MARK: 2. Dual Hero Cards (Now Prayer + Progress Gauge)
                heroCardsRow

                // MARK: 2b. Adhan Now Playing Banner (if active)
                if adhanService.isPlaying {
                    adhanNowPlayingBanner
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }

                // MARK: 3. Daily Prayers List (Subuh, Dzuhur, Ashar, Maghrib, Isya)
                prayersListSection

                // MARK: 4. Action Button ("Mark all as prayed")
                markAllButton
                    .padding(.top, 4)
                    .padding(.bottom, 120) // Clearance for floating tab bar
            }
            .padding(.horizontal, 18)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            PrayerSettingsSheet(
                prayerSettings: prayerSettings,
                currentTheme: themeManager.currentTheme,
                prayerTimes: result.prayers
            )
            .presentationDetents([.fraction(0.72), .large])
        }
        .onAppear {
            refreshCompletedState()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            checkPrayerTimeTrigger()
        }
    }

    // MARK: - Date Header Row with < and > Navigation
    private var dateHeaderRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(result.gregorianDateString)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.prayerTextColor)

                Text(result.hijriDateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.prayerSecondaryTextColor)
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    navigateDate(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.prayerTextColor)
                        .frame(width: 34, height: 34)
                        .background(themeManager.currentTheme.cardBorder.opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    navigateDate(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.prayerTextColor)
                        .frame(width: 34, height: 34)
                        .background(themeManager.currentTheme.cardBorder.opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    showingSettingsSheet = true
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.prayerActiveAccent)
                        .frame(width: 34, height: 34)
                        .background(themeManager.currentTheme.prayerActiveAccent.opacity(0.15))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(themeManager.currentTheme.prayerActiveAccent.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Dual Hero Cards Row
    private var heroCardsRow: some View {
        HStack(spacing: 14) {
            // Left Hero Card (Current Active Prayer)
            VStack(alignment: .leading, spacing: 8) {
                // Top row: "Now" badge on left, Adhan play/stop button on right
                HStack {
                    Text("Now")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3.5)
                        .background(themeManager.currentTheme.prayerActiveAccent.opacity(0.2))
                        .foregroundColor(themeManager.currentTheme.prayerActiveAccent)
                        .clipShape(Capsule())

                    Spacer()

                    Button {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                        adhanService.toggleAdhan(for: result.currentPrayer.name)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: adhanService.isPlaying ? "stop.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 9.5, weight: .bold))
                            Text(adhanService.isPlaying ? "Stop" : "Adhan")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(adhanService.isPlaying ? Color.red.opacity(0.85) : themeManager.currentTheme.prayerActiveAccent)
                        .foregroundColor(adhanService.isPlaying ? .white : (themeManager.currentTheme.isDark ? BayanTheme.obsidian : .white))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 6) {
                    Text(result.currentPrayer.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.prayerTextColor)
                    Text(result.currentPrayer.emoji)
                        .font(.system(size: 16))
                }

                Text(result.currentPrayer.timeString)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.prayerTextColor)

                Text(result.countdownSubtitle)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.prayerSecondaryTextColor)
                    .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 145)
            .background(themeManager.currentTheme.heroCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(themeManager.currentTheme.cardBorder, lineWidth: 1)
            )

            // Right Hero Card (Circular Progress Gauge)
            VStack {
                ZStack {
                    // Gauge Background Ring
                    Circle()
                        .stroke(themeManager.currentTheme.cardBorder.opacity(0.35), lineWidth: 9)

                    // Gauge Progress Arc
                    Circle()
                        .trim(from: 0, to: CGFloat(completedCount) / 5.0)
                        .stroke(
                            LinearGradient(
                                colors: themeManager.currentTheme.prayerGaugeGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: completedCount)

                    // Optional Mini Checkmark Indicator at Top
                    if completedCount > 0 {
                        VStack {
                            Circle()
                                .fill(themeManager.currentTheme.prayerActiveAccent)
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(themeManager.currentTheme.isDark ? BayanTheme.obsidian : .white)
                                )
                                .offset(y: -42)
                            Spacer()
                        }
                    }

                    // Center Labels: "2/5" and "prayed"
                    VStack(spacing: 2) {
                        Text("\(completedCount)/5")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.prayerTextColor)

                        Text("prayed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.prayerSecondaryTextColor)
                    }
                }
                .frame(width: 88, height: 88)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 145)
            .background(themeManager.currentTheme.heroCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(themeManager.currentTheme.cardBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Adhan Now Playing Banner
    private var adhanNowPlayingBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(themeManager.currentTheme.prayerActiveAccent.opacity(0.2))
                    .frame(width: 38, height: 38)
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.prayerActiveAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("الأذان • Now Playing")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.prayerTextColor)
                    Text(adhanService.currentPrayerName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.prayerActiveAccent)
                }

                Text("حي على الصلاة • حي على الفلاح")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(themeManager.currentTheme.prayerSecondaryTextColor)
            }

            Spacer()

            Button {
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif
                adhanService.stopAdhan()
            } label: {
                Text("Stop")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.85))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(themeManager.currentTheme.heroCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(themeManager.currentTheme.prayerActiveAccent.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Prayers List Section
    private var prayersListSection: some View {
        VStack(spacing: 10) {
            ForEach(result.prayers) { prayer in
                PrayerCardRow(
                    prayer: prayer,
                    theme: themeManager.currentTheme,
                    isPrayed: completedPrayers.contains(prayer.id),
                    isMuted: trackerService.mutedPrayerIds.contains(prayer.id),
                    onTogglePrayed: {
                        togglePrayer(prayer.id)
                    },
                    onToggleMute: {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        trackerService.toggleMute(prayerId: prayer.id)
                    }
                )
            }
        }
    }

    // MARK: - Action Button
    private var markAllButton: some View {
        Button {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                let allIds = result.prayers.map(\.id)
                completedPrayers = trackerService.markAll(for: selectedDate, allIds: allIds)
            }
        } label: {
            Text(completedCount == 5 ? "Reset all for today" : "Mark all as prayed")
                .font(.system(size: 14.5, weight: .bold))
                .foregroundColor(themeManager.currentTheme.isDark ? BayanTheme.obsidian : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(themeManager.currentTheme.prayerActiveAccent)
                .clipShape(Capsule())
                .shadow(color: themeManager.currentTheme.prayerActiveAccent.opacity(0.35), radius: 10, y: 3)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Helpers & Prayer Trigger
    private func navigateDate(by days: Int) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        if let next = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = next
                refreshCompletedState()
            }
        }
    }

    private func togglePrayer(_ id: String) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            completedPrayers = trackerService.togglePrayer(id, for: selectedDate)
        }
    }

    private func refreshCompletedState() {
        completedPrayers = trackerService.getCompletedPrayers(for: selectedDate)
    }

    private func checkPrayerTimeTrigger() {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 0

        for prayer in result.prayers {
            let parts = prayer.timeString.split(separator: ":")
            guard parts.count == 2,
                  let hour = Int(parts[0]),
                  let minute = Int(parts[1]) else { continue }

            if currentHour == hour && currentMinute == minute {
                let triggerKey = "\(prayer.id)_\(dayOfYear)_\(hour):\(minute)"
                if lastTriggeredPrayerKey != triggerKey {
                    lastTriggeredPrayerKey = triggerKey
                    if !trackerService.mutedPrayerIds.contains(prayer.id) {
                        adhanService.playAdhan(for: prayer.name)
                    }
                }
            }
        }
    }
}

// MARK: - Individual Prayer Card Row (Theme-Aware)
private struct PrayerCardRow: View {
    let prayer: PrayerTimeItem
    let theme: QuranTheme
    let isPrayed: Bool
    let isMuted: Bool
    let onTogglePrayed: () -> Void
    let onToggleMute: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkmark Circle Button
            Button(action: onTogglePrayed) {
                ZStack {
                    if isPrayed {
                        Circle()
                            .fill(theme.prayerActiveAccent)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.isDark ? BayanTheme.obsidian : .white)
                    } else {
                        Circle()
                            .stroke(theme.prayerSecondaryTextColor.opacity(0.35), lineWidth: 1.8)
                            .frame(width: 26, height: 26)
                    }
                }
            }
            .buttonStyle(.plain)

            // Prayer Name & Emoji
            HStack(spacing: 6) {
                Text(prayer.name)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundColor(theme.prayerTextColor)

                Text(prayer.emoji)
                    .font(.system(size: 15))
            }

            // Status Badge (Now / in Xh Ym)
            if prayer.isCurrent {
                Text("Now")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(theme.prayerActiveAccent.opacity(0.18))
                    .foregroundColor(theme.prayerActiveAccent)
                    .clipShape(Capsule())
            } else if prayer.isNext, let countdown = prayer.countdownString {
                Text(countdown)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(theme.prayerCardBorder.opacity(0.35))
                    .foregroundColor(theme.prayerSecondaryTextColor)
                    .clipShape(Capsule())
            }

            Spacer()

            // Prayer Time Display (e.g. 15.17)
            Text(prayer.timeString)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(theme.prayerTextColor)

            // Notification Speaker Toggle Button
            Button(action: onToggleMute) {
                Image(systemName: isMuted ? "speaker.slash" : "speaker.wave.2.fill")
                    .font(.system(size: 13.5))
                    .foregroundColor(isMuted ? theme.prayerSecondaryTextColor.opacity(0.35) : theme.prayerActiveAccent)
                    .frame(width: 32, height: 32)
                    .background(theme.prayerCardBorder.opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            isPrayed || prayer.isCurrent
                ? theme.prayerCardActiveBackground
                : theme.prayerCardBackground
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    prayer.isCurrent
                        ? theme.prayerActiveAccent.opacity(0.6)
                        : theme.prayerCardBorder,
                    lineWidth: prayer.isCurrent ? 1.5 : 1
                )
        )
        .shadow(
            color: (isPrayed || prayer.isCurrent) ? theme.prayerActiveAccent.opacity(0.15) : Color.clear,
            radius: 8,
            y: 3
        )
    }
}

// MARK: - Prayer Settings Sheet (Calculation Method, Asr Juristic School & 15m Pre-Adhan Reminder)
private struct PrayerSettingsSheet: View {
    @Bindable var prayerSettings: PrayerSettingsManager
    let currentTheme: QuranTheme
    let prayerTimes: [PrayerTimeItem]
    @Environment(\.dismiss) private var dismiss
    @State private var adhanNotificationService = AdhanNotificationService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    // 1. Calculation Convention Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CALCULATION METHOD")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(currentTheme.prayerActiveAccent)

                        VStack(spacing: 8) {
                            ForEach(CalculationConvention.allCases) { convention in
                                let isSelected = prayerSettings.convention == convention
                                Button {
                                    prayerSettings.convention = convention
                                    adhanNotificationService.scheduleAdhanNotifications(prayerTimes: prayerTimes)
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(convention.title)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(currentTheme.prayerTextColor)
                                            Text(convention.subtitle)
                                                .font(.system(size: 11))
                                                .foregroundColor(currentTheme.prayerSecondaryTextColor)
                                        }

                                        Spacer()

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(currentTheme.prayerActiveAccent)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(isSelected ? currentTheme.prayerActiveAccent.opacity(0.12) : currentTheme.prayerCardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(isSelected ? currentTheme.prayerActiveAccent.opacity(0.4) : currentTheme.prayerCardBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // 2. Asr Juristic School Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ASR JURISTIC SCHOOL")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(currentTheme.prayerActiveAccent)

                        VStack(spacing: 8) {
                            ForEach(AsrJuristicSchool.allCases) { school in
                                let isSelected = prayerSettings.asrSchool == school
                                Button {
                                    prayerSettings.asrSchool = school
                                    adhanNotificationService.scheduleAdhanNotifications(prayerTimes: prayerTimes)
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(school.title)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(currentTheme.prayerTextColor)
                                            Text(school.subtitle)
                                                .font(.system(size: 11))
                                                .foregroundColor(currentTheme.prayerSecondaryTextColor)
                                        }

                                        Spacer()

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(currentTheme.prayerActiveAccent)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(isSelected ? currentTheme.prayerActiveAccent.opacity(0.12) : currentTheme.prayerCardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(isSelected ? currentTheme.prayerActiveAccent.opacity(0.4) : currentTheme.prayerCardBorder, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // 3. Reminders & Alerts Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("REMINDERS & NOTIFICATIONS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(currentTheme.prayerActiveAccent)

                        VStack(spacing: 12) {
                            // Full Adhan Audio Notification Toggle
                            Toggle(isOn: Binding(
                                get: { adhanNotificationService.isNotificationsEnabled },
                                set: { newValue in
                                    if newValue {
                                        adhanNotificationService.requestPermission { granted in
                                            if granted {
                                                adhanNotificationService.scheduleAdhanNotifications(prayerTimes: prayerTimes)
                                            }
                                        }
                                    } else {
                                        adhanNotificationService.cancelAll()
                                    }
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Adhan Audio Notifications")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(currentTheme.prayerTextColor)
                                    Text("Play authentic Adhan call to prayer when prayer time arrives")
                                        .font(.system(size: 11))
                                        .foregroundColor(currentTheme.prayerSecondaryTextColor)
                                }
                            }
                            .tint(currentTheme.prayerActiveAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(currentTheme.prayerCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(currentTheme.prayerCardBorder, lineWidth: 1)
                            )

                            // 15-Minute Pre-Adhan Reminder Toggle
                            Toggle(isOn: Binding(
                                get: { prayerSettings.isPreAdhanReminderEnabled },
                                set: { newValue in
                                    prayerSettings.isPreAdhanReminderEnabled = newValue
                                    adhanNotificationService.scheduleAdhanNotifications(prayerTimes: prayerTimes)
                                    #if os(iOS)
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    #endif
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("15-Minute Pre-Adhan Reminder")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(currentTheme.prayerTextColor)
                                    Text("Alert 15 minutes before prayer time for preparation & wudu")
                                        .font(.system(size: 11))
                                        .foregroundColor(currentTheme.prayerSecondaryTextColor)
                                }
                            }
                            .tint(currentTheme.prayerActiveAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(currentTheme.prayerCardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(currentTheme.prayerCardBorder, lineWidth: 1)
                            )

                            // Preview Authentic Adhan Button
                            Button {
                                AdhanAudioService.shared.toggleAdhan(for: "الأذان")
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: AdhanAudioService.shared.isPlaying ? "stop.circle.fill" : "speaker.wave.3.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(currentTheme.prayerActiveAccent)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(AdhanAudioService.shared.isPlaying ? "Stop Adhan Preview" : "Play Authentic Adhan Audio")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(currentTheme.prayerTextColor)
                                        Text("Listen to the authentic bundled Adhan sound")
                                            .font(.system(size: 10))
                                            .foregroundColor(currentTheme.prayerSecondaryTextColor)
                                    }

                                    Spacer()

                                    Text(AdhanAudioService.shared.isPlaying ? "STOP" : "PREVIEW")
                                        .font(.system(size: 10, weight: .black))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(currentTheme.prayerActiveAccent.opacity(0.18))
                                        .foregroundColor(currentTheme.prayerActiveAccent)
                                        .clipShape(Capsule())
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(currentTheme.prayerCardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(AdhanAudioService.shared.isPlaying ? currentTheme.prayerActiveAccent : currentTheme.prayerCardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(18)
            }
            .background(currentTheme.backgroundColor.ignoresSafeArea())
            .navigationTitle("Prayer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(currentTheme.prayerActiveAccent)
                }
            }
        }
    }
}
