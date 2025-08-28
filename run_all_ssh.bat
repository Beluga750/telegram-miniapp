@echo off
setlocal EnableExtensions

start "MiniApp Backend" cmd /k ^
  cd /d "%~dp0" ^&^& call .venv\Scripts\activate.bat ^&^& ^
  python -m uvicorn webapp_backend:app --host 0.0.0.0 --port 8000 --reload

start "Tunnel (auto provider)" cmd /k ^
  cd /d "%~dp0" ^&^& call .venv\Scripts\activate.bat ^&^& ^
  python -X utf8 update_env_tunnel.py

start "Telegram Bot" cmd /k ^
  cd /d "%~dp0" ^&^& call .venv\Scripts\activate.bat ^&^& ^
  python bot.py

exit /b 0


