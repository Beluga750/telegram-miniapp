@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem === 0. В эту же папку положите батник и запускайте его двойным кликом ===
cd /d "%~dp0"

echo === Deploy to Render (FastAPI miniapp) ===

rem --- 1. Проверка наличия git ---
where git >nul 2>nul
if errorlevel 1 (
  echo [ERR] Git не найден в PATH. Установите Git for Windows: https://git-scm.com/download/win
  pause
  exit /b 1
)

rem --- 2. Создадим .gitignore (если нет) ---
if not exist ".gitignore" (
  > ".gitignore" (
    echo .venv/
    echo __pycache__/
    echo *.pyc
    echo cloudflared.exe
    echo cloudflared-windows-amd64.exe
    echo tunnel_url.txt
    echo .env
  )
  echo [OK] .gitignore создан.
)

rem --- 3. Создадим render.yaml (Blueprint) ---
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

rem --- 4. Инициализируем git, если нужно ---
if not exist ".git" (
  git init
  if errorlevel 1 ( echo [ERR] git init не удался & pause & exit /b 1 )
)

rem --- 5. Имя ветки main ---
git branch -M main >nul 2>nul

rem --- 6. Спросим адрес репозитория ---
if "%REPO_URL%"=="" (
  set /p REPO_URL=Вставьте HTTPS-адрес вашего репозитория на GitHub (например https://github.com/user/repo.git): 
)
if "%REPO_URL%"=="" (
  echo [HINT] Создайте новый репозиторий и запустите батник снова.
  start "" "https://github.com/new"
  pause
  exit /b 0
)

rem --- 7. Добавим/обновим origin ---
git remote show origin >nul 2>nul
if errorlevel 1 (
  git remote add origin "%REPO_URL%"
) else (
  git remote set-url origin "%REPO_URL%"
)

rem --- 8. Коммит ---
git add -A
git commit -m "Deploy: miniapp backend + render.yaml" >nul 2>nul

rem --- 9. Push ---
git push -u origin main
if errorlevel 1 (
  echo.
  echo [WARN] Push не удался. Git, скорее всего, ждёт логин/пароль или токен.
  echo       Если открылось окно авторизации GitHub — завершите вход и повторите push.
  echo       Запустить повторный push? (Y/N)
  set /p ANS="> "
  if /I "%ANS%"=="Y" git push -u origin main
)

rem --- 10. Откроем страницу деплоя Render ---
set REPO_PAGE=%REPO_URL%
rem убираем суффикс .git для ссылки
if /I not "%REPO_PAGE:~-4%"==".git" goto open_render
set REPO_PAGE=%REPO_PAGE:~0,-4%

:open_render
echo.
echo [INFO] Открываю страницу деплоя Render. Нажмите "Deploy" в браузере.
start "" "https://render.com/deploy?repo=%REPO_PAGE%"

echo.
echo [NEXT] После успешного деплоя Render даст URL вида https://xxxx.onrender.com
echo [NEXT] Откройте .env и установите:
echo        WEBAPP_URL=https://xxxx.onrender.com/
echo [NEXT] Затем запустите локально бота и в чате введите /refresh
echo.
pause
exit /b 0
