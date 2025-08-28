@echo off
REM === One-click старт: backend + CF tunnel + bot ===
REM Запускай ЭТОТ файл в cmd.exe (не в PowerShell)

setlocal EnableExtensions

REM 1) BACKEND (FastAPI / Uvicorn)
start "MiniApp Backend" cmd /k ^
  cd /d "%~dp0" ^&^& call .venv\Scripts\activate.bat ^&^& ^
  python -m uvicorn webapp_backend:app --host 0.0.0.0 --port 8000 --reload

REM 2) CLOUDFLARE TUNNEL с авто-перезапуском и обновлением .env
start "Cloudflare Tunnel" cmd /k ^
  cd /d "%~dp0" ^&^& call .venv\Scripts\activate.bat ^&^& ^
  python -X utf8 update_env_cloudflare.py

REM 3) TELEGRAM BOT
start "Telegram Bot" cmd /k ^
  cd /d "%~dp0" ^&^& call .venv\Scripts\activate.bat ^&^& ^
  python bot.py

exit /b 0
