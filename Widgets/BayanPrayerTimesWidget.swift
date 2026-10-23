import WidgetKit
import SwiftUI

// MARK: - Prayer Times Widget Entry
public struct PrayerWidgetEntry: TimelineEntry {
    public let date: Date
    public let currentPrayerName: String
    public let currentPrayerEmoji: String
    public let currentPrayerTime: String
    public let nextPrayerName: String
    public let nextPrayerTime: String
    public let countdownText: String
    public let completedCount: Int
    public let prayers: [(name: String, time: String, isDone: Bool)]

    public static let placeholder = PrayerWidgetEntry(
        date: Date(),
        currentPrayerName: "Dzuhur",
        currentPrayerEmoji: "☀️",
        currentPrayerTime: "12.13",
        nextPrayerName: "Ashar",
        nextPrayerTime: "15.15",
        countdownText: "in 1h 44m",
        completedCount: 2,
        prayers: [
            ("Subuh", "05.04", true),
            ("Dzuhur", "12.13", true),
            ("Ashar", "15.15", false),
            ("Maghrib", "17.43", false),
            ("Isya", "19.02", false)
        ]
    )
}

// MARK: - Timeline Provider for Prayers Widget
public struct PrayerTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> PrayerWidgetEntry {
        .placeholder
    }

    public func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(calculateEntry(for: Date()))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date()
        let currentEntry = calculateEntry(for: now)

        // Refresh timeline every 15 minutes or at next prayer time
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? now.addingTimeInterval(900)
        let timeline = Timeline(entries: [currentEntry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func calculateEntry(for date: Date) -> PrayerWidgetEntry {
        let calendar = Calendar.current
        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let tzOffset = Double(TimeZone.current.secondsFromGMT(for: date)) / 3600.0

        let lat = 33.5731 // Default latitude (Casablanca)
        let lng = -7.5898 // Default longitude

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

        let haFajr = hourAngle(alphaDeg: -19.0)
        let haSunset = hourAngle(alphaDeg: -0.833)

        let latRad = lat * .pi / 180.0
        let asrAltRad = atan(1.0 / (1.0 + tan(abs(latRad - decl))))
        let cosAsr = (sin(asrAltRad) - sin(latRad) * sin(decl)) / (cos(latRad) * cos(decl))
        let haAsr = acos(max(-1.0, min(1.0, cosAsr))) * 180.0 / .pi

        let haIsha = hourAngle(alphaDeg: -17.0)

        func fmt(hourVal: Double) -> (String, Double) {
            let positive = (hourVal + 24.0).truncatingRemainder(dividingBy: 24.0)
            let h = Int(positive)
            let m = Int((positive - Double(h)) * 60.0)
            return (String(format: "%02d.%02d", h, m), positive)
        }

        let fajr = fmt(hourVal: solarNoon - haFajr / 15.0)
        let dhuhr = fmt(hourVal: solarNoon + 5.0 / 60.0)
        let asr = fmt(hourVal: solarNoon + haAsr / 15.0)
        let maghrib = fmt(hourVal: solarNoon + haSunset / 15.0 + 2.0 / 60.0)
        let isha = fmt(hourVal: solarNoon + haIsha / 15.0)

        let prayerList = [
            ("Subuh", "✨", fajr.0, fajr.1),
            ("Dzuhur", "☀️", dhuhr.0, dhuhr.1),
            ("Ashar", "⛅", asr.0, asr.1),
            ("Maghrib", "🌅", maghrib.0, maghrib.1),
            ("Isya", "🌙", isha.0, isha.1)
        ]

        let curHour = Double(calendar.component(.hour, from: date)) + Double(calendar.component(.minute, from: date)) / 60.0

        var curIdx = 0
        var nxtIdx = 0

        if curHour < fajr.1 {
            curIdx = 4
            nxtIdx = 0
        } else if curHour < dhuhr.1 {
            curIdx = 0
            nxtIdx = 1
        } else if curHour < asr.1 {
            curIdx = 1
            nxtIdx = 2
        } else if curHour < maghrib.1 {
            curIdx = 2
            nxtIdx = 3
        } else if curHour < isha.1 {
            curIdx = 3
            nxtIdx = 4
        } else {
            curIdx = 4
            nxtIdx = 0
        }

        let nextItem = prayerList[nxtIdx]
        var diffHours = nextItem.3 - curHour
        if diffHours < 0 { diffHours += 24.0 }
        let diffH = Int(diffHours)
        let diffM = Int((diffHours - Double(diffH)) * 60.0)
        let countdown = diffH > 0 ? "in \(diffH)h \(diffM)m" : "in \(diffM)m"

        return PrayerWidgetEntry(
            date: date,
            currentPrayerName: prayerList[curIdx].0,
            currentPrayerEmoji: prayerList[curIdx].1,
            currentPrayerTime: prayerList[curIdx].2,
            nextPrayerName: nextItem.0,
            nextPrayerTime: nextItem.2,
            countdownText: countdown,
            completedCount: curIdx + 1,
            prayers: prayerList.map { ($0.0, $0.2, false) }
        )
    }
}

// MARK: - Widget View
public struct BayanPrayerTimesWidgetView: View {
    var entry: PrayerWidgetEntry
    @Environment(\.widgetFamily) var family

    public var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        case .accessoryRectangular:
            lockScreenRectangular
        case .accessoryCircular:
            lockScreenCircular
        case .accessoryInline:
            lockScreenInline
        default:
            smallWidget
        }
    }

    // Home Screen Small
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Now")
                    .font(.system(size: 9.5, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color(red: 0.95, green: 0.78, blue: 0.35).opacity(0.2))
                    .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))
                    .clipShape(Capsule())

                Spacer()

                Text("🕌 Bayan")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(entry.currentPrayerName)
                        .font(.system(size: 14.5, weight: .bold))
                    Text(entry.currentPrayerEmoji)
                        .font(.system(size: 13))
                }

                Text(entry.currentPrayerTime)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }

            Spacer(minLength: 0)

            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Next: \(entry.nextPrayerName)")
                        .font(.system(size: 10.5, weight: .semibold))
                    Text("\(entry.nextPrayerTime) • \(entry.countdownText)")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color(red: 0.05, green: 0.08, blue: 0.16)
        }
    }

    // Home Screen Medium
    private var mediumWidget: some View {
        HStack(spacing: 14) {
            // Left Hero Column
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Now")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.95, green: 0.78, blue: 0.35).opacity(0.2))
                        .foregroundColor(Color(red: 0.95, green: 0.78, blue: 0.35))
                        .clipShape(Capsule())

                    Spacer()
                }

                HStack(spacing: 4) {
                    Text(entry.currentPrayerName)
                        .font(.system(size: 16, weight: .bold))
                    Text(entry.currentPrayerEmoji)
                        .font(.system(size: 15))
                }

                Text(entry.currentPrayerTime)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Next: \(entry.nextPrayerName) \(entry.countdownText)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .overlay(Color.white.opacity(0.12))

            // Right Prayers List Column
            VStack(spacing: 5) {
                ForEach(entry.prayers, id: \.name) { p in
                    let isCurrent = p.name == entry.currentPrayerName
                    let isNext = p.name == entry.nextPrayerName

                    HStack {
                        Circle()
                            .fill(isCurrent ? Color(red: 0.95, green: 0.78, blue: 0.35) : Color.white.opacity(0.2))
                            .frame(width: 6, height: 6)

                        Text(p.name)
                            .font(.system(size: 11, weight: isCurrent || isNext ? .bold : .regular))
                            .foregroundColor(isCurrent ? Color(red: 0.95, green: 0.78, blue: 0.35) : .primary)

                        Spacer()

                        Text(p.time)
                            .font(.system(size: 11, weight: isCurrent ? .bold : .regular, design: .rounded))
                            .foregroundColor(isCurrent ? Color(red: 0.95, green: 0.78, blue: 0.35) : .secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(red: 0.05, green: 0.08, blue: 0.16)
        }
    }

    // Lock Screen Rectangular
    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 10))
                Text("Bayan Prayers")
                    .font(.system(size: 11, weight: .bold))
            }

            HStack {
                Text(entry.nextPrayerName)
                    .font(.system(size: 14, weight: .bold))
                Text(entry.nextPrayerTime)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                Text(entry.countdownText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Text("Current: \(entry.currentPrayerName) (\(entry.currentPrayerTime))")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    // Lock Screen Circular
    private var lockScreenCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11, weight: .bold))
                Text(entry.nextPrayerName.prefix(3).uppercased())
                    .font(.system(size: 10, weight: .bold))
                Text(entry.nextPrayerTime)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
            }
        }
    }

    // Lock Screen Inline
    private var lockScreenInline: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
            Text("\(entry.nextPrayerName) \(entry.nextPrayerTime) (\(entry.countdownText))")
        }
    }
}

// MARK: - Widget Definition
public struct BayanPrayerTimesWidget: Widget {
    public static let kind: String = "com.bayan.app.widget.prayertimes"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: PrayerTimelineProvider()) { entry in
            BayanPrayerTimesWidgetView(entry: entry)
        }
        .configurationDisplayName("Prayer Times & Countdown")
        .description("Track the daily 5 prayers and countdown to the next prayer directly from your Lock Screen and Home Screen.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}
