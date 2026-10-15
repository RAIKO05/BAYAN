#!/usr/bin/env node

/**
 * Bayan (بَيَان) - Quran Audio Reference Downloader (Node.js)
 * Downloads reference audio clips from the EveryAyah CDN for popular reciters
 * to generate the ShazamKit custom catalog (.shazamcatalog).
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const RECITERS = [
  {
    id: "alafasy",
    name_english: "Mishary Rashid Alafasy",
    name_arabic: "مشاري راشد العفاسي",
    cdn_folder: "Alafasy_128kbps",
    riwayah: "Hafs 'an 'Asim"
  },
  {
    id: "abdulbasit_mujawwad",
    name_english: "Abdul Basit (Mujawwad)",
    name_arabic: "عبد الباسط عبد الصمد (مجود)",
    cdn_folder: "Abdul_Basit_Mujawwad_128kbps",
    riwayah: "Hafs 'an 'Asim"
  },
  {
    id: "minshawi_murattal",
    name_english: "Mohamed Siddiq Al-Minshawi",
    name_arabic: "محمد صديق المنشاوي",
    cdn_folder: "Minshawy_Murattal_128kbps",
    riwayah: "Hafs 'an 'Asim"
  },
  {
    id: "husary_murattal",
    name_english: "Mahmoud Khalil Al-Husary",
    name_arabic: "محمود خليل الحصري",
    cdn_folder: "Husary_128kbps",
    riwayah: "Hafs 'an 'Asim"
  },
  {
    id: "sudais",
    name_english: "Abdur-Rahman As-Sudais",
    name_arabic: "عبد الرحمن السديس",
    cdn_folder: "Abdurrahmaan_As-Sudais_192kbps",
    riwayah: "Hafs 'an 'Asim"
  }
];

const SAMPLE_SURAHS = [
  { id: 1, name_english: "Al-Fatihah", name_arabic: "الفاتحة", ayahs: 7 },
  { id: 18, name_english: "Al-Kahf", name_arabic: "الكهف", ayahs: 10 },
  { id: 36, name_english: "Ya-Sin", name_arabic: "يس", ayahs: 12 },
  { id: 55, name_english: "Ar-Rahman", name_arabic: "الرحمن", ayahs: 16 },
  { id: 67, name_english: "Al-Mulk", name_arabic: "الملك", ayahs: 10 },
  { id: 112, name_english: "Al-Ikhlas", name_arabic: "الإخلاص", ayahs: 4 },
  { id: 113, name_english: "Al-Falaq", name_arabic: "الفلق", ayahs: 5 },
  { id: 114, name_english: "An-Nas", name_arabic: "الناس", ayahs: 6 }
];

async function downloadFile(url, destPath) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`HTTP ${response.status} ${response.statusText}`);
  const arrayBuffer = await response.arrayBuffer();
  fs.writeFileSync(destPath, Buffer.from(arrayBuffer));
}

async function main() {
  const outputDir = path.join(__dirname, "reference_audio");
  fs.mkdirSync(outputDir, { recursive: true });

  const manifest = [];

  console.log("==================================================");
  console.log(" Bayan — Quran Reference Audio Downloader");
  console.log("==================================================");

  for (const reciter of RECITERS) {
    console.log(`\n📥 Preparing reciter: ${reciter.name_english} (${reciter.name_arabic})`);
    const reciterDir = path.join(outputDir, reciter.id);
    fs.mkdirSync(reciterDir, { recursive: true });

    for (const surah of SAMPLE_SURAHS) {
      const surahStr = String(surah.id).padStart(3, "0");
      const ayahStr = "001";
      const filename = `${surahStr}${ayahStr}.mp3`;
      const targetPath = path.join(reciterDir, filename);
      const url = `https://everyayah.com/data/${reciter.cdn_folder}/${filename}`;

      manifest.push({
        surah_id: surah.id,
        surah_name_english: surah.name_english,
        surah_name_arabic: surah.name_arabic,
        reciter_id: reciter.id,
        reciter_name: reciter.name_english,
        riwayah: reciter.riwayah,
        file_path: path.relative(__dirname, targetPath),
        url
      });

      if (!fs.existsSync(targetPath)) {
        process.stdout.write(`  Downloading ${surah.name_english} (Ayah 1)... `);
        try {
          await downloadFile(url, targetPath);
          console.log("✓ Done");
        } catch (err) {
          console.log(`⚠️ Failed: ${err.message}`);
        }
      } else {
        console.log(`  ✓ Already exists: ${filename}`);
      }
    }
  }

  const manifestPath = path.join(__dirname, "catalog_manifest.json");
  fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), "utf8");

  console.log(`\n🎉 Done! Manifest written to: ${manifestPath}`);
  console.log(`Total reference clips prepared: ${manifest.length}`);
}

main().catch(err => {
  console.error("Fatal error:", err);
  process.exit(1);
});
