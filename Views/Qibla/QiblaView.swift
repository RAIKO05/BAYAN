import SwiftUI
import CoreLocation

// MARK: - Qibla Compass View
public struct QiblaView: View {
    @StateObject private var compassManager = CompassHeadingManager()
    @State private var selectedCity: QiblaCity = .defaultCity
    @State private var useLiveGPS = true
    @State private var showingCitySheet = false
    @State private var wasAligned = false
    @State private var selectedMode: QiblaTabMode = .prayers
    @State private var themeManager = AppThemeManager.shared

    public enum QiblaTabMode: String, CaseIterable {
        case prayers = "Prayers"
        case calendar = "Calendar"
        case compass = "Compass"
    }
 
    public init() {}

    private var activeHeading: Double {
        compassManager.heading
    }

    private var activeLatitude: Double {
        if useLiveGPS, let coord = compassManager.userCoordinate {
            return coord.latitude
        }
        return selectedCity.latitude
    }

    private var activeLongitude: Double {
        if useLiveGPS, let coord = compassManager.userCoordinate {
            return coord.longitude
        }
        return selectedCity.longitude
    }

    private var displayLocationName: String {
        if useLiveGPS, compassManager.userCoordinate != nil {
            return compassManager.userCityName ?? "Current Location (GPS)"
        }
        return "\(selectedCity.name), \(selectedCity.country)"
    }

    private var qiblaBearing: Double {
        calculateQiblaBearing(lat: activeLatitude, lng: activeLongitude)
    }

    private var distanceToKaaba: Int {
        calculateDistance(lat: activeLatitude, lng: activeLongitude)
    }

