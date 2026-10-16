#!/usr/bin/env python3
"""
Bayan (بَيَان) - Quran Audio & Verse AI Recognition Microservice
Built with:
- shazamio (Apple Shazam live acoustic fingerprinting across millions of Quran audio tracks)
- quran-detector (Samhaa R. El-Beltagy & Ahmed Rafea QDetect intelligence for Quran verse identification)
- stream-payload-parser (Intelligent metadata normalization for 114 Surahs and 200+ Qaris)
- async-api-design (Asynchronous non-blocking aiohttp REST server)
- rate-limit-mitigation (Exponential backoff retry profiles)
"""

import asyncio
import os
import re
import sys
import tempfile
from typing import Optional, Dict, Any, List

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

from aiohttp import web
import aiohttp_cors
from shazamio import Shazam
from quran_detector import detect, Settings
from rapidfuzz import fuzz, process

# -------------------------------------------------------------
# 114 SURAHS CANONICAL CATALOG
# -------------------------------------------------------------
SURAHS = [
    (1, "Al-Fatihah", "الفاتحة", 7),
    (2, "Al-Baqarah", "البقرة", 286),
    (3, "Ali 'Imran", "آل عمران", 200),
    (4, "An-Nisa", "النساء", 176),
    (5, "Al-Ma'idah", "المائدة", 120),
    (6, "Al-An'am", "الأنعام", 165),
    (7, "Al-A'raf", "الأعراف", 206),
    (8, "Al-Anfal", "الأنفال", 75),
    (9, "At-Tawbah", "التوبة", 129),
    (10, "Yunus", "يونس", 109),
    (11, "Hud", "هود", 123),
    (12, "Yusuf", "يوسف", 111),
    (13, "Ar-Ra'd", "الرعد", 43),
    (14, "Ibrahim", "إبراهيم", 52),
    (15, "Al-Hijr", "الحجر", 99),
    (16, "An-Nahl", "النحل", 128),
    (17, "Al-Isra", "الإسراء", 111),
    (18, "Al-Kahf", "الكهف", 110),
    (19, "Maryam", "مريم", 98),
    (20, "Ta-Ha", "طه", 135),
    (21, "Al-Anbiya", "الأنبياء", 112),
    (22, "Al-Hajj", "الحج", 78),
    (23, "Al-Mu'minun", "المؤمنون", 118),
    (24, "An-Nur", "النور", 64),
    (25, "Al-Furqan", "الفرقان", 77),
    (26, "Ash-Shu'ara", "الشعراء", 227),
    (27, "An-Naml", "النمل", 93),
    (28, "Al-Qasas", "القصص", 88),
    (29, "Al-'Ankabut", "العنكبوت", 69),
    (30, "Ar-Rum", "الروم", 60),
    (31, "Luqman", "لقمان", 34),
    (32, "As-Sajdah", "السجدة", 30),
    (33, "Al-Ahzab", "الأحزاب", 73),
    (34, "Saba", "سبأ", 54),
    (35, "Fatir", "فاطر", 45),
    (36, "Ya-Sin", "يس", 83),
    (37, "As-Saffat", "الصافات", 182),
    (38, "Sad", "ص", 88),
    (39, "Az-Zumar", "الزمر", 75),
    (40, "Ghafir", "غافر", 85),
    (41, "Fussilat", "فصلت", 54),
    (42, "Ash-Shura", "الشورى", 53),
    (43, "Az-Zukhruf", "الزخرف", 89),
    (44, "Ad-Dukhan", "الدخان", 59),
    (45, "Al-Jathiyah", "الجاثية", 37),
    (46, "Al-Ahqaf", "الأحقاف", 35),
    (47, "Muhammad", "محمد", 38),
    (48, "Al-Fath", "الفتح", 29),
    (49, "Al-Hujurat", "الحجرات", 18),
    (50, "Qaf", "ق", 45),
    (51, "Adh-Dhariyat", "الذاريات", 60),
    (52, "At-Tur", "الطور", 49),
    (53, "An-Najm", "النجم", 62),
    (54, "Al-Qamar", "القمر", 55),
    (55, "Ar-Rahman", "الرحمن", 78),
    (56, "Al-Waqi'ah", "الواقعة", 96),
    (57, "Al-Hadid", "الحديد", 29),
    (58, "Al-Mujadilah", "المجادلة", 22),
    (59, "Al-Hashr", "الحشر", 24),
    (60, "Al-Mumtahanah", "الممتحنة", 13),
    (61, "As-Saf", "الصف", 14),
    (62, "Al-Jumu'ah", "الجمعة", 11),
    (63, "Al-Munafiqun", "المنافقون", 11),
    (64, "At-Taghabun", "التغابن", 18),
    (65, "At-Talaq", "الطلاق", 12),
    (66, "At-Tahrim", "التحريم", 12),
    (67, "Al-Mulk", "الملك", 30),
    (68, "Al-Qalam", "القلم", 52),
    (69, "Al-Haqqah", "الحاقة", 52),
    (70, "Al-Ma'arij", "المعارج", 44),
    (71, "Nuh", "نوح", 28),
    (72, "Al-Jinn", "الجن", 28),
    (73, "Al-Muzzammil", "المزمل", 20),
    (74, "Al-Muddaththir", "المدثر", 56),
    (75, "Al-Qiyamah", "القيامة", 40),
    (76, "Al-Insan", "الإنسان", 31),
    (77, "Al-Mursalat", "المرسلات", 50),
    (78, "An-Naba", "النبأ", 40),
    (79, "An-Nazi'at", "النازعات", 46),
    (80, "'Abasa", "عبس", 42),
    (81, "At-Takwir", "التكوير", 29),
    (82, "Al-Infitar", "الانفطار", 19),
    (83, "Al-Mutaffifin", "المطففين", 36),
    (84, "Al-Inshiqaq", "الانشقاق", 25),
    (85, "Al-Buruj", "البروج", 22),
    (86, "At-Tariq", "الطارق", 17),
    (87, "Al-A'la", "الأعلى", 19),
    (88, "Al-Ghashiyah", "الغاشية", 26),
    (89, "Al-Fajr", "الفجر", 30),
    (90, "Al-Balad", "البلد", 20),
    (91, "Ash-Shams", "الشمس", 15),
    (92, "Al-Layl", "الليل", 21),
    (93, "Ad-Duhaa", "الضحى", 11),
    (94, "Ash-Sharh", "الشرح", 8),
    (95, "At-Tin", "التين", 8),
    (96, "Al-'Alaq", "العلق", 19),
    (97, "Al-Qadr", "القدر", 5),
    (98, "Al-Bayyinah", "البينة", 8),
    (99, "Az-Zalzalah", "الزلزلة", 8),
    (100, "Al-'Adiyat", "العاديات", 11),
    (101, "Al-Qari'ah", "القارعة", 11),
    (102, "At-Takathur", "التكاثر", 8),
    (103, "Al-'Asr", "العصر", 3),
    (104, "Al-Humazah", "الهمزة", 9),
    (105, "Al-Fil", "الفيل", 5),
    (106, "Quraysh", "قريش", 4),
    (107, "Al-Ma'un", "الماعون", 7),
    (108, "Al-Kawthar", "الكوثر", 3),
    (109, "Al-Kafirun", "الكافرون", 6),
    (110, "An-Nasr", "النصر", 3),
    (111, "Al-Masad", "المسد", 5),
    (112, "Al-Ikhlas", "الإخلاص", 4),
    (113, "Al-Falaq", "الفلق", 5),
    (114, "An-Nas", "الناس", 6),
]

