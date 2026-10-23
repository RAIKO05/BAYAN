import Foundation
import AVFoundation

// MARK: - Word-by-Word Quran Service (كلمات القرآن)
/// High-efficiency lexical service providing word-by-word breakdown, transliteration,
/// direct English vocabulary mapping, Arabic roots, and single-word speech pronunciation.
@Observable
public final class QuranWordByWordService: @unchecked Sendable {
    public static let shared = QuranWordByWordService()

    private var speechSynthesizer: AVSpeechSynthesizer?

    // Common Quranic Vocabulary & Root Dictionary
    private let commonWordDict: [String: (translit: String, meaning: String, role: String, root: String)] = [
        // Basmalah & Fatiha
        "بِسْمِ": ("Bismi", "In (the) name", "Preposition + Noun", "س م و"),
        "اللَّهِ": ("Allāh", "(of) Allah", "Proper Name of God", "إ ل ه"),
        "ٱللَّهِ": ("Allāh", "(of) Allah", "Proper Name of God", "إ ل ه"),
        "الرَّحْمَـٰنِ": ("Ar-Raḥmān", "The Entirely Merciful", "Divine Attribute", "ر ح م"),
        "ٱلرَّحْمَـٰنِ": ("Ar-Raḥmān", "The Entirely Merciful", "Divine Attribute", "ر ح م"),
        "الرَّحِيمِ": ("Ar-Raḥīm", "The Especially Merciful", "Divine Attribute", "ر ح م"),
        "ٱلرَّحِيمِ": ("Ar-Raḥīm", "The Especially Merciful", "Divine Attribute", "ر ح م"),
        "الْحَمْدُ": ("Al-Ḥamdu", "All praise and gratitude", "Noun (Definite)", "ح م د"),
        "ٱلْحَمْدُ": ("Al-Ḥamdu", "All praise and gratitude", "Noun (Definite)", "ح م د"),
        "لِلَّهِ": ("Lillāhi", "Be to Allah", "Preposition + Proper Name", "إ ل ه"),
        "رَبِّ": ("Rabbi", "Lord, Cherisher & Sustainer", "Noun", "ر ب ب"),
        "الْعَالَمِينَ": ("Al-ʿĀlamīn", "Of the entire creation / worlds", "Noun (Plural)", "ع ل م"),
        "ٱلْعَـٰلَمِينَ": ("Al-ʿĀlamīn", "Of the entire creation / worlds", "Noun (Plural)", "ع ل م"),
        "مَـٰلِكِ": ("Māliki", "Master / Sovereign Owner", "Active Participle", "م ل ك"),
        "يَوْمِ": ("Yawmi", "(of the) Day", "Noun (Time)", "ي و م"),
        "الدِّينِ": ("Ad-Dīn", "(of) Judgment and Recompense", "Noun (Definite)", "د ي ن"),
        "ٱلدِّينِ": ("Ad-Dīn", "(of) Judgment and Recompense", "Noun (Definite)", "د ي ن"),
        "إِيَّاكَ": ("Iyyāka", "You alone", "Separated Pronoun (Accusative)", "إ ي ي"),
        "نَعْبُدُ": ("Naʿbudu", "We worship and surrender to", "Imperfect Verb (1st Pers Pl)", "ع ب د"),
        "وَإِيَّاكَ": ("Wa-iyyāka", "And You alone", "Conjunction + Pronoun", "إ ي ي"),
        "نَسْتَعِينُ": ("Nastaʿīn", "We ask for assistance", "Imperfect Verb (Form X)", "ع و ن"),
        "اهْدِنَا": ("Ihdinā", "Guide us firmly", "Imperative Verb + Object Pronoun", "ه د ي"),
        "ٱهْدِنَا": ("Ihdinā", "Guide us firmly", "Imperative Verb + Object Pronoun", "ه د ي"),
        "الصِّرَاطَ": ("Aṣ-Ṣirāṭ", "(to) The Straight Path", "Noun (Accusative)", "ص ر ط"),
        "ٱلصِّرَٰطَ": ("Aṣ-Ṣirāṭ", "(to) The Straight Path", "Noun (Accusative)", "ص ر ط"),
        "الْمُسْتَقِيمَ": ("Al-Mustaqīm", "The upright and true", "Active Participle (Form X)", "ق و م"),
        "ٱلْمُسْتَقِيمَ": ("Al-Mustaqīm", "The upright and true", "Active Participle (Form X)", "ق و م"),
        "صِرَاطَ": ("Ṣirāṭa", "(The) Path (of)", "Noun", "ص ر ط"),
        "الَّذِينَ": ("Alladhīna", "Those whom", "Relative Pronoun (Plural)", "ل ذ ي"),
        "ٱلَّذِينَ": ("Alladhīna", "Those whom", "Relative Pronoun (Plural)", "ل ذ ي"),
        "أَنْعَمْتَ": ("Anʿamta", "You have bestowed favor upon", "Perfect Verb (2nd Pers Masc)", "ن ع م"),
        "عَلَيْهِمْ": ("ʿAlayhim", "Upon them", "Preposition + Pronoun", "ع ل و"),
        "غَيْرِ": ("Ghayri", "Not (of)", "Noun (Negative Exception)", "غ ي ر"),
        "الْمَغْضُوبِ": ("Al-Maghḍūbi", "Those who earned wrath", "Passive Participle", "غ ض ب"),
        "ٱلْمَغْضُوبِ": ("Al-Maghḍūbi", "Those who earned wrath", "Passive Participle", "غ ض ب"),
        "وَلَا": ("Wa-lā", "And not", "Conjunction + Negative Particle", "ل ا"),
        "الضَّالِّينَ": ("Aḍ-Ḍāllīn", "Those who are astray", "Active Participle (Plural)", "ض ل ل"),
        "ٱلضَّآلِّينَ": ("Aḍ-Ḍāllīn", "Those who are astray", "Active Participle (Plural)", "ض ل ل"),

        // Frequent Quranic Core Lexicon
        "قُلْ": ("Qul", "Say (O Muhammad)", "Imperative Verb", "ق و ل"),
        "هُوَ": ("Huwa", "He is", "Pronoun (3rd Pers Masc)", "ه و"),
        "أَحَدٌ": ("Aḥad", "The One and Only Absolute", "Adjective / Divine Name", "أ ح د"),
        "الصَّمَدُ": ("Aṣ-Ṣamad", "The Self-Sufficient Refuge", "Divine Attribute", "ص م د"),
        "ٱلصَّمَدُ": ("Aṣ-Ṣamad", "The Self-Sufficient Refuge", "Divine Attribute", "ص م د"),
        "لَمْ": ("Lam", "Did not / Never", "Jussive Negative Particle", "ل م"),
        "يَلِدْ": ("Yalid", "He begets", "Imperfect Verb (Jussive)", "و ل د"),
        "وَلَمْ": ("Wa-lam", "And neither", "Conjunction + Negative Particle", "ل م"),
        "يُولَدْ": ("Yūlad", "Was He begotten", "Passive Verb (Jussive)", "و ل د"),
        "يَكُن": ("Yakun", "Is there / Has been", "Imperfect Verb (Kāna)", "ك و ن"),
        "لَّهُۥ": ("Lahū", "Unto Him", "Preposition + Pronoun", "ل"),
        "كُفُوًا": ("Kufuwan", "Any equal or comparable", "Noun (Accusative)", "ك ف أ"),
        "أَعُوذُ": ("Aʿūdhu", "I seek refuge and protection", "Imperfect Verb (1st Pers)", "ع و ذ"),
        "بِرَبِّ": ("Bi-Rabbi", "In the Lord of", "Preposition + Noun", "ر ب ب"),
        "الْفَلَقِ": ("Al-Falaq", "The daybreak / dawn", "Noun (Genitive)", "ف ل ق"),
        "ٱلْفَلَقِ": ("Al-Falaq", "The daybreak / dawn", "Noun (Genitive)", "ف ل ق"),
        "النَّاسِ": ("An-Nās", "Mankind", "Collective Noun", "أ ن س"),
        "ٱلنَّاسِ": ("An-Nās", "Mankind", "Collective Noun", "أ ن س"),
        "مِن": ("Min", "From", "Preposition", "م ن"),
        "شَرِّ": ("Sharri", "(the) Evil of", "Noun (Genitive)", "ش ر ر"),
        "مَا": ("Mā", "What / That which", "Relative Pronoun", "م ا"),
        "خَلَقَ": ("Khalaqa", "He created", "Perfect Verb (3rd Pers)", "خ ل ق"),
        "الْجَنَّةِ": ("Al-Jannah", "Paradise / The Gardens", "Noun (Feminine)", "ج ن ن"),
        "ٱلْجَنَّةِ": ("Al-Jannah", "Paradise / The Gardens", "Noun (Feminine)", "ج ن ن"),
        "النَّارِ": ("An-Nār", "The Fire / Hellfire", "Noun (Feminine)", "ن و ر"),
        "ٱلنَّارِ": ("An-Nār", "The Fire / Hellfire", "Noun (Feminine)", "ن و ر"),
        "آمَنُوا": ("Āmanū", "Those who believed", "Perfect Verb (Plural)", "أ م ن"),
        "ءَامَنُوا": ("Āmanū", "Those who believed", "Perfect Verb (Plural)", "أ م ن"),
        "عَمِلُوا": ("ʿAmilū", "Did righteous deeds", "Perfect Verb (Plural)", "ع م ل"),
        "الصَّالِحَاتِ": ("Aṣ-Ṣāliḥāt", "The righteous deeds", "Plural Noun (Accusative)", "ص ل ح"),
        "ٱلصَّـٰلِحَـٰتِ": ("Aṣ-Ṣāliḥāt", "The righteous deeds", "Plural Noun (Accusative)", "ص ل ح"),
        "إِنَّ": ("Inna", "Indeed / Truly", "Emphatic Accusative Particle", "إ ن ن"),
        "أَنَّ": ("Anna", "That", "Subordinating Conjunction", "أ ن ن"),
        "كَانَ": ("Kāna", "He was / He is ever", "Defective Verb (Past)", "ك و ن"),
        "عَلِيمٌ": ("ʿAlīm", "All-Knowing", "Divine Attribute", "ع ل م"),
        "حَكِيمٌ": ("Ḥakīm", "All-Wise", "Divine Attribute", "ح ك م"),
        "غَفُورٌ": ("Ghafūr", "Oft-Forgiving", "Divine Attribute", "غ ف ر"),
        "شَكُورٌ": ("Shakūr", "Appreciative of Good", "Divine Attribute", "ش ك ر"),
        "سَمِيعٌ": ("Samīʿ", "All-Hearing", "Divine Attribute", "س م ع"),
        "بَصِيرٌ": ("Baṣīr", "All-Seeing", "Divine Attribute", "ب ص ر"),
        "قَدِيرٌ": ("Qadīr", "All-Powerful over all things", "Divine Attribute", "ق د ر")
    ]

