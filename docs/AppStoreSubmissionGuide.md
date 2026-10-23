# 🚀 Bayan (البيان) — Apple App Store & TestFlight Submission Guide

This handbook provides step-by-step instructions for submitting **Bayan** to **Apple TestFlight** and the **Apple App Store**.

---

## 1. App Store Connect Registration

### App Information
* **Primary Language**: English (U.S.) or Arabic
* **Bundle ID**: `com.bayan.app`
* **SKU**: `BAYAN-IOS-01`
* **App Name**: `Bayan: Quran & Prayer Times`
* **Subtitle**: `Audio Identifier, Mushaf & Qibla`
* **Primary Category**: Books / Reference
* **Secondary Category**: Lifestyle / Utilities

---

## 2. Privacy Questionnaire (Nutrition Labels)

Bayan is built with a **100% Privacy-First Architecture**:
* **Data Used to Track You**: **None** (No third-party trackers, no analytics SDKs, no ad networks).
* **Data Linked to You**: **None**.
* **Data Not Linked to You**:
  * **Location**: *Coarse / Approximate Location* (Used exclusively on-device to calculate astronomical solar prayer angles and Qibla bearing. Never transmitted to any server).
  * **Audio Data**: *Microphone Audio* (Used exclusively in real time to generate acoustic hashes for recitation matching and local dictation. Audio is never stored or transmitted to external servers).

---

## 3. TestFlight Configuration

### Internal Testing
1. In [App Store Connect](https://appstoreconnect.apple.com), navigate to **Apps** ➔ **Bayan** ➔ **TestFlight**.
2. Click **Internal Groups** ➔ **+ Add Group** (e.g. `Core Team`).
3. Add your Apple ID email.
4. Upload the signed IPA (`Bayan.ipa`) or use Xcode / GitHub Actions.
5. Internal testers receive an instant email and push notification in the TestFlight app on their iPhone.

### External Beta Testing
1. Create an **External Testing Group** (e.g. `Public Beta Testers`).
2. Add build `1.1.0 (Build 48+)`.
3. Provide **Beta App Review Information**:
   * **Contact Information**: Your support email.
   * **What to Test**:
     > "Please test Quran recitation audio identification in various environments, prayer calculation methods (Habous Morocco, Umm Al-Qura, MWL), authentic Adhan audio alerts, and Siri Shortcuts ('When is Maghrib with Bayan?')."

---

## 4. App Review Notes (For Apple Reviewers)

When submitting for App Review, paste these notes in the **Review Notes** section:

```
Hello Apple Review Team,

Bayan is an ad-free Islamic utility designed for Quran recitation identification, authentic Uthmanic reading, precision prayer times, and Qibla compass direction.

TESTING GUIDANCE:
1. AUDIO RECITATION IDENTIFICATION:
   - Tap the central golden radar orb on the main tab.
   - Play any recitation of the Quran (e.g., search "Surah Ar-Rahman Mishary Alafasy" or "Surah Al-Fatihah" on another device or speaker).
   - Bayan will match the recitation within seconds and present the recognized Surah card.
   - Alternatively, tap "Type or Search Verse Text" to test the manual instant fuzzy search.

2. PRAYER TIMES & ADHAN AUDIO:
   - Navigate to the "Prayers" tab.
   - Tap the gear icon to view calculation conventions (Morocco Habous, Umm Al-Qura, MWL, ISNA, Egyptian).
   - Tap "Play Authentic Adhan Audio" to preview the bundled high-fidelity call to prayer.
   - Toggle "Adhan Audio Notifications" to schedule daily alerts with 15-minute advance preparation reminders.

3. SIRI SHORTCUTS:
   - In Siri or the Shortcuts app, speak:
     * "When is Maghrib with Bayan?"
     * "When is next prayer in Bayan?"
     * "Where is the Qibla in Bayan?"
     * "Identify Quran with Bayan"

4. LOGIN CREDENTIALS:
   - No login or user account is required. The app is fully functional upon launch with zero registration.

Thank you!
```

---

## 5. Automated CI/CD TestFlight Upload via GitHub Actions

To enable 1-click automated upload from GitHub Actions to TestFlight:
1. In App Store Connect, generate an **App Store Connect API Key** under **Users and Access** ➔ **Integrations** ➔ **App Store Connect API**.
2. Note the **Key ID**, **Issuer ID**, and download the `.p8` private key file.
3. In your GitHub repository settings (`RAIKO05/BAYAN`), navigate to **Secrets and variables** ➔ **Actions**, and add:
   * `APP_STORE_CONNECT_KEY_ID`: Your Key ID
   * `APP_STORE_CONNECT_ISSUER_ID`: Your Issuer ID
   * `APP_STORE_CONNECT_PRIVATE_KEY`: Content of the `.p8` file
4. With these secrets configured, GitHub Actions will automatically upload every tagged release directly into TestFlight!