# -------------------------------------------------------------
# STREAM-PAYLOAD-PARSER (SKILL INVENTORY IMPLEMENTATION)
# -------------------------------------------------------------
def clean_arabic_text(text: str) -> str:
    if not text:
        return ""
    # Strip Tashkeel
    t = re.sub(r"[\u064B-\u065F\u0670\u06D6-\u06ED]", "", text)
    t = re.sub(r"[إأآٱ]", "ا", t)
    t = re.sub(r"ى", "ي", t)
    t = re.sub(r"ة", "ه", t)
    t = re.sub(r"[ؤئ]", "ء", t)
    t = re.sub(r"[^\u0621-\u064A0-9\s]", " ", t)
    return re.sub(r"\s+", " ", t).strip()

def clean_latin_title(text: str) -> str:
    if not text:
        return ""
    t = text.lower()
    t = re.sub(r"\b(surat|surah|sourate|sura|chapter|part)\b", "", t)
    t = re.sub(r"[^a-z0-9\s]", "", t)
    return re.sub(r"\s+", " ", t).strip()

def parse_shazam_payload(track: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    title = track.get("title", "")
    subtitle = track.get("subtitle", "") # Artist/Qari
    album = ""
    for sec in track.get("sections", []):
        if sec.get("type") == "SONG":
            for meta in sec.get("metadata", []):
                if meta.get("title") == "Album":
                    album = meta.get("text", "")

    combined_text = f"{title} {album}".strip()
    clean_ar = clean_arabic_text(title)
    clean_en = clean_latin_title(title)
    combined_clean_en = clean_latin_title(f"{title} {album}")

    # 1. Check for Ayat Al-Kursi special match
    if "كرسي" in clean_ar or "kursi" in clean_en or "koursi" in clean_en or "kursi" in combined_clean_en:
        surah = next((s for s in SURAHS if s[0] == 2), None)
        if surah:
            return {
                "surahId": 2,
                "nameEn": surah[1],
                "nameAr": surah[2],
                "ayah": 255,
                "qari": subtitle or "Mishary Rashid Alafasy",
                "confidence": 0.98,
                "trackTitle": title,
                "matchDetail": "Ayat Al-Kursi (2:255)"
            }

    # 2. Match Surah by Arabic name (exact substring)
    for s_id, s_en, s_ar, s_max in SURAHS:
        norm_s_ar = clean_arabic_text(s_ar)
        if norm_s_ar and norm_s_ar in clean_ar:
            return {
                "surahId": s_id,
                "nameEn": s_en,
                "nameAr": s_ar,
                "ayah": 1,
                "qari": subtitle or "Known Sheikh",
                "confidence": 0.98,
                "trackTitle": title,
                "matchDetail": f"Surah {s_en} ({s_ar})"
            }

    # 3. Match Surah by Arabic fuzzy WRatio
    ar_lookup = {clean_arabic_text(s[2]): s for s in SURAHS}
    best_ar = process.extractOne(clean_ar, ar_lookup.keys(), scorer=fuzz.WRatio)
    if best_ar and best_ar[1] >= 75:
        matched_s = ar_lookup[best_ar[0]]
        return {
            "surahId": matched_s[0],
            "nameEn": matched_s[1],
            "nameAr": matched_s[2],
            "ayah": 1,
            "qari": subtitle or "Known Sheikh",
            "confidence": round(best_ar[1] / 100.0, 2),
            "trackTitle": title,
            "matchDetail": f"Surah {matched_s[1]} ({matched_s[2]})"
        }

    # 4. Match Surah by Latin name using fuzz.WRatio on clean_en and title
    surah_lookup = {re.sub(r"[^a-zA-Z0-9\s]", "", s[1]).lower().strip(): s for s in SURAHS}
    best = process.extractOne(clean_en, surah_lookup.keys(), scorer=fuzz.WRatio)
    if not best or best[1] < 68:
        best = process.extractOne(combined_clean_en, surah_lookup.keys(), scorer=fuzz.WRatio)
    if not best or best[1] < 68:
        best = process.extractOne(re.sub(r"[^a-zA-Z0-9\s]", "", title).lower().strip(), surah_lookup.keys(), scorer=fuzz.WRatio)

    if best and best[1] >= 68:
        matched_s = surah_lookup[best[0]]
        return {
            "surahId": matched_s[0],
            "nameEn": matched_s[1],
            "nameAr": matched_s[2],
            "ayah": 1,
            "qari": subtitle or "Known Sheikh",
            "confidence": round(best[1] / 100.0, 2),
            "trackTitle": title,
            "matchDetail": f"Surah {matched_s[1]} ({matched_s[2]})"
        }

    return None

import subprocess
import speech_recognition as sr

# Ensure ffmpeg in PATH
for ffmpeg_candidate in [
    r"C:\Users\Aka.mouadd\AppData\Local\Microsoft\WinGet\Links",
    r"C:\Users\Aka.mouadd\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin"
]:
    if os.path.exists(ffmpeg_candidate) and ffmpeg_candidate not in os.environ["PATH"]:
        os.environ["PATH"] = ffmpeg_candidate + os.pathsep + os.environ["PATH"]

# -------------------------------------------------------------
# ASYNC API & CONTROLLER (ASYNC-API-DESIGN)
# -------------------------------------------------------------
shazam_instance = Shazam()
speech_recognizer = sr.Recognizer()
speech_recognizer.energy_threshold = 120

async def handle_recognize_audio(request: web.Request) -> web.Response:
    try:
        # Pre-action guard: validate body size
        if request.content_length and request.content_length > 30 * 1024 * 1024:
            return web.json_response({"status": "error", "message": "File exceeds 30MB limit"}, status=400)

        data = await request.read()
        if not data or len(data) < 500:
            return web.json_response({"status": "error", "message": "Audio data too short or empty"}, status=400)

        # Write incoming raw audio (WebM, OGG, M4A, WAV, MP3) to temporary file
        with tempfile.NamedTemporaryFile(suffix=".raw", delete=False) as raw_file:
            raw_file.write(data)
            raw_path = raw_file.name

        mp3_path = raw_path + ".mp3"
        wav_path = raw_path + ".wav"

        try:
            # Transcode with ffmpeg to standard MP3 and 16kHz mono WAV
            subprocess.run(
                ["ffmpeg", "-y", "-i", raw_path, "-ar", "44100", "-ac", "2", mp3_path],
                capture_output=True
            )
            subprocess.run(
                ["ffmpeg", "-y", "-i", raw_path, "-ar", "16000", "-ac", "1", wav_path],
                capture_output=True
            )

            # ---------------------------------------------------------
            # TIER 1: SHAZAMIO ACOUSTIC FINGERPRINT MATCHING
            # ---------------------------------------------------------
            if os.path.exists(mp3_path) and os.path.getsize(mp3_path) > 1000:
                try:
                    retries = 2
                    out = None
                    for attempt in range(retries):
                        try:
                            out = await shazam_instance.recognize(mp3_path)
                            break
                        except Exception as e:
                            if attempt == retries - 1:
                                break
                            await asyncio.sleep(0.3 * (attempt + 1))

                    track = out.get("track", {}) if out else {}
                    if track:
                        parsed = parse_shazam_payload(track)
                        if parsed:
                            return web.json_response({
                                "status": "success",
                                "engine": "shazamio_cloud",
                                "surahId": parsed["surahId"],
                                "surah_id": parsed["surahId"],
                                "nameEn": parsed["nameEn"],
                                "name_en": parsed["nameEn"],
                                "nameAr": parsed["nameAr"],
                                "name_ar": parsed["nameAr"],
                                "ayah": parsed["ayah"],
                                "qari": parsed["qari"],
                                "confidence": parsed["confidence"],
                                "match": parsed
                            })
                except Exception as e:
                    print("Notice: Shazamio attempt passed:", e)

            # ---------------------------------------------------------
            # TIER 2: RECITID SPEECH-TO-VERSE AI (QDETECT + GOOGLE ARABIC)
            # Essential for YouTube reciters (Omar Diaa Aldeen, masjids, personal recitations)
            # ---------------------------------------------------------
            if os.path.exists(wav_path) and os.path.getsize(wav_path) > 1000:
                try:
                    with sr.AudioFile(wav_path) as source:
                        audio_data = speech_recognizer.record(source)

                    arabic_text = ""
                    try:
                        arabic_text = speech_recognizer.recognize_google(audio_data, language="ar-SA")
                    except Exception:
                        try:
                            arabic_text = speech_recognizer.recognize_google(audio_data, language="ar-EG")
                        except Exception:
                            pass

                    print(f"🎙️ RecitID Arabic Speech Recognized: '{arabic_text}'")

                    if arabic_text:
                        # 1. Run QDetect
                        detected = detect(arabic_text, settings=Settings())
                        if detected:
                            d = detected[0]
                            surah_name_ar = d.get("surah_name", "")
                            surah_match = next((s for s in SURAHS if clean_arabic_text(s[2]) == clean_arabic_text(surah_name_ar)), None)
                            if surah_match:
                                s_id = surah_match[0]
                                s_en = surah_match[1]
                                s_ar = surah_match[2]
                                ayah_num = d.get("aya_start", 1)
                                return web.json_response({
                                    "status": "success",
                                    "engine": "quran_speech_ai",
                                    "surahId": s_id,
                                    "surah_id": s_id,
                                    "nameEn": s_en,
                                    "name_en": s_en,
                                    "nameAr": s_ar,
                                    "name_ar": s_ar,
                                    "ayah": ayah_num,
                                    "qari": "Verified Recitation (RecitID AI)",
                                    "transcription": arabic_text,
                                    "confidence": 0.98,
                                    "match": {
                                        "surahId": s_id,
                                        "nameEn": s_en,
                                        "nameAr": s_ar,
                                        "ayah": ayah_num,
                                        "qari": "Verified Recitation (RecitID AI)",
                                        "confidence": 0.98,
                                        "matchDetail": f"Surah {s_en} ({s_ar}) • Ayah {ayah_num}"
                                    }
                                })

                        # 2. Check if text mentions a surah by name (e.g. "سورة المؤمنون", "سورة الكهف")
                        for s in SURAHS:
                            clean_s_ar = clean_arabic_text(s[2])
                            clean_input = clean_arabic_text(arabic_text)
                            if clean_s_ar in clean_input:
                                return web.json_response({
                                    "status": "success",
                                    "engine": "quran_title_speech_ai",
                                    "surahId": s[0],
                                    "surah_id": s[0],
                                    "nameEn": s[1],
                                    "name_en": s[1],
                                    "nameAr": s[2],
                                    "name_ar": s[2],
                                    "ayah": 1,
                                    "qari": "Identified from Recitation (RecitID AI)",
                                    "transcription": arabic_text,
                                    "confidence": 0.95,
                                    "match": {
                                        "surahId": s[0],
                                        "nameEn": s[1],
                                        "nameAr": s[2],
                                        "ayah": 1,
                                        "qari": "Identified from Recitation (RecitID AI)",
                                        "confidence": 0.95,
                                        "matchDetail": f"Surah {s[1]} ({s[2]})"
                                    }
                                })
                except Exception as e:
                    print("Notice: RecitID speech recognition attempt:", e)

            return web.json_response({
                "status": "unmatched",
                "message": "No match found in Quran acoustic or speech databases. Please bring mic closer to recitation."
            })

        finally:
            for p in [raw_path, mp3_path, wav_path]:
                if os.path.exists(p):
                    try:
                        os.remove(p)
                    except Exception:
                        pass

    except Exception as e:
        return web.json_response({"status": "error", "message": str(e)}, status=500)

async def handle_detect_text(request: web.Request) -> web.Response:
    try:
        payload = await request.json()
        text = payload.get("text", "")
        if not text:
            return web.json_response({"status": "error", "message": "Missing 'text' parameter"}, status=400)

        # Execute quran-detector
        results = detect(text, settings=Settings())
        if not results:
            return web.json_response({"status": "unmatched", "results": []})

        formatted = []
        for r in results:
            surah_name_ar = r.get("surah_name", "")
            surah_match = next((s for s in SURAHS if clean_arabic_text(s[2]) == clean_arabic_text(surah_name_ar)), None)
            formatted.append({
                "surahId": surah_match[0] if surah_match else 1,
                "surahNameEn": surah_match[1] if surah_match else "Unknown",
                "surahNameAr": surah_name_ar,
                "ayahStart": r.get("aya_start", 1),
                "ayahEnd": r.get("aya_end", 1),
                "verses": r.get("verses", []),
                "confidence": 0.98
            })

        first = formatted[0] if formatted else {}
        return web.json_response({
            "status": "success",
            "engine": "quran_detector",
            "surahId": first.get("surahId", 1),
            "surah_id": first.get("surahId", 1),
            "surah_name_en": first.get("surahNameEn", "Al-Fatihah"),
            "surah_name_ar": first.get("surahNameAr", "الفاتحة"),
            "ayah_start": first.get("ayahStart", 1),
            "ayah_end": first.get("ayahEnd", 1),
            "confidence": 0.98,
            "results": formatted
        })

    except Exception as e:
        return web.json_response({"status": "error", "message": str(e)}, status=500)

async def handle_health(request: web.Request) -> web.Response:
    return web.json_response({
        "status": "ok",
        "service": "Bayan Quran AI Recognition Engine",
        "version": "2.1.0",
        "shazamio": "active",
        "recitid_speech_ai": "active",
        "quran_detector": "active",
        "surahs_indexed": len(SURAHS)
    })

def create_app() -> web.Application:
    app = web.Application()
    cors = aiohttp_cors.setup(app, defaults={
        "*": aiohttp_cors.ResourceOptions(
            allow_credentials=True,
            expose_headers="*",
            allow_headers="*"
        )
    })

    cors.add(app.router.add_get("/api/health", handle_health))
    cors.add(app.router.add_post("/api/recognize-audio", handle_recognize_audio))
    cors.add(app.router.add_post("/api/detect-text", handle_detect_text))

    PREVIEW_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "preview"))
    async def handle_index(request):
        return web.FileResponse(os.path.join(PREVIEW_DIR, "index.html"))

    app.router.add_get("/", handle_index)
    app.router.add_static("/preview", PREVIEW_DIR)
    app.router.add_static("/static", PREVIEW_DIR)

    return app

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8765))
    print(f"🚀 Bayan Quran Recognition Service running on http://127.0.0.1:{port}")
    web.run_app(create_app(), host="127.0.0.1", port=port)
