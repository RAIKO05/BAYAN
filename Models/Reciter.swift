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
            return URL(string: "https://everyayah.com/data/warsh/warsh_yassin_al_jazaery_64kbps/\(fullAyahCode).mp3")
        }

        if id == "abdulbasit_warsh" {
            return URL(string: "https://everyayah.com/data/warsh/warsh_Abdul_Basit_128kbps/\(fullAyahCode).mp3")
        }

        if id == "ibrahim_dosari_warsh" {
            return URL(string: "https://everyayah.com/data/warsh/warsh_ibrahim_aldosary_128kbps/\(fullAyahCode).mp3")
        }

        if serverSubdomain.hasPrefix("warsh/") {
            return URL(string: "https://everyayah.com/data/\(serverSubdomain)/\(fullAyahCode).mp3")
        }

        if id == "omardiaa" {
            // Authentic Omar Bn DiaaAldeen (عمر بن ضياء الدين) recitation from Archive.org
            return URL(string: "https://archive.org/download/20240229_20240229_1756/\(surahStr).mp3")
        }

        let urlString = "https://everyayah.com/data/\(serverSubdomain)/\(fullAyahCode).mp3"
        return URL(string: urlString)
    }

    public var sampleAudioUrl: URL? {
        audioUrl(surah: 1, ayah: 1)
    }

    public static let unknownReciter = Reciter(
        id: "unknown",
        nameArabic: "قارئ غير معروف",
        nameEnglish: "Unknown Reciter",
        style: .murattal,
        riwayah: .hafs,
        serverSubdomain: "Alafasy_128kbps"
    )

    // Curated standard reciters catalog (37 world-renowned Qura'a)
    public static let standardCatalog: [Reciter] = [
        // MARK: - User Favorite Reciter: Omar Bn DiaaAldeen
        Reciter(
            id: "omardiaa",
            nameArabic: "عمر بن ضياء الدين",
            nameEnglish: "Omar Bn DiaaAldeen",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Omar_Diaa_Aldeen"
        ),
        // MARK: - Most Popular / Al-Haramain Imams
        Reciter(
            id: "alafasy",
            nameArabic: "مشاري راشد العفاسي",
            nameEnglish: "Mishary Rashid Alafasy",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Alafasy_128kbps"
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
            id: "maher",
            nameArabic: "ماهر المعيقلي",
            nameEnglish: "Maher Al-Muaiqly",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "MaherAlMuaiqly128kbps"
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
            id: "ghamdi",
            nameArabic: "سعد الغامدي",
            nameEnglish: "Saad Al-Ghamdi",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Ghamadi_40kbps"
        ),
        Reciter(
            id: "shatri",
            nameArabic: "أبو بكر الشاطري",
            nameEnglish: "Abu Bakr Ash-Shatri",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Abu_Bakr_Ash-Shaatree_128kbps"
        ),
        Reciter(
            id: "ali_jaber",
            nameArabic: "علي عبد الله جابر",
            nameEnglish: "Ali Jaber",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Ali_Jaber_64kbps"
        ),
        Reciter(
            id: "qatami",
            nameArabic: "ناصر القطامي",
            nameEnglish: "Nasser Al-Qatami",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Nasser_Alqatami_128kbps"
        ),
        Reciter(
            id: "ajamy",
            nameArabic: "أحمد بن علي العجمي",
            nameEnglish: "Ahmed Al-Ajamy",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "ahmed_ibn_ali_al_ajamy_128kbps"
        ),
        Reciter(
            id: "juhany",
            nameArabic: "عبد الله عواد الجهني",
            nameEnglish: "Abdullah Awad Al-Juhany",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Abdullaah_3awwaad_Al-Juhaynee_128kbps"
        ),
        Reciter(
            id: "ayyub",
            nameArabic: "محمد أيوب",
            nameEnglish: "Muhammad Ayyub",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Muhammad_Ayyoub_128kbps"
        ),
        Reciter(
            id: "hudhaify",
            nameArabic: "علي بن عبد الرحمن الحذيفي",
            nameEnglish: "Ali Al-Hudhaify",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Hudhaify_128kbps"
        ),
        Reciter(
            id: "budair",
            nameArabic: "صلاح البدير",
            nameEnglish: "Salah Al-Budair",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Salah_Al_Budair_128kbps"
        ),
        Reciter(
            id: "basfar",
            nameArabic: "عبد الله بصفر",
            nameEnglish: "Abdullah Basfar",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Abdullah_Basfar_192kbps"
        ),
        Reciter(
            id: "fares_abbad",
            nameArabic: "فارس عباد",
            nameEnglish: "Fares Abbad",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Fares_Abbad_64kbps"
        ),
        Reciter(
            id: "hani_rifai",
            nameArabic: "هاني الرفاعي",
            nameEnglish: "Hani Ar-Rifai",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Hani_Rifai_192kbps"
        ),
        Reciter(
            id: "jibreel",
            nameArabic: "محمد جبريل",
            nameEnglish: "Muhammad Jibreel",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Muhammad_Jibreel_128kbps"
        ),
        Reciter(
            id: "bukhatir",
            nameArabic: "صلاح بوخاطر",
            nameEnglish: "Salah Bukhatir",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Salaah_AbdulRahman_Bukhatir_128kbps"
        ),
        Reciter(
            id: "tunaiji",
            nameArabic: "خليفة الطنيجي",
            nameEnglish: "Khalifa Al-Tunaiji",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "khalefa_al_tunaiji_64kbps"
        ),

        // MARK: - Egyptian Classical Masters (Murattal)
        Reciter(
            id: "abdulbasit_murattal",
            nameArabic: "عبد الباسط عبد الصمد (مرتل)",
            nameEnglish: "Abdul Basit (Murattal)",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Abdul_Basit_Murattal_192kbps"
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
            nameArabic: "محمود خليل الحصري (مرتل)",
            nameEnglish: "Mahmoud Khalil Al-Husary (Murattal)",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Husary_128kbps"
        ),
        Reciter(
            id: "tablawi",
            nameArabic: "محمد محمود الطبلاوي",
            nameEnglish: "Mohamed Al-Tablawi",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Mohammad_al_Tablaway_128kbps"
        ),
        Reciter(
            id: "banna",
            nameArabic: "محمود علي البنا",
            nameEnglish: "Mahmoud Ali Al-Banna",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "mahmoud_ali_al_banna_32kbps"
        ),
        Reciter(
            id: "mustafa_ismail",
            nameArabic: "مصطفى إسماعيل",
            nameEnglish: "Mustafa Ismail",
            style: .murattal,
            riwayah: .hafs,
            serverSubdomain: "Mustafa_Ismail_48kbps"
        ),

        // MARK: - Classical Mujawwad Masters
        Reciter(
            id: "abdulbasit_mujawwad",
            nameArabic: "عبد الباسط عبد الصمد (مجود)",
            nameEnglish: "Abdul Basit (Mujawwad)",
            style: .mujawwad,
            riwayah: .hafs,
            serverSubdomain: "Abdul_Basit_Mujawwad_128kbps"
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
            id: "husary_mujawwad",
            nameArabic: "محمود خليل الحصري (مجود)",
            nameEnglish: "Mahmoud Khalil Al-Husary (Mujawwad)",
            style: .mujawwad,
            riwayah: .hafs,
            serverSubdomain: "Husary_128kbps_Mujawwad"
        ),

        // MARK: - Educational & Tajweed Teachers (المصحف المعلم)
        Reciter(
            id: "husary_muallim",
            nameArabic: "محمود خليل الحصري (المصحف المعلم)",
            nameEnglish: "Mahmoud Khalil Al-Husary (Teacher)",
            style: .muallim,
            riwayah: .hafs,
            serverSubdomain: "Husary_Muallim_128kbps"
        ),
        Reciter(
            id: "minshawi_muallim",
            nameArabic: "محمد صديق المنشاوي (المصحف المعلم)",
            nameEnglish: "Mohamed Siddiq Al-Minshawi (Teacher)",
            style: .muallim,
            riwayah: .hafs,
            serverSubdomain: "Minshawy_Teacher_128kbps"
        ),
        Reciter(
            id: "ayman_sowaid",
            nameArabic: "د. أيمن سويد (إتقان التجويد)",
            nameEnglish: "Dr. Ayman Sowaid",
            style: .muallim,
            riwayah: .hafs,
            serverSubdomain: "Ayman_Sowaid_64kbps"
        ),

        // MARK: - Warsh 'an Nafi' (رواية ورش عن نافع)
        Reciter(
            id: "yassin_warsh",
            nameArabic: "ياسين الجزائري (ورش)",
            nameEnglish: "Yassin Al-Jazaery (Warsh)",
            style: .murattal,
            riwayah: .warsh,
            serverSubdomain: "warsh/warsh_yassin_al_jazaery_64kbps"
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
            serverSubdomain: "warsh/warsh_Abdul_Basit_128kbps"
        ),
        Reciter(
            id: "ibrahim_dosari_warsh",
            nameArabic: "إبراهيم الدوسري (ورش)",
            nameEnglish: "Ibrahim Al-Dosari (Warsh)",
            style: .murattal,
            riwayah: .warsh,
            serverSubdomain: "warsh/warsh_ibrahim_aldosary_128kbps"
        )
    ]
}
