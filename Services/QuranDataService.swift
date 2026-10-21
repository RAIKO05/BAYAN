import Foundation

@Observable
public final class QuranDataService {
    public static let shared = QuranDataService()

    public enum Qiraah: String, CaseIterable, Identifiable {
        case hafs = "Hafs 'an 'Asim"
        case warsh = "Warsh 'an Nafi'"

        public var id: String { rawValue }

        public var titleArabic: String {
            switch self {
            case .hafs: return "حفص عن عاصم"
            case .warsh: return "ورش عن نافع"
            }
        }

        public var shortLabel: String {
            switch self {
            case .hafs: return "حفص"
            case .warsh: return "ورش"
            }
        }
    }

    public var selectedQiraah: Qiraah = .hafs {
        didSet {
            QuranVerseText.reloadForQiraah(warsh: selectedQiraah == .warsh)
        }
    }

    public let allSurahs: [Surah]

    private init() {
        self.allSurahs = QuranDataService.generateFullSurahList()
    }

    public func surah(for id: Int) -> Surah? {
        allSurahs.first { $0.id == id }
    }

    public func search(query: String) -> [Surah] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allSurahs }
        let lower = trimmed.lowercased()
        let normQuery = QuranVerseText.normalizeArabic(trimmed)

        return allSurahs.filter {
            let normArabic = QuranVerseText.normalizeArabic($0.nameArabic)
            return $0.nameArabic.contains(trimmed) ||
                   normArabic.contains(normQuery) ||
                   $0.nameEnglish.lowercased().contains(lower) ||
                   $0.nameTranslation.lowercased().contains(lower) ||
                   String($0.id) == trimmed
        }
    }

    // Comprehensive list of all 114 Surahs
    private static func generateFullSurahList() -> [Surah] {
        [
            Surah(id: 1, nameArabic: "الفاتحة", nameEnglish: "Al-Fatihah", nameTranslation: "The Opening", revelationType: .meccan, totalAyahs: 7, startPage: 1),
            Surah(id: 2, nameArabic: "البقرة", nameEnglish: "Al-Baqarah", nameTranslation: "The Cow", revelationType: .medinan, totalAyahs: 286, startPage: 2),
            Surah(id: 3, nameArabic: "آل عمران", nameEnglish: "Ali 'Imran", nameTranslation: "Family of Imran", revelationType: .medinan, totalAyahs: 200, startPage: 50),
            Surah(id: 4, nameArabic: "النساء", nameEnglish: "An-Nisa", nameTranslation: "The Women", revelationType: .medinan, totalAyahs: 176, startPage: 77),
            Surah(id: 5, nameArabic: "المائدة", nameEnglish: "Al-Ma'idah", nameTranslation: "The Table Spread", revelationType: .medinan, totalAyahs: 120, startPage: 106),
            Surah(id: 6, nameArabic: "الأنعام", nameEnglish: "Al-An'am", nameTranslation: "The Cattle", revelationType: .meccan, totalAyahs: 165, startPage: 128),
            Surah(id: 7, nameArabic: "الأعراف", nameEnglish: "Al-A'raf", nameTranslation: "The Heights", revelationType: .meccan, totalAyahs: 206, startPage: 151),
            Surah(id: 8, nameArabic: "الأنفال", nameEnglish: "Al-Anfal", nameTranslation: "The Spoils of War", revelationType: .medinan, totalAyahs: 75, startPage: 177),
            Surah(id: 9, nameArabic: "التوبة", nameEnglish: "At-Tawbah", nameTranslation: "The Repentance", revelationType: .medinan, totalAyahs: 129, startPage: 187),
            Surah(id: 10, nameArabic: "يونس", nameEnglish: "Yunus", nameTranslation: "Jonah", revelationType: .meccan, totalAyahs: 109, startPage: 208),
            Surah(id: 11, nameArabic: "هود", nameEnglish: "Hud", nameTranslation: "Hud", revelationType: .meccan, totalAyahs: 123, startPage: 221),
            Surah(id: 12, nameArabic: "يوسف", nameEnglish: "Yusuf", nameTranslation: "Joseph", revelationType: .meccan, totalAyahs: 111, startPage: 235),
            Surah(id: 13, nameArabic: "الرعد", nameEnglish: "Ar-Ra'd", nameTranslation: "The Thunder", revelationType: .medinan, totalAyahs: 43, startPage: 249),
            Surah(id: 14, nameArabic: "إبراهيم", nameEnglish: "Ibrahim", nameTranslation: "Abraham", revelationType: .meccan, totalAyahs: 52, startPage: 255),
            Surah(id: 15, nameArabic: "الحجر", nameEnglish: "Al-Hijr", nameTranslation: "The Rocky Tract", revelationType: .meccan, totalAyahs: 99, startPage: 262),
            Surah(id: 16, nameArabic: "النحل", nameEnglish: "An-Nahl", nameTranslation: "The Bee", revelationType: .meccan, totalAyahs: 128, startPage: 267),
            Surah(id: 17, nameArabic: "الإسراء", nameEnglish: "Al-Isra", nameTranslation: "The Night Journey", revelationType: .meccan, totalAyahs: 111, startPage: 282),
            Surah(id: 18, nameArabic: "الكهف", nameEnglish: "Al-Kahf", nameTranslation: "The Cave", revelationType: .meccan, totalAyahs: 110, startPage: 293),
            Surah(id: 19, nameArabic: "مريم", nameEnglish: "Maryam", nameTranslation: "Mary", revelationType: .meccan, totalAyahs: 98, startPage: 305),
            Surah(id: 20, nameArabic: "طه", nameEnglish: "Ta-Ha", nameTranslation: "Ta-Ha", revelationType: .meccan, totalAyahs: 135, startPage: 312),
            Surah(id: 21, nameArabic: "الأنبياء", nameEnglish: "Al-Anbiya", nameTranslation: "The Prophets", revelationType: .meccan, totalAyahs: 112, startPage: 322),
            Surah(id: 22, nameArabic: "الحج", nameEnglish: "Al-Hajj", nameTranslation: "The Pilgrimage", revelationType: .medinan, totalAyahs: 78, startPage: 332),
            Surah(id: 23, nameArabic: "المؤمنون", nameEnglish: "Al-Mu'minun", nameTranslation: "The Believers", revelationType: .meccan, totalAyahs: 118, startPage: 342),
            Surah(id: 24, nameArabic: "النور", nameEnglish: "An-Nur", nameTranslation: "The Light", revelationType: .medinan, totalAyahs: 64, startPage: 350),
            Surah(id: 25, nameArabic: "الفرقان", nameEnglish: "Al-Furqan", nameTranslation: "The Criterion", revelationType: .meccan, totalAyahs: 77, startPage: 359),
            Surah(id: 26, nameArabic: "الشعراء", nameEnglish: "Ash-Shu'ara", nameTranslation: "The Poets", revelationType: .meccan, totalAyahs: 227, startPage: 367),
            Surah(id: 27, nameArabic: "النمل", nameEnglish: "An-Naml", nameTranslation: "The Ant", revelationType: .meccan, totalAyahs: 93, startPage: 377),
            Surah(id: 28, nameArabic: "القصص", nameEnglish: "Al-Qasas", nameTranslation: "The Stories", revelationType: .meccan, totalAyahs: 88, startPage: 385),
            Surah(id: 29, nameArabic: "العنكبوت", nameEnglish: "Al-'Ankabut", nameTranslation: "The Spider", revelationType: .meccan, totalAyahs: 69, startPage: 396),
            Surah(id: 30, nameArabic: "الروم", nameEnglish: "Ar-Rum", nameTranslation: "The Romans", revelationType: .meccan, totalAyahs: 60, startPage: 404),
            Surah(id: 31, nameArabic: "لقمان", nameEnglish: "Luqman", nameTranslation: "Luqman", revelationType: .meccan, totalAyahs: 34, startPage: 411),
            Surah(id: 32, nameArabic: "السجدة", nameEnglish: "As-Sajdah", nameTranslation: "The Prostration", revelationType: .meccan, totalAyahs: 30, startPage: 415),
            Surah(id: 33, nameArabic: "الأحزاب", nameEnglish: "Al-Ahzab", nameTranslation: "The Combined Forces", revelationType: .medinan, totalAyahs: 73, startPage: 418),
            Surah(id: 34, nameArabic: "سبأ", nameEnglish: "Saba", nameTranslation: "Sheba", revelationType: .meccan, totalAyahs: 54, startPage: 428),
            Surah(id: 35, nameArabic: "فاطر", nameEnglish: "Fatir", nameTranslation: "Originator", revelationType: .meccan, totalAyahs: 45, startPage: 434),
            Surah(id: 36, nameArabic: "يس", nameEnglish: "Ya-Sin", nameTranslation: "Ya-Sin", revelationType: .meccan, totalAyahs: 83, startPage: 440),
            Surah(id: 37, nameArabic: "الصافات", nameEnglish: "As-Saffat", nameTranslation: "Those Ranks", revelationType: .meccan, totalAyahs: 182, startPage: 446),
            Surah(id: 38, nameArabic: "ص", nameEnglish: "Sad", nameTranslation: "The Letter Sad", revelationType: .meccan, totalAyahs: 88, startPage: 453),
            Surah(id: 39, nameArabic: "الزمر", nameEnglish: "Az-Zumar", nameTranslation: "The Troops", revelationType: .meccan, totalAyahs: 75, startPage: 458),
            Surah(id: 40, nameArabic: "غافر", nameEnglish: "Ghafir", nameTranslation: "The Forgiver", revelationType: .meccan, totalAyahs: 85, startPage: 467),
            Surah(id: 41, nameArabic: "فصلت", nameEnglish: "Fussilat", nameTranslation: "Explained in Detail", revelationType: .meccan, totalAyahs: 54, startPage: 477),
            Surah(id: 42, nameArabic: "الشورى", nameEnglish: "Ash-Shura", nameTranslation: "The Consultation", revelationType: .meccan, totalAyahs: 53, startPage: 483),
            Surah(id: 43, nameArabic: "الزخرف", nameEnglish: "Az-Zukhruf", nameTranslation: "The Gold Adornment", revelationType: .meccan, totalAyahs: 89, startPage: 489),
            Surah(id: 44, nameArabic: "الدخان", nameEnglish: "Ad-Dukhan", nameTranslation: "The Smoke", revelationType: .meccan, totalAyahs: 59, startPage: 496),
            Surah(id: 45, nameArabic: "الجاثية", nameEnglish: "Al-Jathiyah", nameTranslation: "The Crouching", revelationType: .meccan, totalAyahs: 37, startPage: 499),
            Surah(id: 46, nameArabic: "الأحقاف", nameEnglish: "Al-Ahqaf", nameTranslation: "The Wind-Curved Sandhills", revelationType: .meccan, totalAyahs: 35, startPage: 502),
            Surah(id: 47, nameArabic: "محمد", nameEnglish: "Muhammad", nameTranslation: "Muhammad", revelationType: .medinan, totalAyahs: 38, startPage: 507),
            Surah(id: 48, nameArabic: "الفتح", nameEnglish: "Al-Fath", nameTranslation: "The Victory", revelationType: .medinan, totalAyahs: 29, startPage: 511),
            Surah(id: 49, nameArabic: "الحجرات", nameEnglish: "Al-Hujurat", nameTranslation: "The Rooms", revelationType: .medinan, totalAyahs: 18, startPage: 515),
            Surah(id: 50, nameArabic: "ق", nameEnglish: "Qaf", nameTranslation: "The Letter Qaf", revelationType: .meccan, totalAyahs: 45, startPage: 518),
            Surah(id: 51, nameArabic: "الذاريات", nameEnglish: "Adh-Dhariyat", nameTranslation: "The Winnowing Winds", revelationType: .meccan, totalAyahs: 60, startPage: 520),
            Surah(id: 52, nameArabic: "الطور", nameEnglish: "At-Tur", nameTranslation: "The Mount", revelationType: .meccan, totalAyahs: 49, startPage: 523),
            Surah(id: 53, nameArabic: "النجم", nameEnglish: "An-Najm", nameTranslation: "The Star", revelationType: .meccan, totalAyahs: 62, startPage: 526),
            Surah(id: 54, nameArabic: "القمر", nameEnglish: "Al-Qamar", nameTranslation: "The Moon", revelationType: .meccan, totalAyahs: 55, startPage: 528),
            Surah(id: 55, nameArabic: "الرحمن", nameEnglish: "Ar-Rahman", nameTranslation: "The Beneficent", revelationType: .medinan, totalAyahs: 78, startPage: 531),
            Surah(id: 56, nameArabic: "الواقعة", nameEnglish: "Al-Waqi'ah", nameTranslation: "The Inevitable", revelationType: .meccan, totalAyahs: 96, startPage: 534),
            Surah(id: 57, nameArabic: "الحديد", nameEnglish: "Al-Hadid", nameTranslation: "The Iron", revelationType: .medinan, totalAyahs: 29, startPage: 537),
            Surah(id: 58, nameArabic: "المجادلة", nameEnglish: "Al-Mujadila", nameTranslation: "The Pleading Woman", revelationType: .medinan, totalAyahs: 22, startPage: 542),
            Surah(id: 59, nameArabic: "الحشر", nameEnglish: "Al-Hashr", nameTranslation: "The Exile", revelationType: .medinan, totalAyahs: 24, startPage: 545),
            Surah(id: 60, nameArabic: "الممتحنة", nameEnglish: "Al-Mumtahanah", nameTranslation: "She that is to be examined", revelationType: .medinan, totalAyahs: 13, startPage: 549),
            Surah(id: 61, nameArabic: "الصف", nameEnglish: "As-Saff", nameTranslation: "The Ranks", revelationType: .medinan, totalAyahs: 14, startPage: 551),
            Surah(id: 62, nameArabic: "الجمعة", nameEnglish: "Al-Jumu'ah", nameTranslation: "The Congregation", revelationType: .medinan, totalAyahs: 11, startPage: 553),
            Surah(id: 63, nameArabic: "المنافقون", nameEnglish: "Al-Munafiqun", nameTranslation: "The Hypocrites", revelationType: .medinan, totalAyahs: 11, startPage: 554),
            Surah(id: 64, nameArabic: "التغابن", nameEnglish: "At-Taghabun", nameTranslation: "Mutual Disillusion", revelationType: .medinan, totalAyahs: 18, startPage: 556),
            Surah(id: 65, nameArabic: "الطلاق", nameEnglish: "At-Talaq", nameTranslation: "The Divorce", revelationType: .medinan, totalAyahs: 12, startPage: 558),
            Surah(id: 66, nameArabic: "التحريم", nameEnglish: "At-Tahrim", nameTranslation: "The Prohibition", revelationType: .medinan, totalAyahs: 12, startPage: 560),
            Surah(id: 67, nameArabic: "الملك", nameEnglish: "Al-Mulk", nameTranslation: "The Sovereignty", revelationType: .meccan, totalAyahs: 30, startPage: 562),
            Surah(id: 68, nameArabic: "القلم", nameEnglish: "Al-Qalam", nameTranslation: "The Pen", revelationType: .meccan, totalAyahs: 52, startPage: 564),
            Surah(id: 69, nameArabic: "الحاقة", nameEnglish: "Al-Haqqah", nameTranslation: "The Reality", revelationType: .meccan, totalAyahs: 52, startPage: 566),
            Surah(id: 70, nameArabic: "المعارج", nameEnglish: "Al-Ma'arij", nameTranslation: "The Ascending Stairways", revelationType: .meccan, totalAyahs: 44, startPage: 568),
            Surah(id: 71, nameArabic: "نوح", nameEnglish: "Nuh", nameTranslation: "Noah", revelationType: .meccan, totalAyahs: 28, startPage: 570),
            Surah(id: 72, nameArabic: "الجن", nameEnglish: "Al-Jinn", nameTranslation: "The Jinn", revelationType: .meccan, totalAyahs: 28, startPage: 572),
            Surah(id: 73, nameArabic: "المزمل", nameEnglish: "Al-Muzzammil", nameTranslation: "The Enshrouded One", revelationType: .meccan, totalAyahs: 20, startPage: 574),
            Surah(id: 74, nameArabic: "المدثر", nameEnglish: "Al-Muddaththir", nameTranslation: "The Cloaked One", revelationType: .meccan, totalAyahs: 56, startPage: 575),
            Surah(id: 75, nameArabic: "القيامة", nameEnglish: "Al-Qiyamah", nameTranslation: "The Resurrection", revelationType: .meccan, totalAyahs: 40, startPage: 577),
            Surah(id: 76, nameArabic: "الإنسان", nameEnglish: "Al-Insan", nameTranslation: "Man", revelationType: .medinan, totalAyahs: 31, startPage: 578),
            Surah(id: 77, nameArabic: "المرسلات", nameEnglish: "Al-Mursalat", nameTranslation: "The Emissaries", revelationType: .meccan, totalAyahs: 50, startPage: 580),
            Surah(id: 78, nameArabic: "النبأ", nameEnglish: "An-Naba", nameTranslation: "The Tidings", revelationType: .meccan, totalAyahs: 40, startPage: 582),
            Surah(id: 79, nameArabic: "النازعات", nameEnglish: "An-Nazi'at", nameTranslation: "Those who drag forth", revelationType: .meccan, totalAyahs: 46, startPage: 583),
            Surah(id: 80, nameArabic: "عبس", nameEnglish: "'Abasa", nameTranslation: "He Frowned", revelationType: .meccan, totalAyahs: 42, startPage: 585),
            Surah(id: 81, nameArabic: "التكوير", nameEnglish: "At-Takwir", nameTranslation: "The Overthrowing", revelationType: .meccan, totalAyahs: 29, startPage: 586),
            Surah(id: 82, nameArabic: "الانفطار", nameEnglish: "Al-Infitar", nameTranslation: "The Cleaving", revelationType: .meccan, totalAyahs: 19, startPage: 587),
            Surah(id: 83, nameArabic: "المطففين", nameEnglish: "Al-Mutaffifin", nameTranslation: "The Defrauding", revelationType: .meccan, totalAyahs: 36, startPage: 587),
            Surah(id: 84, nameArabic: "الانشقاق", nameEnglish: "Al-Inshiqaq", nameTranslation: "The Splitting Open", revelationType: .meccan, totalAyahs: 25, startPage: 589),
            Surah(id: 85, nameArabic: "البروج", nameEnglish: "Al-Buruj", nameTranslation: "The Mansions of the Stars", revelationType: .meccan, totalAyahs: 22, startPage: 590),
            Surah(id: 86, nameArabic: "الطارق", nameEnglish: "At-Tariq", nameTranslation: "The Morning Star", revelationType: .meccan, totalAyahs: 17, startPage: 591),
            Surah(id: 87, nameArabic: "الأعلى", nameEnglish: "Al-A'la", nameTranslation: "The Most High", revelationType: .meccan, totalAyahs: 19, startPage: 591),
            Surah(id: 88, nameArabic: "الغاشية", nameEnglish: "Al-Ghashiyah", nameTranslation: "The Overwhelming", revelationType: .meccan, totalAyahs: 26, startPage: 592),
            Surah(id: 89, nameArabic: "الفجر", nameEnglish: "Al-Fajr", nameTranslation: "The Dawn", revelationType: .meccan, totalAyahs: 30, startPage: 593),
            Surah(id: 90, nameArabic: "البلد", nameEnglish: "Al-Balad", nameTranslation: "The City", revelationType: .meccan, totalAyahs: 20, startPage: 594),
            Surah(id: 91, nameArabic: "الشمس", nameEnglish: "Ash-Shams", nameTranslation: "The Sun", revelationType: .meccan, totalAyahs: 15, startPage: 595),
            Surah(id: 92, nameArabic: "الليل", nameEnglish: "Al-Layl", nameTranslation: "The Night", revelationType: .meccan, totalAyahs: 21, startPage: 595),
            Surah(id: 93, nameArabic: "الضحى", nameEnglish: "Ad-Duha", nameTranslation: "The Morning Hours", revelationType: .meccan, totalAyahs: 11, startPage: 596),
            Surah(id: 94, nameArabic: "الشرح", nameEnglish: "Ash-Sharh", nameTranslation: "The Relief", revelationType: .meccan, totalAyahs: 8, startPage: 596),
            Surah(id: 95, nameArabic: "التين", nameEnglish: "At-Tin", nameTranslation: "The Fig", revelationType: .meccan, totalAyahs: 8, startPage: 597),
            Surah(id: 96, nameArabic: "العلق", nameEnglish: "Al-'Alaq", nameTranslation: "The Clot", revelationType: .meccan, totalAyahs: 19, startPage: 597),
            Surah(id: 97, nameArabic: "القدر", nameEnglish: "Al-Qadr", nameTranslation: "The Power", revelationType: .meccan, totalAyahs: 5, startPage: 598),
            Surah(id: 98, nameArabic: "البينة", nameEnglish: "Al-Bayyinah", nameTranslation: "The Clear Proof", revelationType: .medinan, totalAyahs: 8, startPage: 598),
            Surah(id: 99, nameArabic: "الزلزلة", nameEnglish: "Az-Zalzalah", nameTranslation: "The Earthquake", revelationType: .medinan, totalAyahs: 8, startPage: 599),
            Surah(id: 100, nameArabic: "العاديات", nameEnglish: "Al-'Adiyat", nameTranslation: "The Courser", revelationType: .meccan, totalAyahs: 11, startPage: 599),
            Surah(id: 101, nameArabic: "القارعة", nameEnglish: "Al-Qari'ah", nameTranslation: "The Calamity", revelationType: .meccan, totalAyahs: 11, startPage: 600),
            Surah(id: 102, nameArabic: "التكاثر", nameEnglish: "At-Takathur", nameTranslation: "The Rivalry in World Increase", revelationType: .meccan, totalAyahs: 8, startPage: 600),
            Surah(id: 103, nameArabic: "العصر", nameEnglish: "Al-'Asr", nameTranslation: "The Declining Day", revelationType: .meccan, totalAyahs: 3, startPage: 601),
            Surah(id: 104, nameArabic: "الهمزة", nameEnglish: "Al-Humazah", nameTranslation: "The Traducer", revelationType: .meccan, totalAyahs: 9, startPage: 601),
            Surah(id: 105, nameArabic: "الفيل", nameEnglish: "Al-Fil", nameTranslation: "The Elephant", revelationType: .meccan, totalAyahs: 5, startPage: 601),
            Surah(id: 106, nameArabic: "قريش", nameEnglish: "Quraysh", nameTranslation: "Quraysh", revelationType: .meccan, totalAyahs: 4, startPage: 602),
            Surah(id: 107, nameArabic: "الماعون", nameEnglish: "Al-Ma'un", nameTranslation: "The Small Kindnesses", revelationType: .meccan, totalAyahs: 7, startPage: 602),
            Surah(id: 108, nameArabic: "الكوثر", nameEnglish: "Al-Kawthar", nameTranslation: "The Abundance", revelationType: .meccan, totalAyahs: 3, startPage: 602),
            Surah(id: 109, nameArabic: "الكافرون", nameEnglish: "Al-Kafirun", nameTranslation: "The Disbelievers", revelationType: .meccan, totalAyahs: 6, startPage: 603),
            Surah(id: 110, nameArabic: "النصر", nameEnglish: "An-Nasr", nameTranslation: "The Divine Support", revelationType: .medinan, totalAyahs: 3, startPage: 603),
            Surah(id: 111, nameArabic: "المسد", nameEnglish: "Al-Masad", nameTranslation: "The Palm Fiber", revelationType: .meccan, totalAyahs: 5, startPage: 603),
            Surah(id: 112, nameArabic: "الإخلاص", nameEnglish: "Al-Ikhlas", nameTranslation: "The Sincerity", revelationType: .meccan, totalAyahs: 4, startPage: 604),
            Surah(id: 113, nameArabic: "الفلق", nameEnglish: "Al-Falaq", nameTranslation: "The Daybreak", revelationType: .meccan, totalAyahs: 5, startPage: 604),
            Surah(id: 114, nameArabic: "الناس", nameEnglish: "An-Nas", nameTranslation: "Mankind", revelationType: .meccan, totalAyahs: 6, startPage: 604)
        ]
    }
}
