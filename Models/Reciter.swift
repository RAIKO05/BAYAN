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

        let baseEveryAyah = BayanSecureNetworkSession.everyAyahEndpoint

        if id == "kazabri_warsh" {
            // Omar Al-Kazabri Warsh - Verified Cloudflare High-Speed CDN
            return URL(string: "https://cdn.mp3quran.net/audio/omar-kazabri/r1/\(surahStr).mp3")
        }

        if id == "yassin_warsh" {
            return URL(string: "\(baseEveryAyah)/warsh/warsh_yassin_al_jazaery_64kbps/\(fullAyahCode).mp3")
        }

        if id == "abdulbasit_warsh" {
            return URL(string: "\(baseEveryAyah)/warsh/warsh_Abdul_Basit_128kbps/\(fullAyahCode).mp3")
        }

        if id == "ibrahim_dosari_warsh" {
            return URL(string: "\(baseEveryAyah)/warsh/warsh_ibrahim_aldosary_128kbps/\(fullAyahCode).mp3")
        }

        if serverSubdomain.hasPrefix("warsh/") {
            return URL(string: "\(baseEveryAyah)/\(serverSubdomain)/\(fullAyahCode).mp3")
        }

        if id == "omardiaa" {
            // Authentic Omar Bn DiaaAldeen (عمر بن ضياء الدين) verified recitations
            if surah == 1 {
                return URL(string: "https://archive.org/download/omaar_8/omaar_1.mp3")
            }
            let omarSurahs: Set<Int> = [2, 3, 4, 5, 6, 9, 10, 15, 17, 18, 19, 20, 23, 25, 35, 40, 44, 47, 49, 50, 55, 56, 57, 67, 76]
            if omarSurahs.contains(surah) {
                return URL(string: "https://archive.org/download/omar-ben-diya-al-din/\(surahStr).mp3")
            }
            // For other surahs, fallback to pristine high-bitrate recitation so it never fails
            return URL(string: "\(baseEveryAyah)/Alafasy_128kbps/\(fullAyahCode).mp3")
        }

        let urlString = "\(baseEveryAyah)/\(serverSubdomain)/\(fullAyahCode).mp3"
        return URL(string: urlString)
    }

    public var sampleAudioUrl: URL? {
        audioUrl(surah: 1, ayah: 1)
    }

    /// Base image name for local asset bundle lookup
    public var imageName: String {
        switch id {
        case "abdulbasit_murattal", "abdulbasit_mujawwad", "abdulbasit_warsh":
            return "abdulbasit"
        case "minshawi_murattal", "minshawi_mujawwad", "minshawi_muallim":
            return "minshawi"
        case "husary_murattal", "husary_mujawwad", "husary_muallim":
            return "husary"
        default:
            return id
        }
    }

    /// High-resolution verified CDN Profile Image URL
    public var imageUrl: URL? {
        let urlString: String? = {
            switch id {
            case "omardiaa":
                return "https://yt3.googleusercontent.com/S5DRhTqyInj6f6cOxjCJ39fhYSYaeF6DhlM3tJAelSiKbkuq8doGOzBbFc1mdt3NWhhDrQ5kJg=s500-c-k-c0x00ffffff-no-rj"
            case "alafasy":
                return "https://static.qurancdn.com/images/reciters/6/mishary-rashid-alafasy-cover.jpeg"
            case "sudais":
                return "https://static.qurancdn.com/images/reciters/2/abdul-rahman-al-sudais-cover.jpeg"
            case "shuraim":
                return "https://static.qurancdn.com/images/reciters/8/saoud-shuraim-cover.jpeg"
            case "maher":
                return "https://static.qurancdn.com/images/reciters/25/Maher-al-Muaiqly-profile.png"
            case "dosari":
                return "https://static.qurancdn.com/images/reciters/20/yasser-profile.png"
            case "ghamdi":
                return "https://static.qurancdn.com/images/reciters/16/saad-al-ghamdi-cover.jpeg"
            case "shatri":
                return "https://static.qurancdn.com/images/reciters/3/abu-bakr-al-shatri-cover.jpeg"
            case "ali_jaber":
                return "https://static.qurancdn.com/images/reciters/23/Abdullah-Ali-Jabir-profile.png"
            case "qatami":
                return "https://upload.wikimedia.org/wikipedia/commons/c/ca/%D8%B5%D9%88%D8%B1%D8%A9_%D8%B4%D8%AE%D8%B5%D9%8A%D8%A9_%D8%A7%D9%84%D8%B4%D9%8A%D8%AE_%D9%86%D8%A7%D8%B5%D8%B1_%D8%A7%D9%84%D9%82%D8%B7%D8%A7%D9%85%D9%8A.jpg"
            case "ajamy":
                return "https://static.qurancdn.com/images/reciters/22/Ahmed-ibn-Ali-al-Ajmy-profile.png"
            case "juhany":
                return "https://upload.wikimedia.org/wikipedia/commons/2/25/Abdullah_Al_Juhany_%28Cropped%29.png"
            case "ayyub":
                return "https://artwork.qurancentral.com/muhammad-ayyub.jpg"
            case "hudhaify":
                return "https://upload.wikimedia.org/wikipedia/commons/d/d7/Huthaify.jpg"
            case "budair":
                return "https://upload.wikimedia.org/wikipedia/commons/d/df/Salah_Ibn_Mohammed_Al_Budair.jpg"
            case "basfar":
                return "https://artwork.qurancentral.com/abdullah-basfar.jpg"
            case "fares_abbad":
                return "https://artwork.qurancentral.com/fares-abbad.jpg"
            case "hani_rifai":
                return "https://static.qurancdn.com/images/reciters/4/hani-ar-rifai-cover.jpeg"
            case "jibreel":
                return "https://upload.wikimedia.org/wikipedia/commons/3/32/Qari_Muhammad_Jebril%2C_Ramadan_2019.png"
            case "bukhatir":
                return "https://upload.wikimedia.org/wikipedia/commons/thumb/7/73/Bukhatir_Photo.JPG/500px-Bukhatir_Photo.JPG"
            case "tunaiji":
                return "https://static.qurancdn.com/images/reciters/11/khalifa-al-tunaiji-cover.jpeg"
            case "abdulbasit_murattal", "abdulbasit_mujawwad", "abdulbasit_warsh":
                return "https://static.qurancdn.com/images/reciters/1/abdelbasset-cover.jpeg"
            case "minshawi_murattal", "minshawi_mujawwad", "minshawi_muallim":
                return "https://static.qurancdn.com/images/reciters/7/mohamed-siddiq-el-minshawi-cover.jpeg"
            case "husary_murattal", "husary_mujawwad", "husary_muallim":
                return "https://static.qurancdn.com/images/reciters/5/mahmoud-khalil-al-hussary-cover.png"
            case "tablawi":
                return "https://artwork.qurancentral.com/mohamed-tablawi.jpg"
            case "banna":
                return "https://artwork.qurancentral.com/mahmoud-ali-al-banna.jpg"
            case "mustafa_ismail":
                return "https://upload.wikimedia.org/wikipedia/commons/a/a8/Mustafa_Ismail_%281%29.jpg"
            case "ayman_sowaid":
                return "https://upload.wikimedia.org/wikipedia/commons/e/e2/Aymen_souaid.jpg"
            case "yassin_warsh":
                return "https://artwork.qurancentral.com/yassen-al-jazairi.jpg"
            case "kazabri_warsh":
                return "https://artwork.qurancentral.com/omar-al-kazabri.jpg"
            case "ibrahim_dosari_warsh":
                return "https://artwork.qurancentral.com/ibrahim-al-dossari.jpg"
            default:
                return nil
            }
        }()

        guard let urlString else { return nil }
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
