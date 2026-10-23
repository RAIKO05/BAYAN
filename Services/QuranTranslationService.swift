import Foundation
import SwiftUI

// MARK: - Multi-Language Quran Translation Service
@Observable
public final class QuranTranslationService {
    public static let shared = QuranTranslationService()

    private let kSelectedTranslationLang = "bayan_selected_translation_lang"

    public var selectedLanguage: QuranTranslationLanguage = .english {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: kSelectedTranslationLang)
        }
    }

    private init() {
        if let stored = UserDefaults.standard.string(forKey: kSelectedTranslationLang),
           let lang = QuranTranslationLanguage(rawValue: stored) {
            self.selectedLanguage = lang
        }
    }

    public func translation(for surahId: Int, ayahNumber: Int, language: QuranTranslationLanguage? = nil) -> String {
        let activeLang = language ?? selectedLanguage

        switch activeLang {
        case .english:
            return QuranVerseText.translation(surahId: surahId, ayahNumber: ayahNumber)

        case .arabicTafsir:
            return QuranTafsirService.shared.tafsir(for: surahId, ayahNumber: ayahNumber).arabicTafsir

        case .french:
            if let fr = frenchTranslations(surahId: surahId, ayahNumber: ayahNumber) {
                return fr
            }
            return QuranVerseText.translation(surahId: surahId, ayahNumber: ayahNumber)

        case .spanish:
            if let es = spanishTranslations(surahId: surahId, ayahNumber: ayahNumber) {
                return es
            }
            return QuranVerseText.translation(surahId: surahId, ayahNumber: ayahNumber)

        case .turkish:
            if let tr = turkishTranslations(surahId: surahId, ayahNumber: ayahNumber) {
                return tr
            }
            return QuranVerseText.translation(surahId: surahId, ayahNumber: ayahNumber)

        case .indonesian:
            if let id = indonesianTranslations(surahId: surahId, ayahNumber: ayahNumber) {
                return id
            }
            return QuranVerseText.translation(surahId: surahId, ayahNumber: ayahNumber)

        case .urdu:
            if let ur = urduTranslations(surahId: surahId, ayahNumber: ayahNumber) {
                return ur
            }
            return QuranVerseText.translation(surahId: surahId, ayahNumber: ayahNumber)
        }
    }

    // MARK: - Curated Authentic Multi-Language Verse Dictionaries
    private func frenchTranslations(surahId: Int, ayahNumber: Int) -> String? {
        if surahId == 1 {
            switch ayahNumber {
            case 1: return "Au nom d'Allah, le Tout Miséricordieux, le Très Miséricordieux."
            case 2: return "Louange à Allah, Seigneur de l'univers."
            case 3: return "Le Tout Miséricordieux, le Très Miséricordieux,"
            case 4: return "Maître du Jour de la rétribution."
            case 5: return "C'est Toi [Seul] que nous adorons, et c'est Toi [Seul] dont nous implorons secours."
            case 6: return "Guide-nous dans le droit chemin,"
            case 7: return "Le chemin de ceux que Tu as comblés de faveurs, non pas de ceux qui ont encouru Ta colère, ni des égarés."
            default: break
            }
        } else if surahId == 112 {
            switch ayahNumber {
            case 1: return "Dis: «Il est Allah, Unique."
            case 2: return "Allah, Le Seul à être imploré pour ce que nous désirons."
            case 3: return "Il n'a jamais engendré, n'a pas été engendré non plus."
            case 4: return "Et nul n'est égal à Lui»."
            default: break
            }
        } else if surahId == 2 && ayahNumber == 255 {
            return "Allah! Point de divinité à part Lui, le Vivant, Celui qui subsiste par Lui-même. Ni somnolence ni sommeil ne Le saisissent. À Lui appartient tout ce qui est dans les cieux et sur la terre."
        }
        return nil
    }

    private func spanishTranslations(surahId: Int, ayahNumber: Int) -> String? {
        if surahId == 1 {
            switch ayahNumber {
            case 1: return "En el nombre de Dios, el Compasivo con toda la creación, el Especialmente Misericordioso con los creyentes."
            case 2: return "Todas las alabanzas son para Dios, Señor de todo el universo,"
            case 3: return "el Compasivo, el Misericordioso,"
            case 4: return "Soberano absoluto del Día del Juicio."
            case 5: return "Solo a Ti te adoramos y solo de Ti imploramos ayuda."
            case 6: return "¡Guíanos por el camino recto!"
            case 7: return "El camino de los que han recibido Tus bendiciones, no el de los que han caído en Tu ira ni el de los extraviados."
            default: break
            }
        } else if surahId == 112 {
            switch ayahNumber {
            case 1: return "Di: «Él es Dios, la Única divinidad."
            case 2: return "Dios es el Absoluto [de Quien todo y todos necesitan]."
            case 3: return "No engendró ni fue engendrado."
            case 4: return "Y no hay nada ni nadie que sea semejante a Él»."
            default: break
            }
        } else if surahId == 2 && ayahNumber == 255 {
            return "¡Dios! No existe divinidad sino Él, el Viviente, el Autosuficiente. No lo afecta somnolencia ni sueño. Suyo es cuanto hay en los cielos y en la Tierra."
        }
        return nil
    }

    private func turkishTranslations(surahId: Int, ayahNumber: Int) -> String? {
        if surahId == 1 {
            switch ayahNumber {
            case 1: return "Rahmân ve Rahîm olan Allah'ın adıyla."
            case 2: return "Hamd, âlemlerin Rabbi olan Allah'a mahsustur."
            case 3: return "O, Rahmândır, Rahîmdir."
            case 4: return "Ceza (ve mükâfat) gününün sahibidir."
            case 5: return "(Rabbimiz!) Ancak sana kulluk eder ve yalnız senden yardım dileriz."
            case 6: return "Bizi doğru yola ilet."
            case 7: return "Kendilerine lütuf ve ihsanda bulunduğun kimselerin yoluna; gazaba uğramışların ve sapmışların yoluna değil!"
            default: break
            }
        } else if surahId == 112 {
            switch ayahNumber {
            case 1: return "De ki: O, Allah birdir."
            case 2: return "Allah sameddir (her şey O'na muhtaçtır, O hiçbir şeye muhtaç değildir)."
            case 3: return "O, doğurmamış ve doğmamıştır."
            case 4: return "O'nun hiçbir dengi yoktur."
            default: break
            }
        } else if surahId == 2 && ayahNumber == 255 {
            return "Allah, O'ndan başka ilâh olmayan, kendisini uyuklama ve uyku tutmayan, Hayy ve Kayyûm olandır. Göklerde ve yerde ne varsa hepsi O'nundur."
        }
        return nil
    }

    private func indonesianTranslations(surahId: Int, ayahNumber: Int) -> String? {
        if surahId == 1 {
            switch ayahNumber {
            case 1: return "Dengan nama Allah Yang Maha Pengasih, Maha Penyayang."
            case 2: return "Segala puji bagi Allah, Tuhan seluruh alam,"
            case 3: return "Yang Maha Pengasih, Maha Penyayang,"
            case 4: return "Pemilik hari pembalasan."
            case 5: return "Hanya kepada Engkaulah kami menyembah dan hanya kepada Engkaulah kami memohon pertolongan."
            case 6: return "Tunjukilah kami jalan yang lurus,"
            case 7: return "(yaitu) jalan orang-orang yang telah Engkau beri nikmat kepadanya; bukan (jalan) mereka yang dimurkai, dan bukan (pula jalan) mereka yang sesat."
            default: break
            }
        } else if surahId == 112 {
            switch ayahNumber {
            case 1: return "Katakanlah (Muhammad), «Dialah Allah, Yang Maha Esa."
            case 2: return "Allah tempat meminta segala sesuatu."
            case 3: return "(Allah) tidak beranak dan tidak pula diperanakkan."
            case 4: return "Dan tidak ada sesuatu yang setara dengan Dia»."
            default: break
            }
        } else if surahId == 2 && ayahNumber == 255 {
            return "Allah, tidak ada tuhan selain Dia. Yang Mahahidup, Yang terus-menerus mengurus (makhluk-Nya), tidak mengantuk dan tidak tidur. Milik-Nya apa yang ada di langit dan apa yang ada di bumi."
        }
        return nil
    }

    private func urduTranslations(surahId: Int, ayahNumber: Int) -> String? {
        if surahId == 1 {
            switch ayahNumber {
            case 1: return "شروع اللہ کا نام لے کر جو بڑا مہربان نہایت رحم والا ہے"
            case 2: return "سب طرح کی تعریف اللہ ہی کو زیبا ہے جو تمام جہانوں کا پروردگار ہے"
            case 3: return "بڑا مہربان نہایت رحم والا"
            case 4: return "انصاف کے دن کا حاکم"
            case 5: return "ہم تیری ہی عبادت کرتے ہیں اور تجھ ہی سے مدد مانگتے ہیں"
            case 6: return "ہم کو سیدھے راستے پر چلا"
            case 7: return "ان لوگوں کے راستے پر جن پر تو اپنا فضل و کرم کرتا رہا نہ ان کے جن پر غصہ ہوتا رہا اور نہ گمراہوں کے"
            default: break
            }
        } else if surahId == 112 {
            switch ayahNumber {
            case 1: return "کہو کہ وہ اللہ ایک ہے"
            case 2: return "اللہ بےنیاز ہے"
            case 3: return "نہ اس کی کوئی اولاد ہے اور نہ وہ کسی کی اولاد ہے"
            case 4: return "اور کوئی اس کا ہمسر نہیں"
            default: break
            }
        } else if surahId == 2 && ayahNumber == 255 {
            return "اللہ کے سوا کوئی معبود نہیں، وہ زندہ ہے اور سب کو قائم رکھنے والا ہے۔ نہ اس کو اونگھ آتی ہے نہ نیند۔ جو کچھ آسمانوں میں اور جو کچھ زمین میں ہے سب اسی کا ہے۔"
        }
        return nil
    }
}
