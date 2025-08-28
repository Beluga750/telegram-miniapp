# Telegram Mini App (Python starter)

Готовый минимальный шаблон мини‑приложения для Telegram:
- Бот‑лаунчер на `python-telegram-bot`
- Бэкенд на `FastAPI` со статикой и эндпоинтом `/api/echo`
- Веб‑клиент (WebApp) на `HTML + Telegram WebApp JS`

## Быстрый старт (Windows)

1) Создайте бота через @BotFather и получите токен.
2) Распакуйте архив и перейдите в папку проекта в консоли.
3) Создайте виртуальное окружение и установите зависимости:
   ```bat
   py -3 -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt
   ```
4) Скопируйте `.env.example` в `.env` и заполните:
   - `BOT_TOKEN=...`
   - `WEBAPP_URL=http://127.0.0.1:8000/` (для локальной отладки в Telegram Desktop)
5) Запустите бэкенд (отдельное окно):
   ```bat
   .venv\Scripts\activate
   python -m uvicorn webapp_backend:app --host 0.0.0.0 --port 8000 --reload
   ```
6) Запустите бота (ещё одно окно):
   ```bat
   .venv\Scripts\activate
   python bot.py
   ```
7) Откройте ваш бот в Telegram, введите `/start` и нажмите кнопку **«Открыть мини‑приложение»** или воспользуйтесь кнопкой в меню чата.

### Важно про URL
- **Мобильные клиенты Telegram (iOS/Android)** требуют **HTTPS**. Для теста используйте ngrok/localhost.run/Cloudflare Tunnel либо свой домен с TLS.
- **Telegram Desktop** позволяет загружать `http://127.0.0.1:8000/` локально.

### Проверка подлинности
Эндпоинт `/api/echo` демонстрирует валидацию `initData` (подписи Telegram WebApp). Для прод доступны доп. меры защиты (ограничение времени, ip, csrf и пр.).

## Где править фронтенд
Файлы лежат в `webapp_frontend`. Главная страница — `index.html`.
