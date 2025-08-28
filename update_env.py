# -*- coding: utf-8 -*-
import os, re, sys, subprocess

ENV_PATH = ".env"
CLOUDFLARED = "cloudflared.exe"

URL_RE = re.compile(
    r"https://[a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)*\.(?:trycloudflare\.com|lhr\.life)\b"
)

def update_env(url: str):
    url = url.rstrip("/") + "/"
    lines, found = [], False
    if os.path.exists(ENV_PATH):
        with open(ENV_PATH, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip().startswith("WEBAPP_URL="):
                    lines.append(f"WEBAPP_URL={url}\n"); found = True
                else:
                    lines.append(line)
    if not found:
        lines.append(f"WEBAPP_URL={url}\n")
    with open(ENV_PATH, "w", encoding="utf-8") as f:
        f.writelines(lines)
    print(f"[INFO] .env обновлён: WEBAPP_URL={url}")

def ensure_cloudflared():
    if os.path.exists(CLOUDFLARED):
        print("[INFO] cloudflared.exe найден")
        return
    print("[INFO] Скачиваю cloudflared.exe…")
    try:
        import urllib.request
        urllib.request.urlretrieve(
            "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe",
            CLOUDFLARED
        )
        print("[INFO] cloudflared.exe скачан.")
    except Exception as e:
        print("[ERROR] Не удалось скачать cloudflared:", e)
        sys.exit(1)

def run_cloudflared():
    ensure_cloudflared()
    print("[INFO] Запускаю cloudflared (http2)…")
    p = subprocess.Popen(
        [CLOUDFLARED, "tunnel", "--protocol", "http2", "--url", "http://127.0.0.1:8000"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1
    )
    for line in p.stdout:
        print(line, end="")
        m = URL_RE.search(line)
        if m:
            update_env(m.group(0))

def run_ssh_localhost_run():
    print("[INFO] Запускаю SSH-туннель localhost.run…")
    p = subprocess.Popen(
        ["ssh", "-o", "StrictHostKeyChecking=no", "-R", "80:localhost:8000", "nokey@localhost.run"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1
    )
    for line in p.stdout:
        print(line, end="")
        m = URL_RE.search(line)
        if m:
            update_env(m.group(0))

if __name__ == "__main__":
    mode = (sys.argv[1].lower() if len(sys.argv) > 1 else "cf")
    if mode in ("cf", "cloudflare", "cloudflared"):
        run_cloudflared()
    elif mode in ("ssh", "localhost.run", "lhr"):
        run_ssh_localhost_run()
    else:
        print("Использование: python update_env.py [cf|ssh]")
        sys.exit(2)
