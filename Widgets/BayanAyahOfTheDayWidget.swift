import WidgetKit
import SwiftUI

// MARK: - Curated Daily Quranic Inspiration Model
public struct DailyAyahData {
    public let surahId: Int
    public let ayahNumber: Int
    public let surahNameArabic: String
    public let surahNameEnglish: String
    public let arabicText: String
    public let translationText: String

    public static let curatedCatalog: [DailyAyahData] = [
        DailyAyahData(
            surahId: 2,
            ayahNumber: 255,
            surahNameArabic: "البقرة",
            surahNameEnglish: "Al-Baqarah",
            arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ",
            translationText: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep."
        ),
        DailyAyahData(
            surahId: 94,
            ayahNumber: 5,
            surahNameArabic: "الشرح",
            surahNameEnglish: "Ash-Sharh",
            arabicText: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا • إِنَّ مَعَ الْعُسْرِ يُسْرًا",
            translationText: "For indeed, with hardship [will be] ease. Indeed, with hardship [will be] ease."
        ),
        DailyAyahData(
            surahId: 2,
            ayahNumber: 286,
            surahNameArabic: "البقرة",
            surahNameEnglish: "Al-Baqarah",
            arabicText: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
            translationText: "Allah does not burden a soul beyond that it can bear."
        ),
        DailyAyahData(
            surahId: 39,
            ayahNumber: 53,
            surahNameArabic: "الزمر",
            surahNameEnglish: "Az-Zumar",
            arabicText: "قُلْ يَا عِبَادِيَ الَّذِينَ أَسْرَفُوا عَلَىٰ أَنْفُسِهِمْ لَا تَقْنَطُوا مِنْ رَحْمَةِ اللَّهِ",
            translationText: "Say, 'O My servants who have transgressed against themselves, do not despair of the mercy of Allah.'"
        ),
        DailyAyahData(
            surahId: 55,
            ayahNumber: 13,
            surahNameArabic: "الرحمن",
            surahNameEnglish: "Ar-Rahman",
            arabicText: "فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ",
            translationText: "So which of the favors of your Lord would you deny?"
        ),
        DailyAyahData(
            surahId: 2,
            ayahNumber: 152,
            surahNameArabic: "البقرة",
            surahNameEnglish: "Al-Baqarah",
            arabicText: "فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ",
            translationText: "So remember Me; I will remember you. And be grateful to Me and do not deny Me."
        ),
        DailyAyahData(
            surahId: 3,
            ayahNumber: 139,
            surahNameArabic: "آل عمران",
            surahNameEnglish: "Ali 'Imran",
            arabicText: "وَلَا تَهِنُوا وَلَا تَحْزَنُوا وَأَنْتُمُ الْأَعْلَوْنَ إِنْ كُنْتُمْ مُؤْمِنِينَ",
            translationText: "So do not weaken and do not grieve, and you will be superior if you are [true] believers."
        ),
        DailyAyahData(
            surahId: 14,
            ayahNumber: 7,
            surahNameArabic: "إبراهيم",
            surahNameEnglish: "Ibrahim",
            arabicText: "لَئِنْ شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
            translationText: "If you are grateful, I will surely increase you [in favor]."
        ),
        DailyAyahData(
            surahId: 2,
            ayahNumber: 186,
            surahNameArabic: "البقرة",
            surahNameEnglish: "Al-Baqarah",
            arabicText: "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ",
            translationText: "And when My servants ask you concerning Me, indeed I am near. I respond to the invocation of the supplicant."
        ),
        DailyAyahData(
            surahId: 65,
            ayahNumber: 3,
            surahNameArabic: "الطلاق",
            surahNameEnglish: "At-Talaq",
            arabicText: "وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا • وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ",
            translationText: "And whoever fears Allah - He will make for him a way out, and will provide for him from where he does not expect."
        ),
        DailyAyahData(
            surahId: 18,
            ayahNumber: 10,
            surahNameArabic: "الكهف",
            surahNameEnglish: "Al-Kahf",
            arabicText: "رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَدًا",
            translationText: "Our Lord, grant us from Yourself mercy and prepare for us from our affair right guidance."
        ),
        DailyAyahData(
            surahId: 57,
            ayahNumber: 4,
            surahNameArabic: "الحديد",
            surahNameEnglish: "Al-Hadid",
            arabicText: "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنْتُمْ ۚ وَاللَّهُ بِمَا تَعْمَلُونَ بَصِيرٌ",
            translationText: "And He is with you wherever you are. And Allah, of what you do, is Seeing."
        ),
        DailyAyahData(
            surahId: 50,
            ayahNumber: 16,
            surahNameArabic: "ق",
            surahNameEnglish: "Qaf",
            arabicText: "وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ",
            translationText: "And We are closer to him than [his] jugular vein."
        ),
        DailyAyahData(
            surahId: 93,
            ayahNumber: 3,
            surahNameArabic: "الضحى",
            surahNameEnglish: "Ad-Duha",
            arabicText: "مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ • وَلَلْآخِرَةُ خَيْرٌ لَكَ مِنَ الْأُولَىٰ",
            translationText: "Your Lord has not taken leave of you nor has He detested you. And the Hereafter is better for you than the first [life]."
        ),
        DailyAyahData(
            surahId: 24,
            ayahNumber: 35,
            surahNameArabic: "النور",
            surahNameEnglish: "An-Nur",
            arabicText: "اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ",
            translationText: "Allah is the Light of the heavens and the earth."
        ),
        DailyAyahData(
            surahId: 20,
            ayahNumber: 114,
            surahNameArabic: "طه",
            surahNameEnglish: "Ta-Ha",
            arabicText: "وَقُلْ رَبِّ زِدْنِي عِلْمًا",
            translationText: "And say, 'My Lord, increase me in knowledge.'"
        ),
        DailyAyahData(
            surahId: 17,
            ayahNumber: 82,
            surahNameArabic: "الإسراء",
            surahNameEnglish: "Al-Isra",
            arabicText: "وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِلْمُؤْمِنِينَ",
            translationText: "And We send down of the Qur'an that which is healing and mercy for the believers."
        ),
        DailyAyahData(
            surahId: 67,
            ayahNumber: 1,
            surahNameArabic: "الملك",
            surahNameEnglish: "Al-Mulk",
            arabicText: "تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ",
            translationText: "Blessed is He in whose hand is dominion, and He is over all things competent."
        ),
        DailyAyahData(
            surahId: 2,
            ayahNumber: 45,
            surahNameArabic: "البقرة",
            surahNameEnglish: "Al-Baqarah",
            arabicText: "وَاسْتَعِينُوا بِالصَّبْرِ وَالصَّلَاةِ ۚ وَإِنَّهَا لَكَبِيرَةٌ إِلَّا عَلَى الْخَاشِعِينَ",
            translationText: "And seek help through patience and prayer, and indeed, it is difficult except for the humbly submissive [to Allah]."
        ),
        DailyAyahData(
            surahId: 16,
            ayahNumber: 128,
            surahNameArabic: "النحل",
            surahNameEnglish: "An-Nahl",
            arabicText: "إِنَّ اللَّهَ مَعَ الَّذِينَ اتَّقَوْا وَالَّذِينَ هُمْ مُحْسِنُونَ",
            translationText: "Indeed, Allah is with those who fear Him and those who are doers of good."
        )
    ]
}