    private var headingDifference: Double {
        var diff = qiblaBearing - activeHeading
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    private var isAligned: Bool {
        abs(headingDifference) <= 2.0
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background seamlessly matching active theme
                themeManager.currentTheme.backgroundColor.ignoresSafeArea()
                themeManager.currentTheme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 0) {
                    modeSwitcherPill
                        .padding(.top, 8)
                        .padding(.bottom, 8)

                    Group {
                        switch selectedMode {
                        case .prayers:
                            PrayersDashboardView(latitude: activeLatitude, longitude: activeLongitude)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                    removal: .opacity
                                ))
                        case .calendar:
                            HijriCalendarView(latitude: activeLatitude, longitude: activeLongitude)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                    removal: .opacity
                                ))
                        case .compass:
                            compassScrollView
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.98)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.82), value: selectedMode)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: isAligned) { _, newlyAligned in
                if newlyAligned && !wasAligned {
                    triggerHaptic()
                }
                wasAligned = newlyAligned
            }
            .sheet(isPresented: $showingCitySheet) {
                CityPickerSheet(
                    selectedCity: $selectedCity,
                    useLiveGPS: $useLiveGPS,
                    compassManager: compassManager
                )
                .presentationDetents([.medium, .large])
            }
            .onAppear {
                compassManager.startUpdating()
            }
            .onDisappear {
                compassManager.stopUpdating()
            }
        }
    }

    // MARK: - Mode Switcher Pill (Prayers, Hijri Calendar, Qibla Compass)
    private var modeSwitcherPill: some View {
        HStack(spacing: 3) {
            modePillButton(mode: .prayers, title: "Prayers", icon: "clock.badge.checkmark.fill")
            modePillButton(mode: .calendar, title: "Calendar", icon: "moon.stars.fill")
            modePillButton(mode: .compass, title: "Compass", icon: "safari.fill")
        }
        .padding(3)
        .background(themeManager.currentTheme.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(themeManager.currentTheme.isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08), lineWidth: 1))
    }

    private func modePillButton(mode: QiblaTabMode, title: String, icon: String) -> some View {
        let isSelected = selectedMode == mode
        return Button {
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedMode = mode
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? themeManager.currentTheme.prayerActiveAccent : Color.clear)
            .foregroundColor(isSelected ? (themeManager.currentTheme.isDark ? BayanTheme.obsidian : .white) : (themeManager.currentTheme.isDark ? .white.opacity(0.7) : Color(red: 0.35, green: 0.40, blue: 0.48)))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Compass Content View
    private var compassScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Title
                        VStack(spacing: 4) {
                            Text("اتِّجَاهُ الْقِبْلَةِ")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, BayanTheme.goldSoft],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            Text("QIBLA COMPASS & PRAYER DIRECTION")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(2.5)
                                .foregroundColor(BayanTheme.gold.opacity(0.85))
                        }
                        .padding(.top, 10)

                        // Location Bar
                        Button {
                            showingCitySheet = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(BayanTheme.gold)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(displayLocationName)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.white)

                                    Text("\(String(format: "%.2f", abs(activeLatitude)))°\(activeLatitude >= 0 ? "N" : "S"), \(String(format: "%.2f", abs(activeLongitude)))°\(activeLongitude >= 0 ? "E" : "W") • Qibla: \(Int(qiblaBearing))°")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.65))
                                }

                                Spacer()

                                Text("Change")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(BayanTheme.gold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(BayanTheme.gold.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .liquidGlass(cornerRadius: 18)
                        }
                        .padding(.horizontal)

                        // Alignment Status Pill
                        HStack(spacing: 8) {
                            Image(systemName: isAligned ? "checkmark.seal.fill" : "location.north.circle")
                                .font(.subheadline)
                                .foregroundColor(isAligned ? BayanTheme.gold : .white.opacity(0.6))

                            Text(isAligned ? "ALIGNED WITH KAABA (مُحَاذٍ لِلْقِبْلَةِ)" : alignmentInstruction)
                                .font(.caption.weight(.bold))
                                .foregroundColor(isAligned ? BayanTheme.goldSoft : .white.opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            isAligned ?
                                BayanTheme.gold.opacity(0.18) :
                                Color.white.opacity(0.06)
                        )
                        .overlay(
                            Capsule().stroke(
                                isAligned ? BayanTheme.gold.opacity(0.5) : Color.white.opacity(0.12),
                                lineWidth: 1
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: isAligned ? BayanTheme.gold.opacity(0.3) : .clear, radius: 10)

                        // 3D Liquid Glass Compass Dial
                        ZStack {
                            // Outer Glow Ring
                            Circle()
                                .stroke(
                                    isAligned ? BayanTheme.gold.opacity(0.4) : Color.white.opacity(0.1),
                                    lineWidth: 2
                                )
                                .frame(width: 280, height: 280)
                                .shadow(color: isAligned ? BayanTheme.gold.opacity(0.4) : Color.clear, radius: 16)

                            // Rotating Compass Rose (rotates opposite to heading)
                            ZStack {
                                // Background Glass
                                Circle()
                                    .fill(BayanTheme.obsidian.opacity(0.75))
                                    .frame(width: 270, height: 270)
                                    .liquidGlass(cornerRadius: 135, isGoldBorder: isAligned)

                                // Degree Ticks (0..360 every 30 deg)
                                ForEach(0..<12) { i in
                                    let angle = Double(i * 30)
                                    VStack {
                                        Rectangle()
                                            .fill(i % 3 == 0 ? BayanTheme.goldSoft : Color.white.opacity(0.3))
                                            .frame(width: i % 3 == 0 ? 2.5 : 1.5, height: i % 3 == 0 ? 12 : 7)
                                        Spacer()
                                    }
                                    .frame(width: 260, height: 260)
                                    .rotationEffect(.degrees(angle))
                                }

                                // Cardinal Directions
                                Text("N")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(BayanTheme.gold)
                                    .offset(y: -108)

                                Text("S")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .offset(y: 108)

                                Text("E")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .offset(x: 108)

                                Text("W")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .offset(x: -108)

                                // Kaaba Target Marker (at exact Qibla bearing on the rose)
                                VStack(spacing: 2) {
                                    Text("🕋")
                                        .font(.system(size: 20))
                                        .shadow(color: BayanTheme.gold, radius: 6)
                                    Rectangle()
                                        .fill(BayanTheme.gold)
                                        .frame(width: 2, height: 16)
                                    Spacer()
                                }
                                .frame(width: 270, height: 270)
                                .rotationEffect(.degrees(qiblaBearing))
                            }
                            .rotationEffect(.degrees(-activeHeading))
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: activeHeading)

                            // Task 3: Directional Pointer Arrows
                            // North Arrow (Gold) wrapped in VStack with Spacer below it, framed exactly 280x280
                            VStack(spacing: 0) {
                                CompassArrowShape()
                                    .fill(
                                        LinearGradient(
                                            colors: [BayanTheme.gold, BayanTheme.goldSoft],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 18, height: 55)
                                    .padding(.top, 28)
                                Spacer()
                            }
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(0))

                            // South Arrow (Silver/Muted) wrapped in VStack with Spacer below it, framed exactly 280x280, rotated 180°
                            VStack(spacing: 0) {
                                CompassArrowShape()
                                    .fill(Color.white.opacity(0.35))
                                    .frame(width: 18, height: 55)
                                    .padding(.top, 28)
                                Spacer()
                            }
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(180))

                            // Center Pivot Jewel
                            Circle()
                                .fill(BayanTheme.obsidian)
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(BayanTheme.gold, lineWidth: 2))
                                .shadow(color: .black, radius: 4)

                            Circle()
                                .fill(BayanTheme.gold)
                                .frame(width: 10, height: 10)
                        }
                        .frame(width: 280, height: 280)
                        .padding(.vertical, 10)

                        // Qibla Info Readout Cards
                        HStack(spacing: 12) {
                            StatBox(
                                label: "QIBLA BEARING",
                                value: "\(Int(qiblaBearing))°",
                                subtext: "From True North",
                                isHighlight: true
                            )

                            StatBox(
                                label: "YOUR HEADING",
                                value: "\(Int(activeHeading))°",
                                subtext: cardinalHeading(activeHeading),
                                isHighlight: false
                            )

                            StatBox(
                                label: "DISTANCE",
                                value: "\(distanceToKaaba)",
                                subtext: "Kilometers",
                                isHighlight: false
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 110) // Clearance for floating liquid glass bar
                    }
                    .padding(.top, 8)
                }
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 120) }
    }

    private var alignmentInstruction: String {
        let diff = headingDifference
        if abs(diff) <= 3 {
            return "Facing Kaaba"
        } else if diff > 0 {
            return "Turn \(Int(abs(diff)))° Right"
        } else {
            return "Turn \(Int(abs(diff)))° Left"
        }
    }

    private func cardinalHeading(_ deg: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((deg + 22.5) / 45.0) % 8
        return directions[index]
    }

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        #endif
    }

    // Great-Circle initial bearing from (lat, lng) to Kaaba (21.422487, 39.826206)
    private func calculateQiblaBearing(lat: Double, lng: Double) -> Double {
        let kaabaLat = 21.422487 * .pi / 180
        let kaabaLng = 39.826206 * .pi / 180
        let userLat = lat * .pi / 180
        let userLng = lng * .pi / 180
        let deltaLng = kaabaLng - userLng

        let y = sin(deltaLng) * cos(kaabaLat)
        let x = cos(userLat) * sin(kaabaLat) - sin(userLat) * cos(kaabaLat) * cos(deltaLng)

        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    // Haversine distance in km
    private func calculateDistance(lat: Double, lng: Double) -> Int {
        let r = 6371.0
        let kaabaLat = 21.422487 * .pi / 180
        let kaabaLng = 39.826206 * .pi / 180
        let userLat = lat * .pi / 180
        let userLng = lng * .pi / 180

        let dLat = kaabaLat - userLat
        let dLng = kaabaLng - userLng

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(userLat) * cos(kaabaLat) *
                sin(dLng / 2) * sin(dLng / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return Int(r * c)
    }

    // MARK: - Task 6: Moroccan Ministry of Habous Prayer Times Calculation
    private func calculatePrayerTimes(lat: Double, lng: Double) -> [PrayerTimeItem] {
        let now = Date()
        let calendar = Calendar.current
        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: now) ?? 1)
        let tzOffset = Double(TimeZone.current.secondsFromGMT(for: now)) / 3600.0

        let gamma = 2.0 * .pi / 365.25 * (dayOfYear - 1.0)
        let eqtime = 229.18 * (0.000075 + 0.001868 * cos(gamma) - 0.032077 * sin(gamma) - 0.014615 * cos(2.0 * gamma) - 0.040849 * sin(2.0 * gamma))
        let decl = 0.006918 - 0.399912 * cos(gamma) + 0.070257 * sin(gamma) - 0.006758 * cos(2.0 * gamma) + 0.000907 * sin(2.0 * gamma)

        let solarNoon = (720.0 - 4.0 * lng - eqtime) / 60.0 + tzOffset

        func hourAngle(alphaDeg: Double) -> Double {
            let latRad = lat * .pi / 180.0
            let alphaRad = alphaDeg * .pi / 180.0
            let cosH = (sin(alphaRad) - sin(latRad) * sin(decl)) / (cos(latRad) * cos(decl))
            let clamped = max(-1.0, min(1.0, cosH))
            return acos(clamped) * 180.0 / .pi
        }

        // Moroccan Habous conventions: Fajr 19.0°, Isha 17.0°
        let haFajr = hourAngle(alphaDeg: -19.0)
        let haSunset = hourAngle(alphaDeg: -0.833)

        // Asr: Maliki shadow = 1
        let latRad = lat * .pi / 180.0
        let asrAltRad = atan(1.0 / (1.0 + tan(abs(latRad - decl))))
        let cosAsr = (sin(asrAltRad) - sin(latRad) * sin(decl)) / (cos(latRad) * cos(decl))
        let haAsr = acos(max(-1.0, min(1.0, cosAsr))) * 180.0 / .pi

        let haIsha = hourAngle(alphaDeg: -17.0)

        let fajrHour = (solarNoon - haFajr / 15.0).truncatingRemainder(dividingBy: 24.0)
        let dhuhrHour = (solarNoon + 5.0 / 60.0).truncatingRemainder(dividingBy: 24.0)
        let asrHour = (solarNoon + haAsr / 15.0).truncatingRemainder(dividingBy: 24.0)
        let maghribHour = (solarNoon + haSunset / 15.0 + 2.0 / 60.0).truncatingRemainder(dividingBy: 24.0)
        let ishaHour = (solarNoon + haIsha / 15.0).truncatingRemainder(dividingBy: 24.0)

        func prayerComponents(hourVal: Double) -> (String, Int, Int) {
            let positive = (hourVal + 24.0).truncatingRemainder(dividingBy: 24.0)
            let h = Int(positive)
            let m = Int((positive - Double(h)) * 60.0)
            return (String(format: "%02d:%02d", h, m), h, m)
        }

        let currentDecimalHour = Double(calendar.component(.hour, from: now)) + Double(calendar.component(.minute, from: now)) / 60.0

        let fajr = prayerComponents(hourVal: fajrHour)
        let dhuhr = prayerComponents(hourVal: dhuhrHour)
        let asr = prayerComponents(hourVal: asrHour)
        let maghrib = prayerComponents(hourVal: maghribHour)
        let isha = prayerComponents(hourVal: ishaHour)

        let times = [
            ("fajr", "الفجر", "Fajr", fajr.0, fajr.1, fajr.2, (fajrHour + 24.0).truncatingRemainder(dividingBy: 24.0), "sun.horizon.fill"),
            ("dhuhr", "الظهر", "Dhuhr", dhuhr.0, dhuhr.1, dhuhr.2, (dhuhrHour + 24.0).truncatingRemainder(dividingBy: 24.0), "sun.max.fill"),
            ("asr", "العصر", "Asr", asr.0, asr.1, asr.2, (asrHour + 24.0).truncatingRemainder(dividingBy: 24.0), "sun.haze.fill"),
            ("maghrib", "المغرب", "Maghrib", maghrib.0, maghrib.1, maghrib.2, (maghribHour + 24.0).truncatingRemainder(dividingBy: 24.0), "sunset.fill"),
            ("isha", "العشاء", "Isha", isha.0, isha.1, isha.2, (ishaHour + 24.0).truncatingRemainder(dividingBy: 24.0), "moon.stars.fill")
        ]

        var nextFound = false
        var result: [PrayerTimeItem] = []

        for item in times {
            let isNext = !nextFound && item.6 > currentDecimalHour
            if isNext { nextFound = true }
            result.append(PrayerTimeItem(
                id: item.0,
                nameArabic: item.1,
                nameEnglish: item.2,
                timeString: item.3,
                hour: item.4,
                minute: item.5,
                icon: item.7,
                isNext: isNext
            ))
        }

        if !nextFound && !result.isEmpty {
            let first = result[0]
            result[0] = PrayerTimeItem(
                id: first.id,
                nameArabic: first.nameArabic,
                nameEnglish: first.nameEnglish,
                timeString: first.timeString,
                hour: first.hour,
                minute: first.minute,
                icon: first.icon,
                isNext: true
            )
        }

        return result
    }
}