    private init() {}

    // MARK: - Word Tokenization & Resolution
    public func words(for surahId: Int, ayahNumber: Int) -> [QuranWord] {
        let rawArabic = QuranVerseText.arabic(surahId: surahId, ayahNumber: ayahNumber)
        let rawEnglish = QuranVerseText.translation(surahId: surahId, ayahNumber: ayahNumber)

        // Clean any trailing ayah markers or decorations
        let cleanArabic = rawArabic
            .replacingOccurrences(of: "\u{FD3E}", with: "")
            .replacingOccurrences(of: "\u{FD3F}", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        let arabicTokens = cleanArabic.split(separator: " ").map { String($0) }
        let englishTokens = rawEnglish.split(separator: " ").map { String($0) }

        var result: [QuranWord] = []

        for (index, token) in arabicTokens.enumerated() {
            let strippedToken = token.trimmingCharacters(in: CharacterSet.punctuationCharacters)

            if let info = commonWordDict[strippedToken] {
                result.append(
                    QuranWord(
                        surahId: surahId,
                        ayahNumber: ayahNumber,
                        wordIndex: index + 1,
                        arabic: token,
                        transliteration: info.translit,
                        translation: info.meaning,
                        grammarRole: info.role,
                        rootLetters: info.root
                    )
                )
            } else {
                // Algorithmic phonetics and mapped contextual meaning
                let translit = generateTransliteration(arabic: strippedToken)
                let meaning = approximateWordMeaning(tokenIndex: index, totalTokens: arabicTokens.count, englishTokens: englishTokens)
                let root = extractProbableRoot(arabic: strippedToken)

                result.append(
                    QuranWord(
                        surahId: surahId,
                        ayahNumber: ayahNumber,
                        wordIndex: index + 1,
                        arabic: token,
                        transliteration: translit,
                        translation: meaning,
                        grammarRole: inferGrammarRole(arabic: strippedToken),
                        rootLetters: root
                    )
                )
            }
        }

        return result
    }

    // MARK: - Algorithmic Transliteration Engine
    private func generateTransliteration(arabic: String) -> String {
        var result = ""
        let mapping: [Character: String] = [
            "ا": "a", "أ": "a", "إ": "i", "آ": "ā", "ء": "’",
            "ب": "b", "ت": "t", "ث": "th", "ج": "j", "ح": "ḥ",
            "خ": "kh", "د": "d", "ذ": "dh", "ر": "r", "ز": "z",
            "س": "s", "ش": "sh", "ص": "ṣ", "ض": "ḍ", "ط": "ṭ",
            "ظ": "ẓ", "ع": "ʿ", "غ": "gh", "ف": "f", "ق": "q",
            "ك": "k", "ل": "l", "م": "m", "ن": "n", "ه": "h",
            "و": "w", "ي": "y", "ى": "ā", "ة": "h",
            // Tashkeel / Diacritics
            "\u{064E}": "a", // Fatha
            "\u{064F}": "u", // Damma
            "\u{0650}": "i", // Kasra
            "\u{064B}": "an", // Fathatan
            "\u{064C}": "un", // Dammatan
            "\u{064D}": "in", // Kasratan
            "\u{0651}": "", // Shaddah
            "\u{0652}": "", // Sukun
            "\u{0670}": "ā"  // Dagger Alif
        ]

        for char in arabic {
            if let translit = mapping[char] {
                result += translit
            }
        }

        if result.isEmpty {
            return "kalimah"
        }
        return result.prefix(1).uppercased() + result.dropFirst()
    }

    private func approximateWordMeaning(tokenIndex: Int, totalTokens: Int, englishTokens: [String]) -> String {
        guard !englishTokens.isEmpty, totalTokens > 0 else { return "Quranic word" }
        let ratio = Double(tokenIndex) / Double(max(1, totalTokens))
        let targetEnglishIndex = min(Int(ratio * Double(englishTokens.count)), englishTokens.count - 1)

        let phrase = englishTokens[targetEnglishIndex]
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ";", with: "")
        return phrase.capitalized
    }

