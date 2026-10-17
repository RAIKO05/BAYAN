# Bayan (بَيَان) — Shazam for Holy Qur'an 🎙️📖

> *"This [Qur'an] is a clear statement (بَيَان) to mankind"* — Surah Ali 'Imran (3:138)

**Bayan** is a native iOS application combining **Shazam-style Quranic recitation recognition** with a **full Holy Quran Mushaf (114 Surahs)**, **live GPS Qibla compass**, **interactive Adkar & Tasbih**, over 100+ reciters (القُرّاء), and smart **"Where I stopped" sync**.

---

## 🌟 Key Features

1. **Acoustic Recitation Identifier**:
   - 1-Tap pulsating radar orb with dynamic audio wave animations.
   - Dual-Engine recognition: Live Apple `ShazamKit` streaming + real acoustic correlation without simulated or mock data.
   - Instant audio playback and verse snippet with authentic Uthmanic Arabic typography and English translations.

2. **Full Holy Quran (Mushaf)**:
   - Complete 114 Surahs catalog with Meccan/Medinan tags, English translations, and starting pages.
   - Verse-by-verse reader with synchronized audio playback and repeat mode.
   - Offline bundled complete Arabic Uthmanic text (6,236 Ayahs) and English translation.

3. **Live GPS Qibla Compass (اتِّجَاهُ الْقِبْلَةِ)**:
   - Real-time magnetic and true-north heading calculation using `CoreLocation`.
   - Spherical great-circle bearing and distance calculation directly to the Holy Kaaba in Makkah (21.4225° N, 39.8262° E).
   - Dynamic location detection with live GPS coordinates and preset major cities worldwide.
   - Real-time alignment haptic feedback when aligned within 3° of the Kaaba.

4. **Adkar & Digital Tasbih (أَذْكَارُ الْمُسْلِمِ)**:
   - Morning Dhikr (أَذْكَارُ الصَّبَاحِ), Evening Dhikr (أَذْكَارُ الْمَسَاءِ), and Post-Prayer Dhikr (أَذْكَارُ بَعْدَ الصَّلَاةِ).
   - Interactive haptic counter with progressive circular rings and completion states.

5. **100+ Qura'a Catalog (القُرّاء)**:
   - Stream recitations by Sheikh Mishary Rashid Alafasy, Abdul Basit (Mujawwad & Murattal), Mohamed Siddiq Al-Minshawi, Mahmoud Khalil Al-Husary, Abdur-Rahman As-Sudais, and more.
   - Supports multiple Riwayahs: **Hafs 'an 'Asim (حَفْص)**, **Warsh 'an Nafi' (وَرْش)**, **Qalun (قَالُون)**.

6. **"Where I Stopped" Smart Sync**:
   - Automatically tracks your exact reading position (Surah, Ayah, page, and audio playhead).
   - "Continue Reading" banner to resume with one tap.

7. **iOS 18 Control Center & Widgets**:
   - 1-Tap **Control Center** button (`ControlWidget`) to identify recitations from anywhere.
   - Siri Shortcuts: *"Hey Siri, identify this Surah with Bayan"*.
   - Lock Screen and Home Screen interactive widgets (`WidgetKit`).

---

## 🚀 Deployment & Installation

### Option A: Cloud CI Build via GitHub Actions (No Mac Needed!)

This repository includes a GitHub Actions workflow (`.github/workflows/build-ios.yml`) that automatically compiles and packages `Bayan.ipa` on GitHub's macOS Sequoia (`macos-15`) runners:

1. Push this repository to your GitHub repository:
   ```bash
   git push origin main
   ```
2. Navigate to your repository's **Actions** tab on GitHub:
   `https://github.com/RAIKO05/BAYAN/actions`
3. Click on the active or latest **Build iOS App (Bayan)** workflow run.
4. Once completed, download the **`Bayan-iOS-App`** artifact zip containing `Bayan.ipa`.
5. Sideload onto your iPhone using **[Sideloadly](https://sideloadly.io/)** (Windows/Mac) or **[AltStore](https://altstore.io/)**:
   - Plug iPhone into PC via USB cable.
   - Drag `Bayan.ipa` into Sideloadly.
   - Enter your Apple ID and click **Start**.
   - On your iPhone, go to **Settings > General > VPN & Device Management** and tap **Trust**.

---

### Option B: Local Build & App Store / TestFlight Submission (via Mac)

If you have a Mac with Xcode 15 or 16:

1. Clone the repository and install XcodeGen:
   ```bash
   brew install xcodegen
   ```
2. Generate the native Xcode project:
   ```bash
   xcodegen generate
   ```
3. Open `Bayan.xcodeproj` in Xcode:
   ```bash
   open Bayan.xcodeproj
   ```
4. Select the **Bayan** target > **Signing & Capabilities**:
   - Select your **Apple Developer Team**.
   - Ensure the Bundle Identifier is set (`tools.rea.Bayan`).
5. In Xcode menu, choose **Product > Destination > Any iOS Device (arm64)**.
6. Select **Product > Archive**.
7. In the Organizer window, click **Distribute App** > **TestFlight & App Store** > **Upload**!

