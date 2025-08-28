@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

rem === Рабочая папка — папка скрипта ===
cd /d "%~dp0"

echo === Deploy to Render (FastAPI miniapp) ===

rem ---------- [A] Проверяем Git, при отсутствии — качаем portable MinGit ----------
set "_GITEXE="
for %%G in (git.exe) do set "_GITEXE=%%~$PATH:G"
if not defined _GITEXE (
  if exist ".tools\git\cmd\git.exe" (
    set "_GITEXE=%cd%\.tools\git\cmd\git.exe"
  ) else (
    echo [INFO] Git не найден. Скачиваю portable MinGit...
    set "ZIPURL=https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/MinGit-2.46.0-64-bit.zip"
    set "ZIPFILE=%cd%\.tools\mingit.zip"
    if not exist ".tools" mkdir ".tools"

    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "[Net.ServicePointManager]::SecurityProtocol='Tls12';" ^
      "Invoke-WebRequest -Uri '%ZIPURL%' -OutFile '%ZIPFILE%'"

    if errorlevel 1 (
      echo [ERR] Не удалось скачать MinGit. Установи Git вручную: https://git-scm.com/download/win
      pause & exit /b 1
    )

    echo [INFO] Распаковываю MinGit...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "Expand-Archive -Force '%ZIPFILE%' '%cd%\.tools\git'"

    del /q "%ZIPFILE%" >nul 2>nul
    if not exist ".tools\git\cmd\git.exe" (
      echo [ERR] Не удалось распаковать MinGit.
      pause & exit /b 1
    )
    set "_GITEXE=%cd%\.tools\git\cmd\git.exe"
  )
)

rem Добавляем portable git во временный PATH текущего процесса
if exist ".tools\git\cmd\git.exe" (
  set "PATH=%cd%\.tools\git\cmd;%cd%\.tools\git\mingw64\bin;%PATH%"
)

rem ---------- [B] Создаём .gitignore ----------
if not exist ".gitignore" (
  > ".gitignore" (
    echo .venv/
    echo __pycache__/
    echo *.pyc
    echo cloudflared*.exe
    echo tunnel_url.txt
    echo .env
  )
  echo [OK] .gitignore создан.
)

rem ---------- [C] Создаём render.yaml (Blueprint) ----------
if not exist "render.yaml" (
  > "render.yaml" (
    echo services:
    echo   - type: web
    echo     name: miniapp-backend
    echo     env: python
    echo     plan: free
    echo     rootDir: .
    echo     buildCommand: pip install -r requirements.txt
    echo     startCommand: uvicorn webapp_backend:app --host 0.0.0.0 --port ^$PORT
    echo     autoDeploy: true
    echo     healthCheckPath: /
  )
  echo [OK] render.yaml создан.
)

rem ---------- [D] Инициализация git-репозитория ----------
if not exist ".git" (
  git init || (echo [ERR] git init не удался & pause & exit /b 1)
)
git branch -M main >nul 2>nul

rem ---------- [E] Адрес GitHub-репозитория ----------
if "%REPO_URL%"=="" (
  set /p REPO_URL=Вставьте HTTPS-URL репозитория на GitHub (например https://github.com/user/repo.git): 
)
if "%REPO_URL%"=="" (
  echo [HINT] Создайте новый репозиторий и запустите батник снова.
  start "" "https://github.com/new"
  pause & exit /b 0
)

git remote show origin >nul 2>nul
if errorlevel 1 ( git remote add origin "%REPO_URL%" ) else ( git remote set-url origin "%REPO_URL%" )

rem ---------- [F] Коммит и пуш ----------
git add -A
git commit -m "Deploy: miniapp backend + render.yaml" >nul 2>nul

git push -u origin main
if errorlevel 1 (
  echo.
  echo [WARN] Push не удался. Заверши авторизацию GitHub (PAT/логин) и повтори push.
  echo Запустить повторный push? (Y/N)
  set /p ANS="> "
  if /I "%ANS%"=="Y" git push -u origin main
)

rem ---------- [G] Открываем Render для деплоя ----------
set "REPO_PAGE=%REPO_URL%"
if /I "%REPO_PAGE:~-4%"==".git" set "REPO_PAGE=%REPO_PAGE:~0,-4%"

echo.
echo [INFO] Открываю страницу деплоя на Render. Нажми "Deploy".
start "" "https://render.com/deploy?repo=%REPO_PAGE%"

echo.
echo [NEXT] После деплоя Render даст URL вида https://xxxx.onrender.com
echo [NEXT] Пропиши в .env:  WEBAPP_URL=https://xxxx.onrender.com/
echo [NEXT] Перезапусти локально бота и в чате введи /refresh
echo.
pause
exit /b 0