    private func extractProbableRoot(arabic: String) -> String? {
        let clean = QuranVerseText.normalizeArabic(arabic)
            .replacingOccurrences(of: "ال", with: "")
            .replacingOccurrences(of: "و", with: "")
            .replacingOccurrences(of: "ف", with: "")
            .replacingOccurrences(of: "ب", with: "")
            .replacingOccurrences(of: "ل", with: "")

        let consonants = clean.filter { !"اويى".contains($0) }
        if consonants.count >= 3 {
            let r = Array(consonants.prefix(3))
            return "\(r[0]) \(r[1]) \(r[2])"
        }
        return nil
    }

    private func inferGrammarRole(arabic: String) -> String {
        if arabic.hasPrefix("ال") || arabic.hasPrefix("ٱل") {
            return "Definite Noun"
        } else if arabic.hasPrefix("ي") || arabic.hasPrefix("ت") || arabic.hasPrefix("ن") || arabic.hasPrefix("أ") {
            return "Verb"
        } else if arabic.count <= 3 {
            return "Particle / Preposition"
        }
        return "Noun"
    }

    // MARK: - Single Word Audio Pronunciation
    @MainActor
    public func speakWord(word: QuranWord) {
        if speechSynthesizer == nil {
            speechSynthesizer = AVSpeechSynthesizer()
        }

        speechSynthesizer?.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: word.arabic)
        utterance.voice = AVSpeechSynthesisVoice(language: "ar-SA")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.05
        speechSynthesizer?.speak(utterance)

        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
