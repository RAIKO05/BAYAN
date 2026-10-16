import SwiftUI
import CoreLocation

// MARK: - Qibla Compass View
public struct QiblaView: View {
    @StateObject private var compassManager = CompassHeadingManager()
    @State private var selectedCity: QiblaCity = .defaultCity
    @State private var showingCitySheet = false
    @State private var simulatedHeading: Double = 0
    @State private var isSimulating: Bool = false

    public init() {}

    private var activeHeading: Double {
        isSimulating ? simulatedHeading : compassManager.heading
    }

    private var qiblaBearing: Double {
        calculateQiblaBearing(lat: selectedCity.latitude, lng: selectedCity.longitude)
    }

    private var distanceToKaaba: Int {
        calculateDistance(lat: selectedCity.latitude, lng: selectedCity.longitude)
    }

    private var headingDifference: Double {
        var diff = qiblaBearing - activeHeading
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    private var isAligned: Bool {
        abs(headingDifference) <= 3.0
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                BayanTheme.obsidian.ignoresSafeArea()
                RadialGradient(
                    colors: [
                        isAligned ? BayanTheme.deepEmerald.opacity(0.8) : BayanTheme.deepEmerald.opacity(0.35),
                        BayanTheme.obsidian
                    ],
                    center: .center,
                    startRadius: 40,
                    endRadius: 450
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: isAligned)

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
                                    Text(selectedCity.name)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.white)

                                    Text("\(String(format: "%.2f", abs(selectedCity.latitude)))°\(selectedCity.latitude >= 0 ? "N" : "S"), \(String(format: "%.2f", abs(selectedCity.longitude)))°\(selectedCity.longitude >= 0 ? "E" : "W") • Qibla: \(Int(qiblaBearing))°")
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

                            // Fixed Center Needle Pointer (pointing top toward target)
                            ZStack {
                                // Needle North (Gold)
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: -70))
                                    path.addLine(to: CGPoint(x: 9, y: 0))
                                    path.addLine(to: CGPoint(x: -9, y: 0))
                                    path.closeSubpath()
                                }
                                .fill(
                                    LinearGradient(
                                        colors: [BayanTheme.gold, BayanTheme.goldSoft],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .offset(y: -35)

                                // Needle South (Silver/Muted)
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 70))
                                    path.addLine(to: CGPoint(x: 9, y: 0))
                                    path.addLine(to: CGPoint(x: -9, y: 0))
                                    path.closeSubpath()
                                }
                                .fill(Color.white.opacity(0.35))
                                .offset(y: 35)

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

                        // Manual Compass Simulation Slider (for simulator / testing without gyroscope)
                        VStack(spacing: 8) {
                            HStack {
                                Text("COMPASS HEADING SIMULATION")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(1)

                                Spacer()

                                Button("Snap to Kaaba") {
                                    isSimulating = true
                                    simulatedHeading = qiblaBearing
                                    triggerHaptic()
                                }
                                .font(.caption2.weight(.bold))
                                .foregroundColor(BayanTheme.gold)
                            }

                            Slider(value: $simulatedHeading, in: 0...359, step: 1) { _ in
                                isSimulating = true
                                if isAligned { triggerHaptic() }
                            }
                            .tint(BayanTheme.gold)
                        }
                        .padding(14)
                        .liquidGlass(cornerRadius: 18)
                        .padding(.horizontal)
                        .padding(.bottom, 110) // Clearance for floating liquid glass bar
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Qibla")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCitySheet) {
                CityPickerSheet(selectedCity: $selectedCity)
                    .presentationDetents([.medium, .large])
            }
        }
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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                BayanTheme.obsidian.ignoresSafeArea()

                List(QiblaCity.standardCities) { city in
                    Button {
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

                            if city == selectedCity {
                                Image(systemName: "checkmark")
                                    .foregroundColor(BayanTheme.gold)
                                    .font(.headline)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.04))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select City")
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

// MARK: - CoreLocation Compass Heading Manager
public class CompassHeadingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published public var heading: Double = 0.0
    private var locationManager: CLLocationManager?

    public override init() {
        super.init()
        #if os(iOS)
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.headingFilter = 1.0
        if CLLocationManager.headingAvailable() {
            locationManager?.startUpdatingHeading()
        }
        #endif
    }

    #if os(iOS)
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let val = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        DispatchQueue.main.async {
            self.heading = val
        }
    }
    #endif
}
