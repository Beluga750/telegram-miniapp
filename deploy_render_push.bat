@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

echo === Deploy to Render (FastAPI miniapp) ===

rem -- Находим git (как в твоём тесте)
set GIT_EXE=
if exist "%~dp0PortableGit\cmd\git.exe" set "GIT_EXE=%~dp0PortableGit\cmd\git.exe"
if not defined GIT_EXE if exist "%~dp0.tools\git\cmd\git.exe" set "GIT_EXE=%~dp0.tools\git\cmd\git.exe"
if not defined GIT_EXE where git >nul 2>&1 && set "GIT_EXE=git"
if not defined GIT_EXE (
  echo [ERR] Git не найден.
  pause & exit /b 1
)
echo [INFO] Git: %GIT_EXE%
%GIT_EXE% --version

rem -- .gitignore
if not exist ".gitignore" (
  > ".gitignore" (
    echo .venv/
    echo __pycache__/
    echo *.pyc
    echo cloudflared*.exe
    echo PortableGit/
    echo .tools/
    echo tunnel_url.txt
    echo .env
  )
  echo [OK] .gitignore создан
)

rem -- render.yaml (если вдруг нет)
if not exist "render.yaml" (
  > "render.yaml" (
    echo services:
    echo   - type: web
    echo     name: miniapp-backend
    echo     env: python
    echo     plan: free
    echo     buildCommand: pip install -r requirements.txt
    echo     startCommand: uvicorn webapp_backend:app --host 0.0.0.0 --port ^$PORT
    echo     autoDeploy: true
    echo     healthCheckPath: /
  )
  echo [OK] render.yaml создан
)

rem -- git init/commit
if not exist ".git" (
  "%GIT_EXE%" init || (echo [ERR] git init failed & pause & exit /b 1)
)
"%GIT_EXE%" branch -M main >nul 2>nul
"%GIT_EXE%" add -A
"%GIT_EXE%" commit -m "Deploy miniapp backend + render.yaml" >nul 2>nul

rem -- URL репозитория
set REPO_URL=
if exist ".git\config" (
  for /f "tokens=2" %%a in ('"%GIT_EXE%" remote -v ^| find "origin" ^| find "push"') do set REPO_URL=%%a
)
if not defined REPO_URL (
  echo.
  echo Вставь HTTPS-URL репозитория на GitHub (пример: https://github.com/username/repo.git)
  set /p REPO_URL="REPO_URL: "
  if not defined REPO_URL (
    echo [HINT] Создай репозиторий и запусти батник снова.
    start "" "https://github.com/new"
    pause & exit /b 0
  )
  "%GIT_EXE%" remote add origin "%REPO_URL%" 2>nul || "%GIT_EXE%" remote set-url origin "%REPO_URL%"
)

rem -- push
echo [INFO] Push в origin/main ...
"%GIT_EXE%" push -u origin main
if errorlevel 1 (
  echo.
  echo [WARN] Push не удался. Если GitHub просит логин/пароль —
  echo введите логин GitHub и вместо пароля вставьте Personal Access Token (PAT).
  echo Открыть страницу создания PAT? (Y/N)
  set /p ANS="> "
  if /I "%ANS%"=="Y" start "" "https://github.com/settings/tokens?type=beta"
  echo Повторить push? (Y/N)
  set /p ANS="> "
  if /I "%ANS%"=="Y" "%GIT_EXE%" push -u origin main
)

rem -- ссылка на репо без .git
set REPO_PAGE=%REPO_URL%
if /I "%REPO_PAGE:~-4%"==".git" set "REPO_PAGE=%REPO_PAGE:~0,-4%"

echo.
echo [INFO] Открываю Render Deploy…
start "" "https://render.com/deploy?repo=%REPO_PAGE%"

echo.
echo [NEXT] На Render нажми Deploy. Когда сервис станет Live, возьми его URL вида:
echo        https://xxxx.onrender.com
echo [NEXT] Пропиши в .env:
echo        WEBAPP_URL=https://xxxx.onrender.com/
echo [NEXT] Перезапусти бота и в чате с ботом набери /refresh
echo.
pause
exit /b 0
