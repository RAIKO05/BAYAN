import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline Entry & Provider
public struct IdentifyWidgetEntry: TimelineEntry {
    public let date: Date

    public static let placeholder = IdentifyWidgetEntry(date: Date())
}

public struct IdentifyWidgetTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> IdentifyWidgetEntry {
        .placeholder
    }

    public func getSnapshot(in context: Context, completion: @escaping (IdentifyWidgetEntry) -> Void) {
        completion(.placeholder)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<IdentifyWidgetEntry>) -> Void) {
        let entry = IdentifyWidgetEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
public struct BayanIdentifyWidgetView: View {
    var entry: IdentifyWidgetEntry
    @Environment(\.widgetFamily) var family

    private let goldPrimary = Color(red: 0.95, green: 0.80, blue: 0.40)
    private let emeraldGreen = Color(red: 0.18, green: 0.85, blue: 0.50)
    private let bgObsidian = Color(red: 0.05, green: 0.07, blue: 0.10)

    public var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .accessoryCircular:
                lockScreenCircular
            case .accessoryInline:
                lockScreenInline
            default:
                smallView
            }
        }
        .widgetURL(URL(string: "bayan://identify"))
    }

    // Small Home Screen Widget
    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("QUICK IDENTIFY")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.0)
                    .foregroundColor(goldPrimary)
                Spacer()
                Image(systemName: "waveform")
                    .font(.system(size: 11))
                    .foregroundColor(emeraldGreen)
            }

            Spacer()

            // Concentric Radar Rings & Center Mic Orb
            ZStack {
                // Outermost ring
                Circle()
                    .stroke(goldPrimary.opacity(0.18), lineWidth: 1)
                    .frame(width: 66, height: 66)

                // Middle ring
                Circle()
                    .stroke(emeraldGreen.opacity(0.35), lineWidth: 1.5)
                    .frame(width: 50, height: 50)

                // Center glowing button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.22, blue: 0.18),
                                Color(red: 0.06, green: 0.10, blue: 0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().stroke(goldPrimary.opacity(0.65), lineWidth: 1)
                    )

                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(goldPrimary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Tap to Listen")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Text("Recognize Any Ayah")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.60))
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            bgObsidian
        }
    }

    // Lock Screen Circular
    private var lockScreenCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Bayan")
                    .font(.system(size: 9, weight: .heavy))
            }
        }
    }

    // Lock Screen Inline
    private var lockScreenInline: some View {
        Label("Identify Quran Recitation", systemImage: "waveform.circle.fill")
    }
}

// MARK: - Widget Configuration
public struct BayanIdentifyWidget: Widget {
    public static let kind: String = "com.bayan.app.widget.identify"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: IdentifyWidgetTimelineProvider()) { entry in
            BayanIdentifyWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Quran Identify")
        .description("Instantly launch Quran audio identification with one tap.")
        .supportedFamilies([
            .systemSmall,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}
