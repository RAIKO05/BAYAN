import asyncio
import sys
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')
from shazamio import Shazam
from quran_detector import detect, Settings

async def test_audio():
    print("Testing quran-detector...")
    text = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ"
    results = detect(text, settings=Settings())
    print("quran-detector result:", results)

    print("\nTesting shazamio on reference audio...")
    shazam = Shazam()
    audio_file = r"scripts\reference_audio\alafasy\001001.mp3"
    out = await shazam.recognize(audio_file)
    track = out.get('track', {})
    print("Track Title:", track.get('title'))
    print("Track Subtitle (Artist):", track.get('subtitle'))
    print("Track Share URL:", track.get('share', {}).get('href'))

if __name__ == '__main__':
    asyncio.run(test_audio())
