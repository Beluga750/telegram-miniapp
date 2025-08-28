@echo off
setlocal
REM ==== ONE-CLICK LAUNCHER: backend > tunnel > bot ====
REM Работает из любой папки: сам переходит к проекту.
pushd "%~dp0"

REM 0) Проверим/создадим venv (один раз)
if not exist ".venv\Scripts\python.exe" (
  echo [INFO] Creating virtual environment...
  py -3 -m venv .venv || (
    echo [ERROR] Python 3 не найден или не удалось создать venv.
    pause & exit /b 1
  )
)

REM 1) Backend (откроется в отдельном окне и будет работать там)
start "MiniApp Backend (uvicorn)" cmd /k ^
  "pushd \"%~dp0\" && call .venv\Scripts\activate.bat && python -m uvicorn webapp_backend:app --host 0.0.0.0 --port 8000 --reload"

REM Небольшая пауза, чтобы backend успел подняться
ping -n 3 127.0.0.1 >nul

REM 2) HTTPS-туннель Cloudflare (TCP/HTTP2). 
REM Если cloudflared.exe нет — скачаем и затем запустим.
if not exist "cloudflared.exe" (
  echo [INFO] Downloading cloudflared.exe...
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; ^
     Invoke-WebRequest -Uri https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -OutFile cloudflared.exe" || (
       echo [ERROR] Не удалось скачать cloudflared.exe
       pause & exit /b 1
  )
)

start "Cloudflare Tunnel (keep open)" cmd /k ^
  "pushd \"%~dp0\" && cloudflared.exe tunnel --protocol http2 --url http://127.0.0.1:8000"

echo.
echo ==================================================================================
echo  СКОПИРУЙ HTTPS-адрес из окна "Cloudflare Tunnel" (https://*.trycloudflare.com)
echo  и вставь его в .env, например:
echo      WEBAPP_URL=https://your-subdomain.trycloudflare.com/
echo  После сохранения .env нажми любую клавишу — запустим бота.
echo ==================================================================================
echo.
pause

REM 3) Bot (использует WEBAPP_URL из .env)
start "Telegram Bot" cmd /k ^
  "pushd \"%~dp0\" && call .venv\Scripts\activate.bat && python bot.py"

echo [INFO] Все окна запущены. Не закрывай окно Tunnel — иначе URL «умрёт».
exit /b 0