// MARK: - Task 3: Compass Arrow Shape
struct CompassArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 12))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct PrayerTimeCard: View {
    let prayer: PrayerTimeItem

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: prayer.icon)
                    .font(.system(size: 11))
                    .foregroundColor(prayer.isNext ? BayanTheme.gold : .white.opacity(0.6))
                Text(prayer.nameEnglish.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(prayer.isNext ? BayanTheme.gold : .white.opacity(0.6))
                    .tracking(0.5)
            }

            Text(prayer.nameArabic)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(prayer.isNext ? BayanTheme.goldSoft : .white)

            Text(prayer.timeString)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(prayer.isNext ? BayanTheme.gold : .white.opacity(0.95))

            if prayer.isNext {
                Text("NEXT")
                    .font(.system(size: 8, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BayanTheme.gold)
                    .foregroundColor(BayanTheme.obsidian)
                    .clipShape(Capsule())
            }
        }
        .frame(width: 88, height: 86)
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .liquidGlass(cornerRadius: 16, isGoldBorder: prayer.isNext)
    }
}

// MARK: - Stat Box
private struct StatBox: View {
    let label: String
    let value: String
    let subtext: String
    var isHighlight: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8.5, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.5)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isHighlight ? BayanTheme.goldSoft : .white)

            Text(subtext)
                .font(.system(size: 9.5))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 16, isGoldBorder: isHighlight)
    }
}

