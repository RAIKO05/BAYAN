import SwiftUI

public struct TajweedRule: Identifiable, Hashable {
    public let id: String
    public let nameArabic: String
    public let nameEnglish: String
    public let color: Color
    public let hexColor: String
    public let descriptionArabic: String
    public let descriptionEnglish: String
    public let exampleArabic: String

    public static let ghunnah = TajweedRule(
        id: "ghunnah",
        nameArabic: "الغُنّة",
        nameEnglish: "Ghunnah (Nasalization)",
        color: Color(red: 1.0, green: 0.6, blue: 0.0), // Amber Orange
        hexColor: "#FF9500",
        descriptionArabic: "صوت رخيم يخرج من الخيشوم بمقدار حركتين في النون والميم المشددتين.",
        descriptionEnglish: "A nasal sound held for 2 counts on Noon or Meem with a Shaddah (نّ / مّ).",
        exampleArabic: "إِنَّ الَّذِينَ آمَنُوا"
    )

    public static let qalqalah = TajweedRule(
        id: "qalqalah",
        nameArabic: "القَلقَلة",
        nameEnglish: "Qalqalah (Echoing / Bouncing)",
        color: Color(red: 0.2, green: 0.8, blue: 0.6), // Emerald Teal
        hexColor: "#30D158",
        descriptionArabic: "اضطراب الصوت عند النطق بالحرف الساكن من حروف (ق، ط، ب، ج، د).",
        descriptionEnglish: "Echoing/bouncing bounce on letters of (ق، ط، ب، ج، د) when bearing a Sukun.",
        exampleArabic: "قُلْ هُوَ اللَّهُ أَحَدْ ۝ اللَّهُ الصَّمَدْ"
    )

    public static let idgham = TajweedRule(
        id: "idgham",
        nameArabic: "الإِدغام",
        nameEnglish: "Idgham (Merging)",
        color: Color(red: 0.7, green: 0.35, blue: 0.9), // Purple Indigo
        hexColor: "#AF52DE",
        descriptionArabic: "إدخال حرف ساكن في حرف متحرك من حروف (يرملون).",
        descriptionEnglish: "Merging a Noon Sakinah or Tanween into letters of (يرملون).",
        exampleArabic: "مَن يَقُولُ • مِّن رَّبِّهِمْ"
    )

    public static let ikhfa = TajweedRule(
        id: "ikhfa",
        nameArabic: "الإِخفاء",
        nameEnglish: "Ikhfa (Concealment)",
        color: Color(red: 0.2, green: 0.6, blue: 1.0), // Electric Sky Blue
        hexColor: "#0A84FF",
        descriptionArabic: "النطق بالنون الساكنة أو التنوين بصفة بين الإظهار والإدغام مع بقاء الغنة.",
        descriptionEnglish: "Concealing the Noon Sakinah or Tanween before 15 letters with ghunnah.",
        exampleArabic: "مِن قَبْلِكُمْ • كُنتُمْ"
    )

    public static let iqlab = TajweedRule(
        id: "iqlab",
        nameArabic: "الإِقلاب",
        nameEnglish: "Iqlab (Conversion to Meem)",
        color: Color(red: 1.0, green: 0.84, blue: 0.0), // Gold Yellow
        hexColor: "#FFD60A",
        descriptionArabic: "قلب النون الساكنة أو التنوين ميماً مخفاة بغنة عند حرف الباء.",
        descriptionEnglish: "Converting Noon Sakinah or Tanween into a concealed Meem before Baa (ب).",
        exampleArabic: "مِنۢ بَعْدِ • عَلِيمٌۢ بِذَاتِ الصُّدُورِ"
    )

    public static let madd = TajweedRule(
        id: "madd",
        nameArabic: "المَدّ",
        nameEnglish: "Madd (Elongation 4-6 Harakat)",
        color: Color(red: 1.0, green: 0.25, blue: 0.25), // Crimson Red
        hexColor: "#FF453A",
        descriptionArabic: "إطالة الصوت بحرف المد واللين عند وجود همزة أو سكون (٤ إلى ٦ حركات).",
        descriptionEnglish: "Elongating vowels (Alif, Waw, Yaa) with a Madd sign (~) for 4 to 6 counts.",
        exampleArabic: "السَّمَاءِ ۝ جَاءَتْ ۝ وَلَا الضَّالِّينَ"
    )

    public static let allRules: [TajweedRule] = [
        .madd,
        .ghunnah,
        .qalqalah,
        .ikhfa,
        .idgham,
        .iqlab
    ]
}