// MARK: - Timeline Entry
public struct AyahOfTheDayEntry: TimelineEntry {
    public let date: Date
    public let item: DailyAyahData

    public static let placeholder = AyahOfTheDayEntry(
        date: Date(),
        item: DailyAyahData.curatedCatalog[0]
    )
}

// MARK: - Timeline Provider
public struct AyahOfTheDayTimelineProvider: TimelineProvider {
    public func placeholder(in context: Context) -> AyahOfTheDayEntry {
        .placeholder
    }

    public func getSnapshot(in context: Context, completion: @escaping (AyahOfTheDayEntry) -> Void) {
        completion(.placeholder)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<AyahOfTheDayEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1
        let catalog = DailyAyahData.curatedCatalog
        let activeItem = catalog[(dayOfYear - 1) % catalog.count]

        let entry = AyahOfTheDayEntry(date: now, item: activeItem)

        // Refresh at the next midnight
        let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
}

// MARK: - Widget View
public struct BayanAyahOfTheDayWidgetView: View {
    var entry: AyahOfTheDayEntry
    @Environment(\.widgetFamily) var family

    private let goldPrimary = Color(red: 0.95, green: 0.80, blue: 0.40)
    private let goldSoft = Color(red: 0.78, green: 0.65, blue: 0.35)
    private let bgObsidian = Color(red: 0.05, green: 0.07, blue: 0.10)

