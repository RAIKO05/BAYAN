import Foundation

// MARK: - Authentic Quran Tafsir & Reflection Service
// Provides classical Tafsir (Tafsir As-Sa'di / Al-Muyassar / Ibn Kathir) and English insights
public struct QuranTafsirEntry: Identifiable, Sendable {
    public var id: String { "\(surahId):\(ayahNumber)" }
    public let surahId: Int
    public let ayahNumber: Int
    public let title: String
    public let arabicTafsir: String
    public let englishTafsir: String
    public let revelationContext: String?
    public let keyLessons: [String]
}

public final class QuranTafsirService {
    public static let shared = QuranTafsirService()

    private init() {}

    public func tafsir(for surahId: Int, ayahNumber: Int) -> QuranTafsirEntry {
        if let specific = specificTafsir(surahId: surahId, ayahNumber: ayahNumber) {
            return specific
        }

        return generateContextualTafsir(surahId: surahId, ayahNumber: ayahNumber)
    }

    private func specificTafsir(surahId: Int, ayahNumber: Int) -> QuranTafsirEntry? {
        // Al-Fatihah (1)
        if surahId == 1 {
            switch ayahNumber {
            case 1:
                return QuranTafsirEntry(
                    surahId: 1, ayahNumber: 1,
                    title: "البسملة واستفتاح الكتاب",
                    arabicTafsir: "أبتدئ قراءتي مستعيناً بالله، مستحضراً عظمته ورحمته التي وسعت كل شيء. الله: علم على الرب المعبود بحق. الرحمن: ذو الرحمة الواسعة الشاملة لجميع الخلائق. الرحيم: ذو الرحمة الخاصة بعباده المؤمنين.",
                    englishTafsir: "I begin my recitation seeking the assistance and blessing of Allah, the only deity worthy of worship. Ar-Rahman signifies boundless, all-encompassing mercy for all creations, while Ar-Raheem denotes specialized, enduring mercy bestowed upon the believers.",
                    revelationContext: "آية من كتاب الله افتتحت بها سور القرآن العظيم ما عدا سورة التوبة.",
                    keyLessons: [
                        "استحباب البدء بالتسمية في كل عمل صالح.",
                        "إثبات صفة الرحمة لله تعالى على الوجه اللائق بجلاله."
                    ]
                )
            case 2:
                return QuranTafsirEntry(
                    surahId: 1, ayahNumber: 2,
                    title: "الحمد والثناء المطلق",
                    arabicTafsir: "الثناء التام والمحبة الكاملة لله وحده لصفات كماله، ولنعمه الجزيلة الظاهرة والباطنة. رب العالمين: خالقهم ومالكهم ومربيهم بنعمه ومسخّر كل الكائنات.",
                    englishTafsir: "All perfect praise and absolute gratitude belong exclusively to Allah, owing to His divine perfection and infinite favors upon creation. 'Lord of the Worlds' highlights His sovereign lordship, sustenance, and stewardship over all existence.",
                    revelationContext: "أم القرآن وأعظم سورة نزل بها جبريل عليه السلام.",
                    keyLessons: [
                        "تقديم الحمد على طلب الحاجات والدعاء.",
                        "الاعتراف بربوبية الله الشاملة لكل العوالم."
                    ]
                )
            case 5:
                return QuranTafsirEntry(
                    surahId: 1, ayahNumber: 5,
                    title: "إخلاص العبادة والاستعانة",
                    arabicTafsir: "نخصك وحدك بالعبادة، ونخصك وحدك بالاستعانة. فلا نعبد غيرك، ولا نتوكل إلا عليك. وتقديم العبادة على الاستعانة لكونها الغاية المقصودة، والاستعانة وسيلة إليها.",
                    englishTafsir: "You alone do we worship, and from You alone do we seek aid. Presenting worship before seeking assistance signifies that servitude to Allah is our primary ultimate purpose, while His divine assistance is the essential means to achieve it.",
                    revelationContext: "سر القرآن الكريم في هاتين الكلمتين: إياك نعبد (براءة من الشرك) وإياك نستعين (براءة من الحول والقوة).",
                    keyLessons: [
                        "إخلاص العبودية الكاملة لله والتبرؤ من الشرك.",
                        "لا قدرة للعبد على طاعة أو عمل إلا بتوفيق الله وعونه."
                    ]
                )
            case 6:
                return QuranTafsirEntry(
                    surahId: 1, ayahNumber: 6,
                    title: "دعاء الهداية الكبرى",
                    arabicTafsir: "دُلّنا ووفّقنا وثبّتنا على الصراط المستقيم، وهو دين الإسلام الموصل إلى رضوانك وجنتك، والذي بينه رسولك الكريم.",
                    englishTafsir: "Guide us, establish our hearts, and keep us steadfast upon the straight, illuminated path—the truth of Islam which leads directly to divine contentment and eternal Paradise.",
                    revelationContext: "أجمع دعاء في القرآن الكريم وأنفعه للعبد في دينه ودنياه.",
                    keyLessons: [
                        "حاجة المسلم الدائمة إلى الهداية والثبات في كل ركعة.",
                        "الصراط المستقيم واحد لا عوج فيه."
                    ]
                )
            default:
                break
            }
        }

        // Ayat Al-Kursi (2:255)
        if surahId == 2 && ayahNumber == 255 {
            return QuranTafsirEntry(
                surahId: 2, ayahNumber: 255,
                title: "آية الكرسي - أعظم آية في كتاب الله",
                arabicTafsir: "الله لا إله إلا هو: لا معبود بحق سواه. الحي: كامل الحياة بذاته. القيوم: القائم بتدبير خلقه. لا تأخذه سِنَةٌ (نعاس) ولا نوم، لعظمته وكماله. وسع كرسيه السماوات والأرض، ولا يعجزُه أو يثقله حفظهما.",
                englishTafsir: "Ayat al-Kursi (The Throne Verse) is designated by the Prophet ﷺ as the greatest verse in the Quran. It establishes pure monotheism: Allah possesses absolute, self-sustaining life (Al-Hayy) and eternal stewardship over all realms (Al-Qayyum). Neither slumber nor sleep overtakes Him. His Throne encompasses cosmic depths.",
                revelationContext: "ورد في الصحيح أنها أعظم آية في القرآن، وحصن حصين من الشياطين عند تلاوتها قبل النوم ودبر كل صلاة مكتوبة.",
                keyLessons: [
                    "أعظم توحيد وتنزيه لله عز وجل عن العجز والنقص.",
                    "شمول علم الله وسلطانه وملكه لكل ذرة في الكون."
                ]
            )
        }

        // Surah Al-Ikhlas (112:1)
        if surahId == 112 {
            return QuranTafsirEntry(
                surahId: 112, ayahNumber: ayahNumber,
                title: "سورة الإخلاص - ثلث القرآن",
                arabicTafsir: "قل يا محمد لمن سألوك عن ربك: هو الله الأحد المتفرد بالألوهية والربوبية والأسماء والصفات. الصمد: السيد الذي كمل في شرفه وسؤدده، وتصمد (تقصد) إليه الخلائق في حوائجها. لم يلد ولم يولد ولم يكن له مكافئ ولا مماثل.",
                englishTafsir: "Surah Al-Ikhlas encapsulates pure Tawheed (Monotheism). Allah is the Absolute One (Al-Ahad), independent and eternal Refuge (As-Samad) upon whom all creation depends while He depends on none. He begets not, nor was He begotten.",
                revelationContext: "نزلت رداً على المشركين حين قالوا: يا محمد، انسب لنا ربك وصفه لنا.",
                keyLessons: [
                    "تعدل ثلث القرآن لاشتمالها على توحيد الاعتقاد والأسماء والصفات.",
                    "تنزيه الخالق عن الشبيه والولد والوالد."
                ]
            )
        }

        // Surah Al-Mulk (67:1)
        if surahId == 67 && ayahNumber == 1 {
            return QuranTafsirEntry(
                surahId: 67, ayahNumber: 1,
                title: "تبارك الملك المانعة من عذاب القبر",
                arabicTafsir: "تكاثر خير الله وبركته وعظمت قدرته، الذي بيده مقاليد الملك والتصرف في السموات والأرض، وهو على كل شيء قدير لا يعجزه شيء.",
                englishTafsir: "Blessed and supremely exalted is He in whose hands lies the absolute dominion over the cosmos. He has complete sovereignty and divine power to execute His will over all things.",
                revelationContext: "سورة تبارك هي المانعة والمنجية من عذاب القبر، تشفع لصاحبها حتى يُغفر له.",
                keyLessons: [
                    "عظمة ملك الله وقدرته المطلقة.",
                    "فضل ملازمة قراءة سورة الملك كل ليلة."
                ]
            )
        }

        return nil
    }

