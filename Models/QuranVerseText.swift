import Foundation

public struct QuranVerseText {
    public static var isWarshActive: Bool = false

    // Lazy-loaded offline cache for all 6,236 Ayahs across all 114 Surahs
    private static var arabicCache: [String: [String]] = {
        let resourceName = isWarshActive ? "quran_warsh" : "quran_uthmani"
        let fallbackName = "quran_uthmani"
        let targetUrl = Bundle.main.url(forResource: resourceName, withExtension: "json") ??
                        Bundle.main.url(forResource: fallbackName, withExtension: "json")
        guard let url = targetUrl,
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return dict
    }()

    private static var warshCache: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "quran_warsh", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return dict
    }()

    // Method to toggle or reload Qiraah
    public static func reloadForQiraah(warsh: Bool) {
        isWarshActive = warsh
    }

    public static func normalizeArabic(_ text: String) -> String {
        var str = text
        let diacritics: [Character] = [
            "َ", "ً", "ُ", "ٌ", "ِ", "ٍ", "ْ", "ّ", "ٰ", "ٓ", "ۥ", "ۦ", "ۛ", "ۖ", "ۗ", "ۚ", "ۘ", "ۜ", "۟", "۠", "ۢ", "ۣ", "ۤ", "ـ"
        ]
        str.removeAll { diacritics.contains($0) }
        str = str.replacingOccurrences(of: "أ", with: "ا")
            .replacingOccurrences(of: "إ", with: "ا")
            .replacingOccurrences(of: "آ", with: "ا")
            .replacingOccurrences(of: "ٱ", with: "ا")
            .replacingOccurrences(of: "ة", with: "ه")
            .replacingOccurrences(of: "ى", with: "ي")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return str
    }

    public static func searchVerse(query: String) -> (surahId: Int, ayahNumber: Int)? {
        let normalizedQuery = normalizeArabic(query)
        guard normalizedQuery.count >= 3 else { return nil }

        let queryTokens = normalizedQuery.components(separatedBy: .whitespaces)
            .filter { $0.count >= 2 }

        guard !queryTokens.isEmpty else { return nil }

        for (surahKey, ayahs) in arabicCache {
            guard let sId = Int(surahKey) else { continue }
            for (idx, ayahText) in ayahs.enumerated() {
                let normalizedAyah = normalizeArabic(ayahText)
                if normalizedAyah.contains(normalizedQuery) || normalizedQuery.contains(normalizedAyah) {
                    return (sId, idx + 1)
                }
                // Token subset match if query is multiple words
                if queryTokens.count >= 2 && queryTokens.allSatisfy({ normalizedAyah.contains($0) }) {
                    return (sId, idx + 1)
                }
            }
        }
        return nil
    }

    private static var translationCache: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "quran_translation_en", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        return dict
    }()

    public static func arabic(surahId: Int, ayahNumber: Int) -> String {
        // Check offline Warsh dataset if Warsh is active
        if isWarshActive, let warshAyahs = warshCache[String(surahId)],
           ayahNumber >= 1, ayahNumber <= warshAyahs.count {
            return warshAyahs[ayahNumber - 1]
        }

        // Check offline bundled full Quran dataset first
        if let surahAyahs = arabicCache[String(surahId)],
           ayahNumber >= 1,
           ayahNumber <= surahAyahs.count {
            return surahAyahs[ayahNumber - 1]
        }

        switch surahId {
        case 1: // Al-Fatihah
            switch ayahNumber {
            case 1: return "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
            case 2: return "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ"
            case 3: return "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
            case 4: return "مَٰلِكِ يَوْمِ ٱلدِّينِ"
            case 5: return "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ"
            case 6: return "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ"
            case 7: return "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ"
            default: return "آيَةٌ مِنَ ٱلْقُرْءَانِ ٱلْكَرِيمِ"
            }
        case 112: // Al-Ikhlas
            switch ayahNumber {
            case 1: return "قُلْ هُوَ ٱللَّهُ أَحَدٌ"
            case 2: return "ٱللَّهُ ٱلصَّمَدُ"
            case 3: return "لَمْ يَلِدْ وَلَمْ يُولَدْ"
            case 4: return "وَلَمْ يَكُن لَّهُۥ كُفُوًا أَحَدٌۢ"
            default: return "آيَةٌ مِنَ ٱلْقُرْءَانِ ٱلْكَرِيمِ"
            }
        case 113: // Al-Falaq
            switch ayahNumber {
            case 1: return "قُلْ أَعُوذُ بِرَبِّ ٱلْفَلَقِ"
            case 2: return "مِن شَرِّ مَا خَلَقَ"
            case 3: return "وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ"
            case 4: return "وَمِن شَرِّ ٱلنَّفَّٰثَٰتِ فِي ٱلْعُقَدِ"
            case 5: return "وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ"
            default: return "آيَةٌ مِنَ ٱلْقُرْءَانِ ٱلْكَرِيمِ"
            }
        case 114: // An-Nas
            switch ayahNumber {
            case 1: return "قُلْ أَعُوذُ بِرَبِّ ٱلنَّاسِ"
            case 2: return "مَلِكِ ٱلنَّاسِ"
            case 3: return "إِلَٰهِ ٱلنَّاسِ"
            case 4: return "مِن شَرِّ ٱلْوَسْوَاسِ ٱلْخَنَّاسِ"
            case 5: return "ٱلَّذِي يُوَسْوِسُ فِي صُدُورِ ٱلنَّاسِ"
            case 6: return "مِنَ ٱلْجِنَّةِ وَٱلنَّاسِ"
            default: return "آيَةٌ مِنَ ٱلْقُرْءَانِ ٱلْكَرِيمِ"
            }
        case 55: // Ar-Rahman
            switch ayahNumber {
            case 1: return "ٱلرَّحْمَٰنُ"
            case 2: return "عَلَّمَ ٱلْقُرْءَانَ"
            case 3: return "خَلَقَ ٱلْإِنسَٰنَ"
            case 4: return "عَلَّمَهُ ٱلْبَيَانَ"
            default: return "فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ"
            }
        case 2: // Al-Baqarah
            switch ayahNumber {
            case 1: return "الم"
            case 2: return "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًى لِّلْمُتَّقِينَ"
            case 3: return "ٱلَّذِينَ يُؤْمِنُونَ بِٱلْغَيْبِ وَيُقِيمُونَ ٱلصَّلَوٰةَ وَمِمَّا رَزَقْنَٰهُمْ يُنفِقُونَ"
            case 4: return "وَٱلَّذِينَ يُؤْمِنُونَ بِمَآ أُنزِلَ إِلَيْكَ وَمَآ أُنزِلَ مِن قَبْلِكَ وَبِٱلْـَٔاخِرَةِ هُمْ يُوقِنُونَ"
            case 5: return "أُو۟لَٰٓئِكَ عَلَىٰ هُدًى مِّن رَّبِّهِمْ ۖ وَأُو۟لَٰٓئِكَ هُمُ ٱلْمُفْلِحُونَ"
            case 255: return "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلْحَىُّ ٱلْقَيُّومُ ۚ لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُۥ مَا فِى ٱلسَّمَٰوَٰتِ وَمَا فِى ٱلْأَرْضِ"
            default: return "آيَةٌ \(ayahNumber) مِن سُورَةِ البَقَرَةِ"
            }
        case 36: // Ya-Sin
            switch ayahNumber {
            case 1: return "يس"
            case 2: return "وَٱلْقُرْءَانِ ٱلْحَكِيمِ"
            case 3: return "إِنَّكَ لَمِنَ ٱلْمُرْسَلِينَ"
            case 4: return "عَلَىٰ صِرَٰطٍ مُّسْتَقِيمٍ"
            default: return "آيَةٌ \(ayahNumber) مِن سُورَةِ يس"
            }
        case 67: // Al-Mulk
            switch ayahNumber {
            case 1: return "تَبَٰرَكَ ٱلَّذِي بِيَدِهِ ٱلْمُلْكُ وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ"
            case 2: return "ٱلَّذِي خَلَقَ ٱلْمَوْتَ وَٱلْحَيَوٰةَ لِيَبْلُوَكُمْ أَيُّكُمْ أَحْسَنُ عَمَلًا ۚ وَهُوَ ٱلْعَزِيزُ ٱلْغَفُورُ"
            default: return "آيَةٌ \(ayahNumber) مِن سُورَةِ المُلْكِ"
            }
        default:
            return "آيَةٌ \(ayahNumber) مِن كِتَابِ ٱللَّهِ ٱلْعَزِيزِ"
        }
    }

    public static func translation(surahId: Int, ayahNumber: Int) -> String {
        // Check offline bundled translation first
        if let surahTrans = translationCache[String(surahId)],
           ayahNumber >= 1,
           ayahNumber <= surahTrans.count {
            return surahTrans[ayahNumber - 1]
        }

        switch surahId {
        case 1:
            switch ayahNumber {
            case 1: return "In the name of Allah, the Entirely Merciful, the Especially Merciful."
            case 2: return "[All] praise is [due] to Allah, Lord of the worlds."
            case 3: return "The Entirely Merciful, the Especially Merciful."
            case 4: return "Sovereign of the Day of Recompense."
            case 5: return "It is You we worship and You we ask for help."
            case 6: return "Guide us to the straight path."
            case 7: return "The path of those upon whom You have bestowed favor, not of those who have evoked [Your] anger or of those who are astray."
            default: return "Verse \(ayahNumber) of the Holy Quran."
            }
        case 112:
            switch ayahNumber {
            case 1: return "Say, 'He is Allah, [who is] One,'"
            case 2: return "Allah, the Eternal Refuge."
            case 3: return "He neither begets nor is born,"
            case 4: return "Nor is there to Him any equivalent."
            default: return "Verse \(ayahNumber)."
            }
        case 113:
            switch ayahNumber {
            case 1: return "Say, 'I seek refuge in the Lord of daybreak'"
            case 2: return "From the evil of that which He created"
            case 3: return "And from the evil of darkness when it settles"
            case 4: return "And from the evil of the blowers in knots"
            case 5: return "And from the evil of an envier when he envies."
            default: return "Verse \(ayahNumber)."
            }
        case 114:
            switch ayahNumber {
            case 1: return "Say, 'I seek refuge in the Lord of mankind,'"
            case 2: return "The Sovereign of mankind,"
            case 3: return "The God of mankind,"
            case 4: return "From the evil of the retreating whisperer -"
            case 5: return "Who whispers [evil] into the breasts of mankind -"
            case 6: return "From among the jinn and mankind."
            default: return "Verse \(ayahNumber)."
            }
        case 55:
            switch ayahNumber {
            case 1: return "The Most Merciful"
            case 2: return "Taught the Qur'an,"
            case 3: return "Created man,"
            case 4: return "Taught him eloquent speech (Al-Bayan)."
            default: return "So which of the favors of your Lord would you deny?"
            }
        default:
            return "Verse \(ayahNumber) of the Holy Qur'an."
        }
    }
}
