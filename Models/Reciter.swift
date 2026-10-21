import Foundation

public struct Reciter: Identifiable, Codable, Hashable {
    public let id: String
    public let nameArabic: String
    public let nameEnglish: String
    public var name: String { nameEnglish }
    public let style: RecitationStyle
    public let riwayah: Riwayah
    public let serverSubdomain: String // EveryAyah / MP3Quran directory identifier

    public enum RecitationStyle: String, Codable, CaseIterable, Hashable {
        case murattal = "Murattal"
        case mujawwad = "Mujawwad"
        case muallim = "Muallim (Teacher)"
    }

    public enum Riwayah: String, Codable, CaseIterable, Hashable {
        case hafs = "Hafs 'an 'Asim"
        case warsh = "Warsh 'an Nafi'"
        case qalun = "Qalun 'an Nafi'"
        case alDuri = "Al-Duri 'an Abi 'Amr"
    }

    public func audioUrl(surah: Int, ayah: Int) -> URL? {
        let surahStr = String(format: "%03d", surah)
        let ayahStr = String(format: "%03d", ayah)
        let fullAyahCode = "\(surahStr)\(ayahStr)"

        if id == "kazabri_warsh" {
            // Omar Al-Kazabri Warsh - Verified Cloudflare High-Speed CDN
            return URL(string: "https://cdn.mp3quran.net/audio/omar-kazabri/r1/\(surahStr).mp3")
        }

        if id == "yassin_warsh" {
            // Yassin Al-Jazaery (Warsh verse-by-verse EveryAyah)
            return URL(string: "https://everyayah.com/data/warsh/warsh_yassin_al_jazaery_64kbps/\(fullAyahCode).mp3")
        }

        if id == "abdulbasit_warsh" {
            // Abdul Basit (Warsh verse-by-verse EveryAyah)
            return URL(string: "https://everyayah.com/data/warsh/warsh_Abdul_Basit_128kbps/\(fullAyahCode).mp3")
        }

        if id == "omardiaa" {
            return URL(string: "https://everyayah.com/data/Alafasy_128kbps/\(fullAyahCode).mp3")
        }

        let urlString = "https://everyayah.com/data/\(serverSubdomain)/\(fullAyahCode).mp3"
        return URL(string: urlString)
    }

    public static let unknownReciter = Reciter(
        id: "unknown",
        nameArabic: "قارئ غير معروف",
        nameEnglish: "Unknown Reciter",
        style: .murattal,
        riwayah: .hafs,
        serverSubdomain: "Alafasy_128kbps"
    )

    // Curated standard reciters catalog
    public static let standardCatalog: [Reciter] = [
        Reciter(
            id: "alafasy",
            nameArabic: "مشاري راشد العفاسي",
            nameEnglish: "Mishary Rashid Alafasy",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Alafasy_128kbps"
        ),
        Reciter(
            id: "yassin_warsh",
            nameArabic: "ياسين الجزائري (ورش)",
            nameEnglish: "Yassin Al-Jazaery (Warsh)",
            style: .murattal,
            riwayah: .warsh,
            serverSubdomain: "warsh_yassin"
        ),
        Reciter(
            id: "kazabri_warsh",
            nameArabic: "عمر القزابري (ورش)",
            nameEnglish: "Omar Al-Kazabri (Warsh)",
            style: .murattal,
            riwayah: .warsh,
            serverSubdomain: "Warsh_Omar_AlQazabri"
        ),
        Reciter(
            id: "abdulbasit_warsh",
            nameArabic: "عبد الباسط عبد الصمد (ورش)",
            nameEnglish: "Abdul Basit (Warsh)",
            style: .murattal,
            riwayah: .warsh,
            serverSubdomain: "warsh_abdulbasit"
        ),
        Reciter(
            id: "abdulbasit_mujawwad",
            nameArabic: "عبد الباسط عبد الصمد (مجود)",
            nameEnglish: "Abdul Basit (Mujawwad)",
            style: .mujawwad,
            riwayah: .hafs,
            serverSubdomain: "Abdul_Basit_Mujawwad_128kbps"
        ),
        Reciter(
            id: "abdulbasit_murattal",
            nameArabic: "عبد الباسط عبد الصمد (مرتل)",
            nameEnglish: "Abdul Basit (Murattal)",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Abdul_Basit_Murattal_192kbps"
        ),
        Reciter(
            id: "minshawi_mujawwad",
            nameArabic: "محمد صديق المنشاوي (مجود)",
            nameEnglish: "Mohamed Siddiq Al-Minshawi (Mujawwad)",
            style: .mujawwad,
            riwayah: .hafs,
            serverSubdomain: "Minshawy_Mujawwad_192kbps"
        ),
        Reciter(
            id: "minshawi_murattal",
            nameArabic: "محمد صديق المنشاوي (مرتل)",
            nameEnglish: "Mohamed Siddiq Al-Minshawi (Murattal)",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Minshawy_Murattal_128kbps"
        ),
        Reciter(
            id: "husary_murattal",
            nameArabic: "محمود خليل الحصري",
            nameEnglish: "Mahmoud Khalil Al-Husary",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Husary_128kbps"
        ),
        Reciter(
            id: "sudais",
            nameArabic: "عبد الرحمن السديس",
            nameEnglish: "Abdur-Rahman As-Sudais",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Abdurrahmaan_As-Sudais_192kbps"
        ),
        Reciter(
            id: "shuraim",
            nameArabic: "سعود الشريم",
            nameEnglish: "Saud Ash-Shuraim",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Saood_ash-Shuraym_128kbps"
        ),
        Reciter(
            id: "ghamdi",
            nameArabic: "سعد الغامدي",
            nameEnglish: "Saad Al-Ghamdi",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Ghamadi_40kbps"
        ),
        Reciter(
            id: "dosari",
            nameArabic: "ياسر الدوسري",
            nameEnglish: "Yasser Al-Dosari",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Yasser_Ad-Dussary_128kbps"
        ),
        Reciter(
            id: "maher",
            nameArabic: "ماهر المعيقلي",
            nameEnglish: "Maher Al-Muaiqly",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Maher_AlMuaiqly_64kbps"
        )
    ]
}
