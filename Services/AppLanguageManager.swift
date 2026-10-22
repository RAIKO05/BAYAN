import SwiftUI

// MARK: - Supported App Languages
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case arabic = "ar"
    case english = "en"
    case french = "fr"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .arabic: return "العربية"
        case .english: return "English"
        case .french: return "Français"
        }
    }

    public var subtitle: String {
        switch self {
        case .arabic: return "اللغة العربية الفصحى"
        case .english: return "English (US / UK)"
        case .french: return "Français (Maroc / France)"
        }
    }

    public var flagEmoji: String {
        switch self {
        case .arabic: return "🇲🇦"
        case .english: return "🇬🇧"
        case .french: return "🇫🇷"
        }
    }

    public var layoutDirection: LayoutDirection {
        switch self {
        case .arabic: return .rightToLeft
        case .english, .french: return .leftToRight
        }
    }
}

// MARK: - Centralized Localization Manager
@Observable
public final class AppLanguageManager {
    public static let shared = AppLanguageManager()

    public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: storageKey)
        }
    }

    private let storageKey = "bayan_selected_app_language"

    private init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Default to Arabic or English based on device locale
            let pref = Locale.preferredLanguages.first ?? "ar"
            if pref.starts(with: "ar") {
                self.currentLanguage = .arabic
            } else if pref.starts(with: "fr") {
                self.currentLanguage = .french
            } else {
                self.currentLanguage = .english
            }
        }
    }

    public func setLanguage(_ lang: AppLanguage) {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.currentLanguage = lang
        }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    // MARK: - Localized String Translation Lookup
    public func tr(_ key: String) -> String {
        if let langDict = translations[currentLanguage], let val = langDict[key] {
            return val
        }
        // Fallback to English, then key
        if let enDict = translations[.english], let val = enDict[key] {
            return val
        }
        return key
    }

    private let translations: [AppLanguage: [String: String]] = [
        // MARK: - Arabic
        .arabic: [
            // Tabs
            "tab_identify": "التعرف",
            "tab_mushaf": "المصحف",
            "tab_prayers": "الصلوات",
            "tab_adkar": "الأذكار",
            "tab_history": "الملف الشخصي",

            // Prayers
            "prayer_fajr": "الفجر",
            "prayer_sunrise": "الشروق",
            "prayer_dhuhr": "الظهر",
            "prayer_asr": "العصر",
            "prayer_maghrib": "المغرب",
            "prayer_isha": "العشاء",
            "next_prayer": "الصلاة القادمة",
            "time": "الوقت",
            "qibla_bearing": "اتجاه القبلة",
            "aligned_kaaba": "مواجه للكعبة المشرفة",

            // Audio Identifier
            "tap_to_identify": "اضغط للتعرف على التلاوة",
            "stop_listening": "إيقاف الاستماع",
            "listening_recitation": "جاري الاستماع للتلاوة...",
            "point_iphone": "وجّه هاتفك نحو التلاوة (المسجد، السيارة، التلفاز)",
            "type_search_verse": "البحث بالنص أو كتابة الآية",
            "recent_match": "آخر تطابق",
            "no_recitation": "لم يتم التقاط صوت واضح",
            "live_hearing": "جاري الاستماع",

            // Settings & Features
            "adhan_notifications": "تنبيهات صوت الأذان",
            "pre_adhan_alert": "تنبيه قبل الأذان بـ 15 دقيقة",
            "calculation_method": "طريقة الحساب",
            "asr_school": "المذهب في صلاة العصر",
            "icloud_sync": "مزامنة آي كلاود",
            "app_language": "لغة التطبيق",
            "app_theme": "المظهر",
            "done": "تم",
            "cancel": "إلغاء",
            "save": "حفظ",
            "search": "بحث",
            "tafsir": "التفسير",
            "reciter": "القارئ",
            "surah": "سورة",
            "ayah": "آية",
            "khatmah_goal": "ختمة القرآن الكريم",
            "tasbih": "المسبحة الإلكترونية"
        ],

        // MARK: - French
        .french: [
            // Tabs
            "tab_identify": "Identifier",
            "tab_mushaf": "Coran",
            "tab_prayers": "Prières",
            "tab_adkar": "Invocations",
            "tab_history": "Profil",

            // Prayers
            "prayer_fajr": "Fajr",
            "prayer_sunrise": "Chourouk",
            "prayer_dhuhr": "Dhohr",
            "prayer_asr": "Asr",
            "prayer_maghrib": "Maghrib",
            "prayer_isha": "Icha",
            "next_prayer": "PROCHAINE PRIÈRE",
            "time": "Heure",
            "qibla_bearing": "Direction de la Qibla",
            "aligned_kaaba": "ALIGNÉ AVEC LA KAABA",

            // Audio Identifier
            "tap_to_identify": "APPUYEZ POUR IDENTIFIER",
            "stop_listening": "ARRÊTER L'ÉCOUTE",
            "listening_recitation": "Écoute de la récitation en cours...",
            "point_iphone": "Pointez votre iPhone vers la récitation (Mosquée, voiture, TV)",
            "type_search_verse": "Rechercher par texte ou verset",
            "recent_match": "DERNIER RÉSULTAT",
            "no_recitation": "Aucune récitation détectée",
            "live_hearing": "Écoute en cours",

            // Settings & Features
            "adhan_notifications": "Notifications audio de l'Adhan",
            "pre_adhan_alert": "Alerte 15m avant l'Adhan",
            "calculation_method": "Méthode de calcul",
            "asr_school": "École juristique (Asr)",
            "icloud_sync": "Synchronisation iCloud",
            "app_language": "Langue de l'application",
            "app_theme": "Thème",
            "done": "Terminé",
            "cancel": "Annuler",
            "save": "Enregistrer",
            "search": "Rechercher",
            "tafsir": "Tafsir",
            "reciter": "Récitateur",
            "surah": "Sourate",
            "ayah": "Verset",
            "khatmah_goal": "Objectif de Khatmah",
            "tasbih": "Chapelet Numérique (Tasbih)"
        ],

        // MARK: - English
        .english: [
            // Tabs
            "tab_identify": "Identify",
            "tab_mushaf": "Mushaf",
            "tab_prayers": "Prayers",
            "tab_adkar": "Adkar",
            "tab_history": "Profile",

            // Prayers
            "prayer_fajr": "Fajr",
            "prayer_sunrise": "Sunrise",
            "prayer_dhuhr": "Dhuhr",
            "prayer_asr": "Asr",
            "prayer_maghrib": "Maghrib",
            "prayer_isha": "Isha",
            "next_prayer": "NEXT PRAYER",
            "time": "Time",
            "qibla_bearing": "Qibla Direction",
            "aligned_kaaba": "ALIGNED WITH HOLY KAABA",

            // Audio Identifier
            "tap_to_identify": "TAP TO IDENTIFY RECITATION",
            "stop_listening": "STOP LISTENING",
            "listening_recitation": "Listening to Recitation...",
            "point_iphone": "Point your iPhone toward any recitation (Mosque, car, or TV)",
            "type_search_verse": "Type or Search Verse Text",
            "recent_match": "RECENT MATCH",
            "no_recitation": "No recitation detected",
            "live_hearing": "Hearing",

            // Settings & Features
            "adhan_notifications": "Adhan Audio Notifications",
            "pre_adhan_alert": "15m Pre-Adhan Reminder Alert",
            "calculation_method": "Calculation Method",
            "asr_school": "Asr Juristic School",
            "icloud_sync": "iCloud Sync",
            "app_language": "App Language",
            "app_theme": "Theme",
            "done": "Done",
            "cancel": "Cancel",
            "save": "Save",
            "search": "Search",
            "tafsir": "Tafsir",
            "reciter": "Reciter",
            "surah": "Surah",
            "ayah": "Ayah",
            "khatmah_goal": "Khatmah Reading Goal",
            "tasbih": "Digital Tasbih Counter"
        ]
    ]
}

// MARK: - String Localization Extension
extension String {
    public var localized: String {
        AppLanguageManager.shared.tr(self)
    }
}
