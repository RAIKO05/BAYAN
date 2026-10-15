#!/usr/bin/env python3
"""
Bayan (بَيَان) - Quran Audio Reference Downloader
Downloads reference audio clips from the EveryAyah CDN for popular reciters
to generate the ShazamKit custom catalog (.shazamcatalog).
"""

import os
import json
import urllib.request

RECITERS = [
    {
        "id": "alafasy",
        "name_english": "Mishary Rashid Alafasy",
        "name_arabic": "مشاري راشد العفاسي",
        "cdn_folder": "Alafasy_128kbps",
        "riwayah": "Hafs 'an 'Asim"
    },
    {
        "id": "abdulbasit_mujawwad",
        "name_english": "Abdul Basit (Mujawwad)",
        "name_arabic": "عبد الباسط عبد الصمد (مجود)",
        "cdn_folder": "Abdul_Basit_Mujawwad_128kbps",
        "riwayah": "Hafs 'an 'Asim"
    },
    {
        "id": "minshawi_murattal",
        "name_english": "Mohamed Siddiq Al-Minshawi",
        "name_arabic": "محمد صديق المنشاوي",
        "cdn_folder": "Minshawy_Murattal_128kbps",
        "riwayah": "Hafs 'an 'Asim"
    },
    {
        "id": "husary_murattal",
        "name_english": "Mahmoud Khalil Al-Husary",
        "name_arabic": "محمود خليل الحصري",
        "cdn_folder": "Husary_128kbps",
        "riwayah": "Hafs 'an 'Asim"
    },
    {
        "id": "sudais",
        "name_english": "Abdur-Rahman As-Sudais",
        "name_arabic": "عبد الرحمن السديس",
        "cdn_folder": "Abdurrahmaan_As-Sudais_192kbps",
        "riwayah": "Hafs 'an 'Asim"
    }
]

# Sample priority Surahs for initial catalog signature building
SAMPLE_SURAHS = [
    {"id": 1, "name_english": "Al-Fatihah", "name_arabic": "الفاتحة", "ayahs": 7},
    {"id": 18, "name_english": "Al-Kahf", "name_arabic": "الكهف", "ayahs": 10}, # First 10 ayahs
    {"id": 36, "name_english": "Ya-Sin", "name_arabic": "يس", "ayahs": 12},
    {"id": 55, "name_english": "Ar-Rahman", "name_arabic": "الرحمن", "ayahs": 16},
    {"id": 67, "name_english": "Al-Mulk", "name_arabic": "الملك", "ayahs": 10},
    {"id": 112, "name_english": "Al-Ikhlas", "name_arabic": "الإخلاص", "ayahs": 4},
    {"id": 113, "name_english": "Al-Falaq", "name_arabic": "الفلق", "ayahs": 5},
    {"id": 114, "name_english": "An-Nas", "name_arabic": "الناس", "ayahs": 6}
]

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(base_dir, "reference_audio")
    os.makedirs(output_dir, exist_ok=True)

    manifest = []

    print("==================================================")
    print(" Bayan — Quran Reference Audio Downloader")
    print("==================================================")

    for reciter in RECITERS:
        print(f"\n📥 Preparing reciter: {reciter['name_english']} ({reciter['name_arabic']})")
        reciter_dir = os.path.join(output_dir, reciter["id"])
        os.makedirs(reciter_dir, exist_ok=True)

        for surah in SAMPLE_SURAHS:
            surah_str = f"{surah['id']:03d}"
            # Download first Ayah of each sample Surah as reference
            ayah_str = "001"
            filename = f"{surah_str}{ayah_str}.mp3"
            target_path = os.path.join(reciter_dir, filename)
            url = f"https://everyayah.com/data/{reciter['cdn_folder']}/{filename}"

            entry = {
                "surah_id": surah["id"],
                "surah_name_english": surah["name_english"],
                "surah_name_arabic": surah["name_arabic"],
                "reciter_id": reciter["id"],
                "reciter_name": reciter["name_english"],
                "riwayah": reciter["riwayah"],
                "file_path": os.path.relpath(target_path, base_dir),
                "url": url
            }
            manifest.append(entry)

            if not os.path.exists(target_path):
                print(f"  Downloading Surah {surah['name_english']} (Ayah 1)...")
                try:
                    urllib.request.urlretrieve(url, target_path)
                except Exception as e:
                    print(f"  ⚠️ Could not download {url}: {e}")
            else:
                print(f"  ✓ Already downloaded: {filename}")

    manifest_path = os.path.join(base_dir, "catalog_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    print(f"\n🎉 Done! Manifest written to: {manifest_path}")
    print(f"Total audio reference clips ready: {len(manifest)}")

if __name__ == "__main__":
    main()
