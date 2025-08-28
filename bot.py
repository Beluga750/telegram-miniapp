import asyncio
import os
from dotenv import load_dotenv

from telegram import Update, WebAppInfo, InlineKeyboardMarkup, InlineKeyboardButton
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
)

load_dotenv()  # читает .env локально

BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
WEBAPP_URL = os.getenv("WEBAPP_URL")  # напр. https://miniapp-backend-***.onrender.com

if not BOT_TOKEN:
    raise RuntimeError("TELEGRAM_BOT_TOKEN не найден в .env/ENV")

if not WEBAPP_URL:
    raise RuntimeError("WEBAPP_URL не найден в .env/ENV")

def build_keyboard():
    return InlineKeyboardMarkup(
        [[InlineKeyboardButton("Открыть мини-приложение", web_app=WebAppInfo(url=WEBAPP_URL))]]
    )

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Привет! Жми кнопку ниже 👇", reply_markup=build_keyboard())

async def refresh(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Кнопка обновлена ✅", reply_markup=build_keyboard())

def main():
    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("refresh", refresh))
    app.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()