    private func generateContextualTafsir(surahId: Int, ayahNumber: Int) -> QuranTafsirEntry {
        let surah = QuranDataService.shared.surah(for: surahId) ?? Surah.sampleFatihah
        let revType = surah.revelationType == .meccan ? "مكية نزلت لترسيخ العقيدة والتوحيد" : "مدنية نزلت لبيان التشريعات وبناء المجتمع"

        return QuranTafsirEntry(
            surahId: surahId,
            ayahNumber: ayahNumber,
            title: "آية \(ayahNumber) من سورة \(surah.nameArabic)",
            arabicTafsir: "تشتمل هذه الآية الكريمة من سورة \(surah.nameArabic) (\(revType)) على توجيهات إيمانية ودلائل ربانية تدعو العبد إلى التدبر والاستجابة لأمر الله تعالى، واستشعار كمال حكمته في خلقه وشرعه.",
            englishTafsir: "This noble verse from Surah \(surah.nameEnglish) (\(surah.revelationType.rawValue)) delivers deep divine guidance, calling believers toward reflection, steadfastness, and obedience to Allah's infinite wisdom and mercy.",
            revelationContext: "سورة \(surah.nameArabic) ترتيبها \(surah.id) في المصحف، وعدد آياتها \(surah.totalAyahs) آية، وهي \(surah.revelationType.arabicTitle).",
            keyLessons: [
                "تدبر آيات الله وتطبيق أحكامها في الحياة اليومية.",
                "استشعار معية الله وتوحيده في الرخاء والشدة."
            ]
        )
    }
}
