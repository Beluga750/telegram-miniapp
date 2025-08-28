import hashlib
import hmac
import json
import os
from datetime import datetime
from urllib.parse import parse_qsl

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

# === env ===
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
if not BOT_TOKEN:
    # На Render добавьте переменную окружения TELEGRAM_BOT_TOKEN
    raise RuntimeError("TELEGRAM_BOT_TOKEN is not set")

app = FastAPI(title="Miniapp backend")

# --- utils: soft-проверка Telegram initData (НЕ валим 400 если неверно) ---
def verify_init_data(init_data: str) -> bool:
    """
    https://core.telegram.org/bots/webapps#validating-data-received-via-the-web-app
    Возвращаем True/False, но никогда не бросаем 400 — чтобы мини-апп открывалась всегда.
    """
    if not init_data:
        return False
    try:
        data = dict(parse_qsl(init_data, keep_blank_values=True))
        received_hash = data.pop("hash", "")
        check_string = "\n".join(f"{k}={v}" for k, v in sorted(data.items()))
        secret = hashlib.sha256(BOT_TOKEN.encode()).digest()
        calc_hash = hmac.new(secret, check_string.encode(), hashlib.sha256).hexdigest()
        return hmac.compare_digest(received_hash, calc_hash)
    except Exception:
        return False

# --- API ---
@app.get("/healthz")
async def healthz():
    return {"ok": True, "ts": datetime.utcnow().isoformat()}

@app.post("/api/echo")
async def echo(req: Request):
    body = await req.json()
    init_data = (body or {}).get("initData", "")
    payload = (body or {}).get("payload", {})
    authenticated = verify_init_data(init_data)
    return JSONResponse(
        {
            "ok": True,
            "authenticated": authenticated,
            "payload": payload or {},
            "message": "hello-from-backend",
        }
    )

# --- фронт: отдаем index.html и статические файлы из папки webapp_frontend ---
# ВАЖНО: сначала объявили /api, затем смонтировали фронт на "/"
app.mount("/", StaticFiles(directory="webapp_frontend", html=True), name="root")
# webapp_backend.py
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from pathlib import Path
from datetime import datetime, timezone

app = FastAPI()

# CORS (на всякий случай — фронт и бэк на одном домене, но пусть будет)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"],
)

# --- статика (фронтенд) ---
BASE_DIR = Path(__file__).parent
FRONT = BASE_DIR / "webapp_frontend"
app.mount("/static", StaticFiles(directory=str(FRONT)), name="static")

@app.get("/", response_class=HTMLResponse)
async def root():
    # отдаем наш index.html
    return FileResponse(FRONT / "index.html")

# --- простое “хранилище” (оперативная память процесса) ---
ENTRIES: list[dict] = []

class EntryIn(BaseModel):
    type: str  # "income" | "expense"
    title: str
    amount: float

@app.get("/api/entries")
async def get_entries():
    # последние 50
    return {"ok": True, "items": list(reversed(ENTRIES))[:50]}

@app.post("/api/entry")
async def add_entry(payload: EntryIn, request: Request):
    item = {
        "type": "income" if payload.type == "income" else "expense",
        "title": payload.title.strip(),
        "amount": float(payload.amount),
        "ts": datetime.now(timezone.utc).isoformat(),
        "ip": request.client.host if request.client else None,
    }
    ENTRIES.append(item)
    return {"ok": True, "item": item}
