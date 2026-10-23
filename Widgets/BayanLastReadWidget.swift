import WidgetKit
import SwiftUI
import AppIntents

public struct LastReadEntry: TimelineEntry {
    public let date: Date
    public let surahNameArabic: String
    public let surahNameEnglish: String
    public let ayahNumber: Int
    public let pageNumber: Int

    public static let placeholder = LastReadEntry(
        date: Date(),
        surahNameArabic: "الكهف",
        surahNameEnglish: "Al-Kahf",
        ayahNumber: 28,
        pageNumber: 297
    )
}

public struct LastReadTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> LastReadEntry {
        .placeholder
    }

    public func getSnapshot(in context: Context, completion: @escaping (LastReadEntry) -> Void) {
        completion(.placeholder)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<LastReadEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.bayan.app") ?? UserDefaults(suiteName: "group.tools.rea.bayan") ?? UserDefaults.standard
        let surahEnglish = defaults.string(forKey: "widget_last_surah_english") ?? "Al-Kahf"
        let surahArabic = defaults.string(forKey: "widget_last_surah_arabic") ?? "الكهف"
        let ayah = defaults.integer(forKey: "bayan_last_ayah_id") == 0 ? 1 : defaults.integer(forKey: "bayan_last_ayah_id")
        let page = defaults.integer(forKey: "bayan_last_page_number") == 0 ? 293 : defaults.integer(forKey: "bayan_last_page_number")

        let entry = LastReadEntry(
            date: Date(),
            surahNameArabic: surahArabic,
            surahNameEnglish: surahEnglish,
            ayahNumber: ayah,
            pageNumber: page
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct BayanLastReadWidgetView: View {
    var entry: LastReadEntry
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
        default:
            mediumWidget
        }
    }

    // Small Home Screen Widget
    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(Color(red: 0.90, green: 0.74, blue: 0.38))
                Spacer()
                Text("Page \(entry.pageNumber)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Text(entry.surahNameArabic)
                .font(.title2.weight(.bold))
                .foregroundColor(Color(red: 0.96, green: 0.88, blue: 0.65))

            Text(entry.surahNameEnglish)
                .font(.headline)
                .foregroundColor(.white)

            Text("Ayah \(entry.ayahNumber)")
                .font(.caption.weight(.medium))
                .foregroundColor(Color(red: 0.20, green: 0.82, blue: 0.88))
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color(red: 0.04, green: 0.05, blue: 0.07)
        }
    }

    // Medium Home Screen Widget
    private var mediumWidget: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "book.pages.fill")
                        .foregroundColor(Color(red: 0.90, green: 0.74, blue: 0.38))
                    Text("WHERE YOU STOPPED")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundColor(Color(red: 0.20, green: 0.82, blue: 0.88))
                }

                Text("\(entry.surahNameEnglish) • \(entry.surahNameArabic)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)

                Text("Ayah \(entry.ayahNumber) • Page \(entry.pageNumber)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button(intent: ResumeQuranIntent()) {
                VStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 36))
                    Text("Resume")
                        .font(.caption2.weight(.bold))
                }
                .foregroundColor(Color(red: 0.90, green: 0.74, blue: 0.38))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            Color(red: 0.04, green: 0.05, blue: 0.07)
        }
    }

    // Lock Screen Rectangular
    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Last Read", systemImage: "bookmark.fill")
                .font(.caption2)
            Text("\(entry.surahNameEnglish) • Ayah \(entry.ayahNumber)")
                .font(.headline)
            Text("Page \(entry.pageNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // Lock Screen Circular
    private var lockScreenCircular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "book.fill")
                    .font(.caption2)
                Text("\(entry.ayahNumber)")
                    .font(.caption.weight(.bold))
            }
        }
    }
}

// MARK: - Widget Definition
public struct BayanLastReadWidget: Widget {
    public static let kind: String = "com.bayan.app.widget.lastread"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: LastReadTimelineProvider()) { entry in
            BayanLastReadWidgetView(entry: entry)
        }
        .configurationDisplayName("Last Read Position")
        .description("Quickly resume reading the Quran from where you stopped.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular
        ])
    }
}