// MARK: - City Model & Picker
public struct QiblaCity: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let country: String
    public let latitude: Double
    public let longitude: Double

    public static let defaultCity = QiblaCity(name: "Casablanca", country: "Morocco", latitude: 33.5731, longitude: -7.5898)

    public static let standardCities: [QiblaCity] = [
        QiblaCity(name: "Makkah (Holy Kaaba)", country: "Saudi Arabia", latitude: 21.4225, longitude: 39.8262),
        QiblaCity(name: "Madinah", country: "Saudi Arabia", latitude: 24.5247, longitude: 39.5692),
        QiblaCity(name: "Riyadh", country: "Saudi Arabia", latitude: 24.7136, longitude: 46.6753),
        QiblaCity(name: "Cairo", country: "Egypt", latitude: 30.0444, longitude: 31.2357),
        QiblaCity(name: "Dubai", country: "UAE", latitude: 25.2048, longitude: 55.2708),
        QiblaCity(name: "Casablanca", country: "Morocco", latitude: 33.5731, longitude: -7.5898),
        QiblaCity(name: "Rabat", country: "Morocco", latitude: 34.0209, longitude: -6.8416),
        QiblaCity(name: "Algiers", country: "Algeria", latitude: 36.7538, longitude: 3.0588),
        QiblaCity(name: "Tunis", country: "Tunisia", latitude: 36.8065, longitude: 10.1815),
        QiblaCity(name: "Istanbul", country: "Turkey", latitude: 41.0082, longitude: 28.9784),
        QiblaCity(name: "London", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278),
        QiblaCity(name: "Paris", country: "France", latitude: 48.8566, longitude: 2.3522),
        QiblaCity(name: "New York", country: "United States", latitude: 40.7128, longitude: -74.0060),
        QiblaCity(name: "Toronto", country: "Canada", latitude: 43.6532, longitude: -79.3832),
        QiblaCity(name: "Jakarta", country: "Indonesia", latitude: -6.2088, longitude: 106.8456),
        QiblaCity(name: "Kuala Lumpur", country: "Malaysia", latitude: 3.1390, longitude: 101.6869)
    ]
}

