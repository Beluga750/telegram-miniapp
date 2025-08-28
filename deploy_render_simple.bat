@echo off
chcp 65001 >nul
echo === Deploy to Render (FastAPI miniapp) ===

setlocal

:: 1) Проверяем Git в PATH
where git >nul 2>&1
if %errorlevel%==0 (
  set GIT_EXE=git
  goto git_found
)

:: 2) Проверяем PortableGit в папке проекта
if exist "%~dp0PortableGit\cmd\git.exe" (
  set GIT_EXE=%~dp0PortableGit\cmd\git.exe
  goto git_found
)

:: 3) Проверяем .tools\git
if exist "%~dp0.tools\git\cmd\git.exe" (
  set GIT_EXE=%~dp0.tools\git\cmd\git.exe
  goto git_found
)

echo [ERR] Git не найден! Установи Git вручную: https://git-scm.com/download/win
pause
exit /b 1

:git_found
echo [INFO] Найден Git: %GIT_EXE%

:: Дальше твоя логика деплоя:
%GIT_EXE% --version

echo [OK] Git работает. Теперь можно пушить код на Render.
pause
