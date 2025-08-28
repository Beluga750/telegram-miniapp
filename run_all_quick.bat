@echo off
setlocal enableextensions
REM === One-click: backend > tunnel > bot (без остановок) ===
REM Скрипт сам зайдёт в папку, где лежит .bat
pushd "%~dp0"

REM 0) venv (если ещё нет)
if not exist ".venv\Scripts\python.exe" (
  echo [INFO] Creating virtual environment...
  py -3 -m venv .venv
)

REM 1) Backend (в отдельном окне)
set "BACKEND_CMD=call .venv\Scripts\activate.bat && python -m uvicorn webapp_backend:app --host 0.0.0.0 --port 8000 --reload"
start "MiniApp Backend (uvicorn)" cmd /k "%BACKEND_CMD%"

REM 2) cloudflared (скачаем при необходимости) — держите окно открытым
if not exist "cloudflared.exe" (
  echo [INFO] Downloading cloudflared.exe...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -OutFile cloudflared.exe"
)
set "TUNNEL_CMD=cloudflared.exe tunnel --protocol http2 --url http://127.0.0.1:8000"
start "Cloudflare Tunnel" cmd /k "%TUNNEL_CMD%"

REM 3) Небольшая пауза, чтобы backend/tunnel успели подняться
ping -n 4 127.0.0.1 >nul

REM 4) Бот (использует адрес из .env; убедитесь что WEBAPP_URL уже актуальный)
set "BOT_CMD=call .venv\Scripts\activate.bat && python bot.py"
start "Telegram Bot" cmd /k "%BOT_CMD%"

echo [INFO] Все окна запущены. Не закрывайте окно Tunnel.
exit /b 0
