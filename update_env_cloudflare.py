# -*- coding: utf-8 -*-
"""
Автозапуск Cloudflare Tunnel с обновлением .env
"""

import os, re, subprocess, time

ENV_FILE = ".env"
URL_RE = re.compile(r"https://[a-zA-Z0-9\-]+\.trycloudflare\.com")

def write_env(url: str):
    url = url.rstrip("/") + "/"
    lines, found = [], False
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE, "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("WEBAPP_URL="):
                    lines.append(f"WEBAPP_URL={url}\n"); found = True
                else:
                    lines.append(line)
    if not found:
        lines.append(f"WEBAPP_URL={url}\n")
    with open(ENV_FILE, "w", encoding="utf-8") as f:
        f.writelines(lines)
    with open("tunnel_url.txt", "w", encoding="utf-8") as f:
        f.write(url)
    print(f"[INFO] .env обновлён: WEBAPP_URL={url}")

def run_once():
    cmd = [
        "cloudflared.exe", "tunnel",
        "--protocol", "http2",
        "--no-autoupdate",
        "--url", "http://127.0.0.1:8000"
    ]
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )
    got_url = False
    try:
        for line in proc.stdout:
            print(line, end="")
            m = URL_RE.search(line)
            if m and not got_url:
                write_env(m.group(0))
                got_url = True
    finally:
        try:
            proc.wait(timeout=2)
        except Exception:
            pass
    return got_url, proc.returncode

if __name__ == "__main__":
    print("[INFO] Cloudflare tunnel watchdog запущен")
    while True:
        got_url, code = run_once()
        print(f"[WARN] Туннель завершился (code={code}). Перезапуск через 3 сек…")
        time.sleep(3)

