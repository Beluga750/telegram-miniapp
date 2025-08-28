@echo off
cd /d "%~dp0"
call .venv\Scripts\activate.bat
python -X utf8 update_env.py ssh
