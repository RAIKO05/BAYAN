import json

with open("Resources/quran_uthmani.json", "r", encoding="utf-8") as f:
    data = json.load(f)

warsh_data = {}
for surah_id, ayahs in data.items():
    warsh_ayahs = []
    for idx, ayah in enumerate(ayahs):
        w_ayah = ayah
        # Warsh authentic variant readings
        if surah_id == "1" and idx == 3:
            w_ayah = w_ayah.replace("مَٰلِكِ", "مَلِكِ")
        elif surah_id == "2" and idx == 8:
            w_ayah = w_ayah.replace("يُخَٰدِعُونَ", "يَخْدَعُونَ")
        elif surah_id == "2" and idx == 124:
            w_ayah = w_ayah.replace("وَٱتَّخِذُوا", "وَٱتَّخَذُوا")
        elif surah_id == "2" and idx == 131:
            w_ayah = w_ayah.replace("وَأَوْصَىٰ", "وَوَصَّىٰ")
        elif surah_id == "3" and idx == 132:
            w_ayah = w_ayah.replace("وَسَارِعُوٓا۟", "سَارِعُوٓا۟")
        elif surah_id == "3" and idx == 145:
            w_ayah = w_ayah.replace("نُؤْتِهِۦ", "نُوتِهِۦ")
        warsh_ayahs.append(w_ayah)
    warsh_data[surah_id] = warsh_ayahs

with open("Resources/quran_warsh.json", "w", encoding="utf-8") as f:
    json.dump(warsh_data, f, ensure_ascii=False)

print(f"Successfully generated Resources/quran_warsh.json with {len(warsh_data)} surahs.")
