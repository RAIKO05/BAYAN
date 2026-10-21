import SwiftUI

// MARK: - Prayers Dashboard View (Matches User Reference UI)
public struct PrayersDashboardView: View {
    @State private var selectedDate: Date = Date()
    @State private var completedPrayers: Set<String> = []
    @State private var trackerService = PrayerTrackerService.shared
    @State private var calculationService = PrayerCalculationService.shared

    // Location coordinates (defaults to Casablanca, Morocco, or passed from location manager)
    public var latitude: Double = 33.5731
    public var longitude: Double = -7.5898

    public init(latitude: Double = 33.5731, longitude: Double = -7.5898) {
        self.latitude = latitude
        self.longitude = longitude
    }

    private var result: PrayerTimesDayResult {
        calculationService.calculate(for: selectedDate, lat: latitude, lng: longitude)
    }

    private var completedCount: Int {
        completedPrayers.count
    }

    public var body: some View {
        ZStack {
            // Dark forest green background
            Color(red: 0.03, green: 0.12, blue: 0.10).ignoresSafeArea()
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.18, blue: 0.14),
                    Color(red: 0.02, green: 0.08, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // MARK: 1. Date Navigation Header
                    dateHeaderRow
                        .padding(.top, 8)

                    // MARK: 2. Dual Hero Cards (Now Prayer + 2/5 Progress Gauge)
                    heroCardsRow

                    // MARK: 3. Daily Prayers List (Subuh, Dzuhur, Ashar, Maghrib, Isya)
                    prayersListSection

                    // MARK: 4. Action Button ("Mark all as prayed")
                    markAllButton
                        .padding(.top, 4)
                        .padding(.bottom, 120) // Clearance for floating tab bar
                }
                .padding(.horizontal, 18)
            }
        }
        .onAppear {
            refreshCompletedState()
        }
    }

    // MARK: - Date Header Row with < and > Navigation
    private var dateHeaderRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(result.gregorianDateString)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.white)

                Text(result.hijriDateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.70, green: 0.85, blue: 0.78))
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    navigateDate(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    navigateDate(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
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
                Text("Now")
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(0.14))
                    .foregroundColor(.white)
                    .clipShape(Capsule())

                HStack(spacing: 6) {
                    Text(result.currentPrayer.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Text(result.currentPrayer.emoji)
                        .font(.system(size: 16))
                }

                Text(result.currentPrayer.timeString)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(result.countdownSubtitle)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.70))
                    .lineLimit(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 145)
            .background(Color(red: 0.06, green: 0.20, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )

            // Right Hero Card (Circular Progress Gauge)
            VStack {
                ZStack {
                    // Gauge Background Ring
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 9)

                    // Gauge Progress Arc
                    Circle()
                        .trim(from: 0, to: CGFloat(completedCount) / 5.0)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.18, green: 0.88, blue: 0.50),
                                    Color(red: 0.10, green: 0.68, blue: 0.40)
                                ],
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
                                .fill(Color(red: 0.15, green: 0.82, blue: 0.48))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(y: -42)
                            Spacer()
                        }
                    }

                    // Center Labels: "2/5" and "prayed"
                    VStack(spacing: 2) {
                        Text("\(completedCount)/5")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("prayed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.68))
                    }
                }
                .frame(width: 88, height: 88)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 145)
            .background(Color(red: 0.06, green: 0.20, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )
        }
    }

    // MARK: - Prayers List Section
    private var prayersListSection: some View {
        VStack(spacing: 10) {
            ForEach(result.prayers) { prayer in
                PrayerCardRow(
                    prayer: prayer,
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
                .foregroundColor(Color(red: 0.03, green: 0.14, blue: 0.11))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(red: 0.18, green: 0.78, blue: 0.48))
                .clipShape(Capsule())
                .shadow(color: Color(red: 0.18, green: 0.78, blue: 0.48).opacity(0.35), radius: 10, y: 3)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Helpers
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
}

// MARK: - Individual Prayer Card Row (Exact Match with Image)
private struct PrayerCardRow: View {
    let prayer: PrayerTimeItem
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
                            .fill(Color(red: 0.15, green: 0.82, blue: 0.48))
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1.8)
                            .frame(width: 26, height: 26)
                    }
                }
            }
            .buttonStyle(.plain)

            // Prayer Name & Emoji
            HStack(spacing: 6) {
                Text(prayer.name)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundColor(.white)

                Text(prayer.emoji)
                    .font(.system(size: 15))
            }

            // Status Badge (Now / in Xh Ym)
            if prayer.isCurrent {
                Text("Now")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color.white.opacity(0.12))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            } else if prayer.isNext, let countdown = prayer.countdownString {
                Text(countdown)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color.white.opacity(0.12))
                    .foregroundColor(.white.opacity(0.85))
                    .clipShape(Capsule())
            }

            Spacer()

            // Prayer Time Display (e.g. 15.17)
            Text(prayer.timeString)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // Notification Speaker Toggle Button
            Button(action: onToggleMute) {
                Image(systemName: isMuted ? "speaker.slash" : "speaker.wave.2.fill")
                    .font(.system(size: 13.5))
                    .foregroundColor(isMuted ? .white.opacity(0.35) : Color(red: 0.70, green: 0.85, blue: 0.78))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            isPrayed || prayer.isCurrent
                ? Color(red: 0.08, green: 0.26, blue: 0.20)
                : Color(red: 0.06, green: 0.20, blue: 0.16)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    prayer.isCurrent
                        ? Color(red: 0.20, green: 0.75, blue: 0.45).opacity(0.4)
                        : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
        .shadow(
            color: (isPrayed || prayer.isCurrent) ? Color(red: 0.10, green: 0.50, blue: 0.30).opacity(0.18) : Color.clear,
            radius: 8,
            y: 3
        )
    }
}
