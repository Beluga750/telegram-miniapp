@echo off
setlocal
REM ==== ONE-CLICK LAUNCHER: backend > tunnel > bot ====
REM �������� �� ����� �����: ��� ��������� � �������.
pushd "%~dp0"

REM 0) ��������/�������� venv (���� ���)
if not exist ".venv\Scripts\python.exe" (
  echo [INFO] Creating virtual environment...
  py -3 -m venv .venv || (
    echo [ERROR] Python 3 �� ������ ��� �� ������� ������� venv.
    pause & exit /b 1
  )
)

REM 1) Backend (��������� � ��������� ���� � ����� �������� ���)
start "MiniApp Backend (uvicorn)" cmd /k ^
  "pushd \"%~dp0\" && call .venv\Scripts\activate.bat && python -m uvicorn webapp_backend:app --host 0.0.0.0 --port 8000 --reload"

REM ��������� �����, ����� backend ����� ���������
ping -n 3 127.0.0.1 >nul

REM 2) HTTPS-������� Cloudflare (TCP/HTTP2). 
REM ���� cloudflared.exe ��� � ������� � ����� ��������.
if not exist "cloudflared.exe" (
  echo [INFO] Downloading cloudflared.exe...
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; ^
     Invoke-WebRequest -Uri https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -OutFile cloudflared.exe" || (
       echo [ERROR] �� ������� ������� cloudflared.exe
       pause & exit /b 1
  )
)

start "Cloudflare Tunnel (keep open)" cmd /k ^
  "pushd \"%~dp0\" && cloudflared.exe tunnel --protocol http2 --url http://127.0.0.1:8000"

echo.
echo ==================================================================================
echo  �������� HTTPS-����� �� ���� "Cloudflare Tunnel" (https://*.trycloudflare.com)
echo  � ������ ��� � .env, ��������:
echo      WEBAPP_URL=https://your-subdomain.trycloudflare.com/
echo  ����� ���������� .env ����� ����� ������� � �������� ����.
echo ==================================================================================
echo.
pause

REM 3) Bot (���������� WEBAPP_URL �� .env)
start "Telegram Bot" cmd /k ^
  "pushd \"%~dp0\" && call .venv\Scripts\activate.bat && python bot.py"

echo [INFO] ��� ���� ��������. �� �������� ���� Tunnel � ����� URL �����.
exit /b 0
