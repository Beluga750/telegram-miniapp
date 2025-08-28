# -*- coding: utf-8 -*-
import subprocess
import re
import os

ENV_FILE = ".env"
URL_RE = re.compile(r"https://[A-Za-z0-9\-.]+\.lhr\.life")

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

def main():
    # -T (без TTY, чтобы не рисовали QR), -N (только туннель), keepalive
    cmd = [
        "ssh", "-T", "-N",
        "-o", "StrictHostKeyChecking=no",
        "-o", "ServerAliveInterval=60",
        "-R", "80:localhost:8000",
        "nokey@localhost.run",
    ]
    print("[INFO] Запускаю SSH-туннель localhost.run…")
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)

    got_url = False
    try:
        for line in proc.stdout:
            print(line, end="")
            if not got_url:
                m = URL_RE.search(line)
                if m:
                    write_env(m.group(0))
                    print("[INFO] Туннель активен. Не закрывайте это окно.")
                    print("[HINT] В боте используйте /refresh или включите /autoon 2")
                    got_url = True
        # если поток закрылся — туннель упал
        print("[WARN] Поток вывода ssh завершился. Туннель закрыт.")
    finally:
        try:
            proc.wait(timeout=2)
        except Exception:
            pass

if __name__ == "__main__":
    main()
