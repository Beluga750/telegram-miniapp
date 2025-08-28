@echo off
setlocal EnableExtensions
REM ===== ONE-CLICK: backend > tunnel(+auto .env) > bot =====
REM Работает из любой папки: каждому окну задаём рабочий каталог через cd /d.

REM 1) BACKEND (uvicorn)
start "MiniApp Backend (uvicorn)" cmd /k cd /d "%~dp0" ^&^& call .venv\Scripts\activate.bat ^&^& python -m uvicorn webapp_backend:app --host 0.0.0.0 --port 8000 --reload

REM 2) CLOUDFLARE TUNNEL + AUTO .ENV (update_env.py)
start "Cloudflare Tunnel (+auto .env)" cmd /k cd /d "%~dp0" ^&^& call .venv\Scripts\activate.bat ^&^& python -X utf8 update_env.py

REM 3) TELEGRAM BOT
start "Telegram Bot" cmd /k cd /d "%~dp0" ^&^& call .venv\Scripts\activate.bat ^&^& python bot.py

exit /b 0