// City Picker Sheet
private struct CityPickerSheet: View {
    @Binding var selectedCity: QiblaCity
    @Binding var useLiveGPS: Bool
    @ObservedObject var compassManager: CompassHeadingManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BayanTheme.obsidian.ignoresSafeArea()

                List {
                    // Current GPS Option
                    Section {
                        Button {
                            useLiveGPS = true
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(BayanTheme.gold)
                                    .font(.headline)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(compassManager.userCityName ?? "Current Location (GPS)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    if let coord = compassManager.userCoordinate {
                                        Text("\(String(format: "%.2f", abs(coord.latitude)))°\(coord.latitude >= 0 ? "N" : "S"), \(String(format: "%.2f", abs(coord.longitude)))°\(coord.longitude >= 0 ? "E" : "W")")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    } else {
                                        Text("Detecting live coordinates via GPS...")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }

                                Spacer()

                                if useLiveGPS {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(BayanTheme.gold)
                                        .font(.headline)
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.04))
                    } header: {
                        Text("Live Detection")
                            .foregroundColor(BayanTheme.goldSoft)
                            .font(.caption.weight(.bold))
                    }

                    // Standard Preset Cities
                    Section {
                        ForEach(QiblaCity.standardCities) { city in
                            Button {
                                useLiveGPS = false
                                selectedCity = city
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(city.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(city.country)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }

                                    Spacer()

                                    if !useLiveGPS && city == selectedCity {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(BayanTheme.gold)
                                            .font(.headline)
                                    }
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.04))
                        }
                    } header: {
                        Text("Preset Cities")
                            .foregroundColor(BayanTheme.goldSoft)
                            .font(.caption.weight(.bold))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(BayanTheme.gold)
                }
            }
        }
    }
}

