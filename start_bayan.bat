@echo off
title Bayan Quran AI Recognition Server
cd /d "%~dp0"

echo ====================================================
echo      BAYAN (بَيَان) - Quran AI Recognition Engine
echo ====================================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo [ERROR] Virtual environment not found in .venv.
    pause
    exit /b 1
)

echo [*] Starting Bayan Recognition Server on http://127.0.0.1:8765 ...
echo [*] Opening browser to http://127.0.0.1:8765/ ...
echo.

start http://127.0.0.1:8765/

.venv\Scripts\python scripts\bayan_recognition_server.py
pause
