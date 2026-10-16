import asyncio
import sys
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')
from shazamio import Shazam
from quran_detector import detect, Settings

async def test_multiple():
    shazam = Shazam()
    files = [
        ("Al-Fatihah", r"scripts\reference_audio\alafasy\001001.mp3"),
        ("Al-Kahf", r"scripts\reference_audio\alafasy\018001.mp3"),
        ("Al-Mulk", r"scripts\reference_audio\alafasy\067001.mp3"),
        ("Al-Ikhlas", r"scripts\reference_audio\alafasy\112001.mp3"),
    ]
    for name, path in files:
        try:
            out = await shazam.recognize(path)
            track = out.get('track', {})
            title = track.get('title')
            subtitle = track.get('subtitle')
            print(f"[{name}] -> Shazam Match: Title='{title}', Artist='{subtitle}'")
        except Exception as e:
            print(f"[{name}] -> Error: {e}")

if __name__ == '__main__':
    asyncio.run(test_multiple())