    public var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            case .accessoryRectangular:
                lockScreenRectangular
            default:
                mediumView
            }
        }
        .widgetURL(URL(string: "bayan://surah?id=\(entry.item.surahId)&ayah=\(entry.item.ayahNumber)"))
    }

    // Small Home Screen Widget
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("AYAH OF THE DAY")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(1.0)
                    .foregroundColor(goldPrimary)

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(goldPrimary)
            }

            Spacer()

            Text(entry.item.arabicText)
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)

            Spacer()

            HStack {
                Text("Surah \(entry.item.surahNameEnglish)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Text(":\(entry.item.ayahNumber)")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(goldSoft)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            bgObsidian
        }
    }

    // Medium Home Screen Widget
    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(goldPrimary)
                    Text("AYAH OF THE DAY")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.2)
                        .foregroundColor(goldPrimary)
                }

                Spacer()

                Text("\(entry.item.surahNameEnglish) (\(entry.item.surahNameArabic)) • \(entry.item.ayahNumber)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(goldSoft)
            }

            Spacer()

            Text(entry.item.arabicText)
                .font(.system(size: 17, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)

            Spacer()

            Text(entry.item.translationText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.72))
                .lineLimit(2)
        }
        .padding(16)
        .containerBackground(for: .widget) {
            bgObsidian
        }
    }

    // Large Home Screen Widget
    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundColor(goldPrimary)
                    Text("DAILY QURAN INSPIRATION")
                        .font(.system(size: 11, weight: .heavy))
                        .tracking(1.4)
                        .foregroundColor(goldPrimary)
                }

                Spacer()

                Text("Surah \(entry.item.surahNameEnglish)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
            }

            Divider()
                .overlay(goldPrimary.opacity(0.25))

            Spacer()

            Text(entry.item.arabicText)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineSpacing(6)

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text("TRANSLATION")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.0)
                    .foregroundColor(goldSoft)

                Text(entry.item.translationText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(3)
            }

            Spacer()

            HStack {
                Text("\(entry.item.surahNameArabic) • الآية \(entry.item.ayahNumber)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(goldSoft)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "play.circle.fill")
                    Text("Recite in Bayan")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(goldPrimary)
            }
        }
        .padding(18)
        .containerBackground(for: .widget) {
            bgObsidian
        }
    }

    // Lock Screen Rectangular
    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text("Ayah of the Day")
                    .font(.caption2.weight(.bold))
            }
            Text(entry.item.arabicText)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
            Text("\(entry.item.surahNameEnglish) :\(entry.item.ayahNumber)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Widget Configuration
public struct BayanAyahOfTheDayWidget: Widget {
    public static let kind: String = "tools.rea.bayan.widget.ayahoftheday"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: AyahOfTheDayTimelineProvider()) { entry in
            BayanAyahOfTheDayWidgetView(entry: entry)
        }
        .configurationDisplayName("Ayah of the Day")
        .description("Daily inspirational Quran verse in beautiful Arabic and English.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular
        ])
    }
}
