# Bayan (بَيَان) — Shazam for Holy Qur'an 🎙️📖

> *"This [Qur'an] is a clear statement (بَيَان) to mankind"* — Surah Ali 'Imran (3:138)

**Bayan** is a native iOS application combining **Shazam-style Quranic recitation recognition** with a **full Holy Quran Mushaf (114 Surahs)**, over 100+ reciters (القُرّاء), and smart **"Where I stopped" sync**.

---

## 🌟 Key Features

1. **Acoustic Recitation Identifier**:
   - 1-Tap pulsating radar orb with dynamic audio wave animations.
   - Identifies the Surah, Ayah range, and Reciter (Qari) with Tajweed and acoustic signature matching.
   - Instant audio playback and verse snippet with Uthmanic Arabic typography.

2. **Full Holy Quran (Mushaf)**:
   - Complete 114 Surahs catalog with Meccan/Medinan tags, English translations, and starting pages.
   - Verse-by-verse reader with synchronized audio playback and repeat mode.

3. **100+ Qura'a Catalog (القُرّاء)**:
   - Stream or download recitations by Sheikh Mishary Rashid Alafasy, Abdul Basit (Mujawwad & Murattal), Mohamed Siddiq Al-Minshawi, Mahmoud Khalil Al-Husary, Abdur-Rahman As-Sudais, and more.
   - Supports multiple Riwayahs: **Hafs 'an 'Asim (حَفْص)**, **Warsh 'an Nafi' (وَرْش)**, **Qalun (قَالُون)**.

4. **"Where I Stopped" Smart Sync**:
   - Automatically tracks your exact reading position (Surah, Ayah, page, and audio playhead).
   - "Continue Reading" banner to resume with one tap.

5. **iOS 18 Control Center & Widgets**:
   - 1-Tap **Control Center** button (`ControlWidget`) to identify recitations from anywhere.
   - Siri Shortcuts: *"Hey Siri, identify this Surah with Bayan"*.
   - Lock Screen and Home Screen interactive widgets.

---

## 🚀 Cloud Build via GitHub Actions (No Mac Needed!)

This repository includes a GitHub Actions workflow (`.github/workflows/build-ios.yml`) that builds `Bayan.ipa` automatically on free GitHub macOS runners.

### How to Install on iPhone:
1. Push this repository to your GitHub account.
2. Go to the **Actions** tab on GitHub and click on the latest **Build iOS App (Bayan)** run.
3. Download the **`Bayan-iOS-App`** artifact (contains `Bayan.ipa`).
4. On your Windows PC, install **[Sideloadly](https://sideloadly.io/)** (Free).
5. Plug your iPhone into your PC via USB cable, drag `Bayan.ipa` into Sideloadly, enter your Apple ID, and click **Start**!
6. Open **Settings > General > VPN & Device Management** on your iPhone and tap **Trust**.
7. Enjoy Bayan on your iPhone!