// MARK: - CoreLocation Compass Heading & Location Manager
public class CompassHeadingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published public var heading: Double = 0.0
    @Published public var userCoordinate: CLLocationCoordinate2D?
    @Published public var userCityName: String?
    private var locationManager: CLLocationManager?
    private let geocoder = CLGeocoder()

    public override init() {
        super.init()
        #if os(iOS)
        let manager = CLLocationManager()
        self.locationManager = manager
        manager.delegate = self
        manager.headingFilter = 1.0
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.requestWhenInUseAuthorization()
        #endif
    }

    #if os(iOS)
    public func startUpdating() {
        if CLLocationManager.headingAvailable() {
            locationManager?.startUpdatingHeading()
        }
        if userCoordinate == nil {
            locationManager?.startUpdatingLocation()
        }
    }

    public func stopUpdating() {
        locationManager?.stopUpdatingHeading()
        locationManager?.stopUpdatingLocation()
    }

    public func refreshLocation() {
        locationManager?.startUpdatingLocation()
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            if CLLocationManager.headingAvailable() {
                manager.startUpdatingHeading()
            }
            if userCoordinate == nil {
                manager.startUpdatingLocation()
            }
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let val = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        DispatchQueue.main.async {
            self.heading = val
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userCoordinate = location.coordinate
        }

        // Once valid coordinates are captured, pause GPS tracking to save battery
        manager.stopUpdatingLocation()

        let defaults = UserDefaults(suiteName: "group.tools.rea.Bayan") ?? UserDefaults.standard
        defaults.set(location.coordinate.latitude, forKey: "bayan_last_latitude")
        defaults.set(location.coordinate.longitude, forKey: "bayan_last_longitude")

        if userCityName == nil {
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
                if let place = placemarks?.first {
                    let city = place.locality ?? place.administrativeArea ?? place.name ?? "Current Location"
                    let country = place.country ?? ""
                    let fullCity = country.isEmpty ? city : "\(city), \(country)"
                    DispatchQueue.main.async {
                        self?.userCityName = fullCity
                    }
                    defaults.set(city, forKey: "bayan_last_city_name")
                }
            }
        }
    }
    #endif
}
