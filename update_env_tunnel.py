# -*- coding: utf-8 -*-
import subprocess, re, os, sys, time

ENV_FILE = ".env"

# Ищем https-ссылку любых популярных провайдеров
HTTPS_RE = re.compile(
    r"https://[A-Za-z0-9\-.]+(?:\.lhr\.life|\.pinggy\.io|\.serveo\.net|\.trycloudflare\.com)"
)

PROVIDERS = [
    {  # localhost.run
        "name": "localhost.run",
        "cmd": [
            "ssh", "-tt",    # форс TTY -> сервис печатает ссылку
            "-o", "StrictHostKeyChecking=no",
            "-o", "ServerAliveInterval=60",
            "-R", "80:localhost:8000",
            "nokey@localhost.run", "-N",
        ],
    },
    {  # pinggy (часто стабильнее)
        "name": "pinggy.io",
        "cmd": [
            "ssh", "-tt",
            "-o", "StrictHostKeyChecking=no",
            "-o", "ServerAliveInterval=60",
            # 0 = авто-рандом поддомен
            "-R", "0:localhost:8000",
            "a.pinggy.io", "-N",
        ],
    },
    {  # serveo (иногда недоступен, но попробуем)
        "name": "serveo.net",
        "cmd": [
            "ssh", "-tt",
            "-o", "StrictHostKeyChecking=no",
            "-o", "ServerAliveInterval=60",
            "-R", "80:localhost:8000",
            "serveo.net", "-N",
        ],
    },
]

def write_env(url: str):
    url = url.rstrip("/") + "/"
    # читаем, обновляем или добавляем WEBAPP_URL
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

def run_provider(p):
    print(f"[INFO] Пытаюсь запустить туннель через {p['name']} …")
    proc = subprocess.Popen(
        p["cmd"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    got_url = None
    start = time.time()
    try:
        for line in proc.stdout:
            # печатаем «как есть» (может быть ASCII-графика QR — это норм)
            sys.stdout.write(line)
            m = HTTPS_RE.search(line)
            if m:
                got_url = m.group(0)
                write_env(got_url)
                print(f"[OK] Получена ссылка от {p['name']}: {got_url}")
                print("[INFO] НЕ закрывайте это окно — оно держит туннель.")
                return proc  # оставляем процесс жить
            # если очень долго нет URL — считаем, что провайдер молчит
            if time.time() - start > 30 and got_url is None:
                print(f"[WARN] {p['name']} не дал ссылку за 30с. Пробую следующего…")
                break
    finally:
        if got_url is None:
            # аккуратно гасим неудачный процесс
            try:
                proc.terminate()
                proc.wait(timeout=3)
            except Exception:
                pass
    return None

def main():
    for p in PROVIDERS:
        proc = run_provider(p)
        if proc:  # успех, держим окно/процесс
            # бесконечно ждём, пока пользователь не закроет окно
            try:
                proc.wait()
            except KeyboardInterrupt:
                pass
            return
    print("[ERR] Не удалось получить публичный URL ни у одного провайдера.")
    print("     Попробуй запустить скрипт ещё раз или сменить сеть/интернет.")

if __name__ == "__main__":
    main()
