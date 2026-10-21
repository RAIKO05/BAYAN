import Foundation

public final class HisnAlMuslimDataService {
    public static let shared = HisnAlMuslimDataService()

    public let allAdhkar: [DhikrItem]

    private init() {
        self.allAdhkar = HisnAlMuslimDataService.loadCuratedAdhkar()
    }

    public func adhkar(for category: DhikrCategory) -> [DhikrItem] {
        allAdhkar.filter { $0.category == category }
    }

    private static func loadCuratedAdhkar() -> [DhikrItem] {
        return [
            // MARK: - Morning Adhkar (أذكار الصباح)
            DhikrItem(
                id: "m_ayat_kursi",
                category: .morning,
                arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ",
                transliteration: "Allahu la ilaha illa Huwa, Al-Hayyul-Qayyum. La ta'khudhuhu sinatun wa la nawm...",
                translation: "Allah! There is no deity except Him, the Ever-Living, the Sustainer of all existence. Neither drowsiness overtakes Him nor sleep...",
                targetCount: 1,
                reference: "Surah Al-Baqarah 2:255 • Sahih al-Hakim",
                virtue: "Whoever recites it in the morning will be protected from jinn until evening."
            ),
            DhikrItem(
                id: "m_sayyid_istighfar",
                category: .morning,
                arabicText: "اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ لَكَ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ إِلَّا أَنْتَ",
                transliteration: "Allahumma Anta Rabbi la ilaha illa Anta, khalaqtani wa ana 'abduka, wa ana 'ala 'ahdika wa wa'dika mastata'tu...",
                translation: "O Allah, You are my Lord; there is none worthy of worship except You. You created me and I am Your servant, and I abide by Your covenant and promise as best I can...",
                targetCount: 1,
                reference: "Sahih al-Bukhari (6306)",
                virtue: "The Master of Seeking Forgiveness. Whoever recites it during the day with firm faith and dies before evening will be among the people of Paradise."
            ),
            DhikrItem(
                id: "m_asbahna",
                category: .morning,
                arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذَا الْيَوْمِ وَخَيْرَ مَا بَعْدَهُ، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذَا الْيَوْمِ وَشَرِّ مَا بَعْدَهُ",
                transliteration: "Asbahna wa-asbahal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la shareeka lah...",
                translation: "We have entered the morning and kingdom belongs to Allah, and all praise is for Allah. None has the right to be worshipped except Allah alone, without partner...",
                targetCount: 1,
                reference: "Sahih Muslim (2723)",
                virtue: "Comprehensive supplication acknowledging Allah's sovereignty and seeking the day's goodness."
            ),
            DhikrItem(
                id: "m_bismillah_ladhi",
                category: .morning,
                arabicText: "بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ",
                transliteration: "Bismillahil-ladhi la yadurru ma'as-mihi shay'un fil-ardi wa la fis-sama'i wa Huwas-Sami'ul-'Alim.",
                translation: "In the Name of Allah, with Whose Name nothing can cause harm in the earth nor in the heavens, and He is the All-Hearing, the All-Knowing.",
                targetCount: 3,
                reference: "Sunan Abi Dawood (5088) • Jami` at-Tirmidhi (3388)",
                virtue: "Whoever says it three times in the morning and evening, nothing shall harm them."
            ),
            DhikrItem(
                id: "m_raditu_billah",
                category: .morning,
                arabicText: "رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا",
                transliteration: "Radeetu billahi Rabban, wa bil-Islami deenan, wa bi-Muhammadin sallallahu 'alayhi wa sallama Nabiyya.",
                translation: "I am pleased with Allah as my Lord, with Islam as my religion, and with Muhammad (ﷺ) as my Prophet.",
                targetCount: 3,
                reference: "Sunan Abi Dawood (5072) • Musnad Ahmad",
                virtue: "Whoever recites it three times morning and evening, Allah has promised to please them on the Day of Resurrection."
            ),
            DhikrItem(
                id: "m_subhan_wa_bihamdihi_100",
                category: .morning,
                arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
                transliteration: "Subhanallahi wa bihamdih.",
                translation: "Glory be to Allah and all praise is His.",
                targetCount: 100,
                reference: "Sahih Muslim (2691)",
                virtue: "Whoever recites it one hundred times a day, their sins will be wiped away even if they were like the foam of the sea."
            ),

            // MARK: - Evening Adhkar (أذكار المساء)
            DhikrItem(
                id: "e_amsayna",
                category: .evening,
                arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ. رَبِّ أَسْأَلُكَ خَيْرَ مَا فِي هَذِهِ اللَّيْلَةِ وَخَيْرَ مَا بَعْدَهَا، وَأَعُوذُ بِكَ مِنْ شَرِّ مَا فِي هَذِهِ اللَّيْلَةِ وَشَرِّ مَا بَعْدَهَا",
                transliteration: "Amsayna wa-amsal-mulku lillah, walhamdu lillah, la ilaha illallahu wahdahu la shareeka lah...",
                translation: "We have reached the evening and the dominion belongs to Allah. Praise be to Allah. None has the right to be worshipped except Allah alone...",
                targetCount: 1,
                reference: "Sahih Muslim (2723)",
                virtue: "Guarantees safety and Divine protection for the entirety of the night."
            ),
            DhikrItem(
                id: "e_a'udhu_bikalimatillah",
                category: .evening,
                arabicText: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
                transliteration: "A'udhu bikalimatil-lahit-tammati min sharri ma khalaq.",
                translation: "I seek refuge in the perfect words of Allah from the evil of that which He has created.",
                targetCount: 3,
                reference: "Sahih Muslim (2709)",
                virtue: "Whoever recites it three times in the evening, no poisonous sting or harm shall touch them that night."
            ),
            DhikrItem(
                id: "e_ikhlos_muawwidhatayn",
                category: .evening,
                arabicText: "قُلْ هُوَ اللَّهُ أَحَدٌ ۝ قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ قُلْ أَعُوذُ بِرَبِّ النَّاسِ",
                transliteration: "Surat Al-Ikhlas, Surat Al-Falaq, Surat An-Nas (Recite each 3 times)",
                translation: "Say: He is Allah, the One... Say: I seek refuge in the Lord of daybreak... Say: I seek refuge in the Lord of mankind...",
                targetCount: 3,
                reference: "Sunan Abi Dawood (5082) • Jami` at-Tirmidhi (3575)",
                virtue: "Reciting them three times morning and evening suffices you against everything."
            ),

            // MARK: - Before Sleep (أذكار النوم)
            DhikrItem(
                id: "s_bismika_rabbi",
                category: .sleep,
                arabicText: "بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ، إِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ",
                transliteration: "Bismika Rabbi wada'tu janbi wa bika arfa'uh, in amsakta nafsi farhamha, wa in arsaltaha fahfazha...",
                translation: "In Your Name, my Lord, I lay down my side and in Your Name I raise it. If You take my soul, have mercy upon it, and if You return it, protect it...",
                targetCount: 1,
                reference: "Sahih al-Bukhari (6320) • Sahih Muslim (2714)",
                virtue: "Sunnah when retiring to bed; entrusts the soul to Allah's divine keeping."
            ),
            DhikrItem(
                id: "s_tasbih_fatimah",
                category: .sleep,
                arabicText: "سُبْحَانَ اللَّهِ (٣٣) ، وَالْحَمْدُ لِلَّهِ (٣٣) ، وَاللَّهُ أَكْبَرُ (٣٤)",
                transliteration: "SubhanAllah (33x), Alhamdulillah (33x), Allahu Akbar (34x)",
                translation: "Glory be to Allah (33 times), Praise be to Allah (33 times), Allah is the Greatest (34 times).",
                targetCount: 33,
                reference: "Sahih al-Bukhari (3705) • Sahih Muslim (2727)",
                virtue: "Taught by the Prophet (ﷺ) to Ali and Fatimah (RA); better than having a servant and grants divine strength."
            ),

            // MARK: - Post-Prayer (أذكار بعد الصلاة)
            DhikrItem(
                id: "p_astaghfirullah_3",
                category: .postPrayer,
                arabicText: "أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ، أَسْتَغْفِرُ اللَّهَ. اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ",
                transliteration: "Astaghfirullah (3x). Allahumma Antas-Salamu wa minkas-salam, tabarakta ya Dhal-Jalali wal-Ikram.",
                translation: "I seek Allah's forgiveness (3 times). O Allah, You are Peace and from You comes peace. Blessed are You, O Owner of majesty and honor.",
                targetCount: 1,
                reference: "Sahih Muslim (591)",
                virtue: "The first remembrance recited immediately upon concluding the fardh prayer."
            ),
            DhikrItem(
                id: "p_tasbih_33",
                category: .postPrayer,
                arabicText: "سُبْحَانَ اللَّهِ (٣٣) ، الْحَمْدُ لِلَّهِ (٣٣) ، اللَّهُ أَكْبَرُ (٣٣) ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
                transliteration: "SubhanAllah (33x), Alhamdulillah (33x), Allahu Akbar (33x), La ilaha illallahu wahdahu la shareeka lah...",
                translation: "Glory be to Allah (33), Praise be to Allah (33), Allah is Greatest (33), followed by 'None has the right to be worshipped except Allah alone...'",
                targetCount: 33,
                reference: "Sahih Muslim (597)",
                virtue: "Whoever says this after every prayer will have their sins forgiven even if they were like the foam of the sea."
            ),

            // MARK: - Quranic Duas (أدعية قرآنية)
            DhikrItem(
                id: "q_rabbana_atina",
                category: .quranic,
                arabicText: "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
                transliteration: "Rabbana atina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina 'adhaban-nar.",
                translation: "Our Lord! Grant us that which is good in this world and that which is good in the Hereafter, and save us from the torment of the Fire.",
                targetCount: 3,
                reference: "Surah Al-Baqarah 2:201 • Sahih al-Bukhari",
                virtue: "The most frequent supplication of Prophet Muhammad (ﷺ)."
            ),
            DhikrItem(
                id: "q_rabbi_ishrah",
                category: .quranic,
                arabicText: "رَبِّ اشْرَحْ لِي صَدْرِي ۝ وَيَسِّرْ لِي أَمْرِي ۝ وَاحْلُلْ عُقْدَةً مِّن لِّسَانِي ۝ يَفْقَهُوا قَوْلِي",
                transliteration: "Rabbish-rah li sadri, wa yassir li amri, wahlul 'uqdatan min lisani, yafqahu qawli.",
                translation: "My Lord! Expand for me my chest, and ease for me my task, and untie the knot from my tongue, that they may understand my speech.",
                targetCount: 1,
                reference: "Surah Ta-Ha 20:25-28",
                virtue: "Du'a of Prophet Musa (AS) for peace of mind, ease of hardship, and eloquence."
            ),
            DhikrItem(
                id: "q_rabbi_zidni_ilma",
                category: .quranic,
                arabicText: "رَبِّ زِدْنِي عِلْمًا",
                transliteration: "Rabbi zidni 'ilma.",
                translation: "My Lord, increase me in knowledge.",
                targetCount: 3,
                reference: "Surah Ta-Ha 20:114",
                virtue: "The only du'a where Allah commanded the Prophet (ﷺ) to ask for an increase in something."
            ),

            // MARK: - Protection & Ruqyah (أدعية الحفظ والشفاء)
            DhikrItem(
                id: "pr_hasbi_allahu",
                category: .protection,
                arabicText: "حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ",
                transliteration: "Hasbiyallahu la ilaha illa Huwa, 'alayhi tawakkaltu wa Huwa Rabbul-'Arshil-'Azeem.",
                translation: "Allah is sufficient for me. There is no deity except Him. Upon Him I have relied, and He is the Lord of the Great Throne.",
                targetCount: 7,
                reference: "Surah At-Tawbah 9:129 • Sunan Abi Dawood (5081)",
                virtue: "Whoever recites it seven times morning and evening, Allah will suffice them against whatever concerns them."
            ),
            DhikrItem(
                id: "pr_audhu_bikalimat",
                category: .protection,
                arabicText: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّةِ مِنْ كُلِّ شَيْطَانٍ وَهَامَّةٍ وَمِنْ كُلِّ عَيْنٍ لَامَّةٍ",
                transliteration: "A'udhu bikalimatil-lahit-tammati min kulli shaytanin wa hammah, wa min kulli 'aynin lammah.",
                translation: "I seek refuge in the perfect words of Allah from every devil and poisonous reptile, and from every evil eye.",
                targetCount: 3,
                reference: "Sahih al-Bukhari (3371)",
                virtue: "The supplication Ibrahim (AS) made for Ismail and Ishaq, and the Prophet (ﷺ) made for Al-Hasan and Al-Husain."
            )
        ]
    }
}
