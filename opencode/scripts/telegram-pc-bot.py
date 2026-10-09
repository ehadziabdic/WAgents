# telegram-pc-bot.py (minimal long-polling, httpx required: pip install httpx)
# Runs as a PC daemon: plugins/telegram-bot-autostart.js spawns it (detached,
# singleton via .telegram-bot.pid) on opencode startup; logs to telegram-bot.log.
# Started manually it just runs in the foreground instead.
import os
import time
import shutil
import subprocess
import tempfile
import threading
import httpx
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass


def load_env_file(path):
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())
    except FileNotFoundError:
        pass


load_env_file(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".telegram.env"))
CONFIG_ROOT = os.path.abspath(
    os.environ.get("WAGENTS_CONFIG", os.path.join(os.path.expanduser("~"), ".config", "opencode"))
)
SCRIPTS_DIR = os.path.join(CONFIG_ROOT, "scripts")
TOKEN = os.environ.get("OPENCODE_TELEGRAM_TOKEN", "")
ALLOWED = os.environ.get("TELEGRAM_ALLOWED_CHAT_ID", "")
if not TOKEN or not ALLOWED:
    raise SystemExit("missing OPENCODE_TELEGRAM_TOKEN or TELEGRAM_ALLOWED_CHAT_ID (see .telegram.env)")
print("BOT-START allowlist ready", flush=True)
API = f"https://api.telegram.org/bot{TOKEN}"
HOME = os.path.abspath(os.path.expanduser("~"))
WAGENTS_DIR = os.path.join(CONFIG_ROOT, ".wagents")
WAGENTS_INBOX = os.path.join(WAGENTS_DIR, "inbox")
MAX_SEND_BYTES = 45 * 1024 * 1024
RCLONE_EXE = shutil.which("rclone") or os.path.expandvars(
    r"C:\Users\eminha\AppData\Local\Microsoft\WinGet\Packages\Rclone.Rclone_Microsoft.Winget.Source_8wekyb3d8bbwe\rclone-v1.75.1-windows-amd64\rclone.exe"
)
INBOX = os.path.join(CONFIG_ROOT, "schedules", "inbox")
_PARAKEET = None
_PARAKEET_DIR = os.path.join(
    os.path.expanduser("~"), ".config", "openchamber", "speech-models", "sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8"
)


def _ffmpeg():
    import shutil
    import glob

    p = shutil.which("ffmpeg")
    if p:
        return p
    cands = glob.glob(
        os.path.expandvars(
            r"C:\Users\eminha\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_*\ffmpeg-*\bin\ffmpeg.exe"
        )
    )
    if cands:
        return sorted(cands)[-1]
    raise RuntimeError("ffmpeg not found")


def transcribe(ogg_path):
    global _PARAKEET
    if _PARAKEET is None:
        import sherpa_onnx

        missing = [
            f
            for f in ("encoder.int8.onnx", "decoder.int8.onnx", "joiner.int8.onnx", "tokens.txt")
            if not os.path.isfile(os.path.join(_PARAKEET_DIR, f))
        ]
        if missing:
            raise RuntimeError(
                "parakeet model files missing in "
                + _PARAKEET_DIR
                + " (OpenChamber may have moved them): "
                + ",".join(missing)
            )
        _PARAKEET = sherpa_onnx.OfflineRecognizer.from_transducer(
            encoder=os.path.join(_PARAKEET_DIR, "encoder.int8.onnx"),
            decoder=os.path.join(_PARAKEET_DIR, "decoder.int8.onnx"),
            joiner=os.path.join(_PARAKEET_DIR, "joiner.int8.onnx"),
            tokens=os.path.join(_PARAKEET_DIR, "tokens.txt"),
            num_threads=4,
            sample_rate=16000,
            feature_dim=128,
            model_type="",
        )
    import numpy as np

    r = subprocess.run(
        [
            _ffmpeg(),
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            ogg_path,
            "-ac",
            "1",
            "-ar",
            "16000",
            "-f",
            "f32le",
            "-acodec",
            "pcm_f32le",
            "-",
        ],
        capture_output=True,
        timeout=300,
    )
    if r.returncode != 0:
        raise RuntimeError("ffmpeg decode failed: " + (r.stderr or b"")[-200:].decode("utf-8", "replace"))
    samples = np.frombuffer(r.stdout, dtype=np.float32)
    stream = _PARAKEET.create_stream()
    stream.accept_waveform(16000, samples)
    _PARAKEET.decode_stream(stream)
    return stream.result.text.strip()


def api(m, **p):
    try:
        return httpx.post(f"{API}/{m}", data=p, timeout=30).json()
    except Exception as e:
        print(f"API-SEND-ERROR {m} " + str(e)[:150], flush=True)
        return {}


def run_ps(script, *args):
    si = subprocess.STARTUPINFO()
    si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    r = subprocess.run(
        ["powershell", "-ExecutionPolicy", "Bypass", "-File", script, *args],
        capture_output=True,
        text=True,
        startupinfo=si,
        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
    )
    return (r.stdout + r.stderr)[:3500]


def jail(path_arg):
    p = os.path.abspath(os.path.join(HOME, path_arg.replace("/", os.sep)))
    if p != HOME and not p.startswith(HOME + os.sep):
        return None
    return p


def read_target_session():
    try:
        sid = open(target_session_path(), encoding="utf-8").read().strip().splitlines()[0].strip()
    except Exception:
        return None
    return sid if sid.startswith("ses") else None


def run_in_session(text):
    sid = read_target_session()
    if not sid:
        return False, "no-target-session"
    try:
        r = subprocess.run(
            [
                "opencode",
                "run",
                "--auto",
                "--model",
                "opencode/muse-spark-1.3-contributor-free",
                "--session",
                sid,
                text,
            ],
            capture_output=True,
            text=True,
            timeout=900,
            cwd=HOME,
        )
    except Exception as e:
        return False, str(e)[:200]
    if r.returncode != 0:
        return False, (r.stderr or r.stdout)[-300:]
    return True, (r.stdout or "").strip()[-3500:]


def run_in_session_thread(cid, text):
    def job():
        try:
            ok, out = run_in_session(text)
            if ok and out:
                for i in range(0, len(out), 4000):
                    api("sendMessage", chat_id=cid, text=out[i : i + 4000])
            else:
                api("sendMessage", chat_id=cid, text="chat run failed: " + (out or "?")[:300])
        except Exception as e:
            try:
                api("sendMessage", chat_id=cid, text="chat run crashed: " + str(e)[:200])
            except Exception:
                pass

    threading.Thread(target=job, daemon=True).start()


SESSIONS_CACHE = {"items": [], "time": 0.0}


def target_session_path():
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), ".voice-target-session")


def set_target_session(sid):
    open(target_session_path(), "w", encoding="utf-8").write(sid.strip() + "\n")


def list_all_sessions():
    import json as _json

    try:
        r = subprocess.run(
            ["opencode", "api", "GET", "/api/session"], capture_output=True, text=True, timeout=60, cwd=HOME
        )
    except Exception as e:
        return None, str(e)[:200]
    if r.returncode != 0:
        return None, ((r.stderr or r.stdout) or "list failed")[-300:]
    try:
        payload = _json.loads(r.stdout or "{}")
    except Exception:
        return None, "unparseable session list"
    items = payload.get("data") if isinstance(payload, dict) else None
    if not isinstance(items, list):
        return None, "unparseable session list"
    return items, ""


def norm_session(s):
    if not isinstance(s, dict):
        return {"id": "?", "title": "(untitled)", "updated": None, "directory": "?"}
    t = s.get("time") or {}
    loc = s.get("location") or {}
    return {
        "id": s.get("id", "?"),
        "title": (s.get("title") or "(untitled)"),
        "updated": t.get("updated") or t.get("created"),
        "directory": loc.get("directory") or s.get("directory") or "?",
    }


def short_dir(path):
    try:
        return os.path.basename(path.replace("\\", "/").rstrip("/")) or path
    except Exception:
        return "?"


def session_age(ms):
    try:
        import time as _t

        d = max(0, _t.time() - float(ms) / 1000.0)
    except Exception:
        return "?"
    if d < 3600:
        return "%dm ago" % max(1, int(d // 60))
    if d < 86400:
        return "%dh ago" % int(d // 3600)
    return "%dd ago" % int(d // 86400)


RETENTION_DAYS = 7
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".heic", ".heif"}
last_sweep = 0.0


def retention_sweep():
    import time as _t

    now = _t.time()
    cutoff = now - RETENTION_DAYS * 86400
    try:
        for fn in os.listdir(WAGENTS_INBOX):
            fp = os.path.join(WAGENTS_INBOX, fn)
            if not os.path.isfile(fp):
                continue
            if os.path.splitext(fn)[1].lower() in IMAGE_EXTS:
                continue
            try:
                if os.path.getmtime(fp) < cutoff:
                    os.remove(fp)
                    print("SWEEP deleted=" + fn, flush=True)
            except Exception:
                pass
    except Exception as e:
        print("SWEEP-INBOX-ERROR " + str(e)[:150], flush=True)
    try:
        sbox = os.path.abspath(INBOX)
        for fn in os.listdir(sbox):
            if not fn.endswith(".sent"):
                continue
            fp = os.path.join(sbox, fn)
            try:
                if os.path.getmtime(fp) < cutoff:
                    os.remove(fp)
                    print("SWEEP deleted=" + fn, flush=True)
            except Exception:
                pass
    except Exception as e:
        print("SWEEP-SENT-ERROR " + str(e)[:150], flush=True)
    try:
        box = os.path.abspath(INBOX)
        os.makedirs(box, exist_ok=True)
        for fn in sorted(os.listdir(box)):
            if not fn.endswith(".json"):
                continue
            fp = os.path.join(box, fn)
            try:
                import json as _json

                msg = _json.load(open(fp, encoding="utf-8-sig")).get("text", "")
                if msg:
                    api("sendMessage", chat_id=ALLOWED, text="[auto] " + msg[:4000])
                os.rename(fp, fp + ".sent")
            except Exception as e:
                print("INBOX-ERROR " + fn + " " + str(e)[:200], flush=True)
    except Exception as e:
        print("INBOX-SCAN-ERROR " + str(e)[:200], flush=True)


off = 0
poll_failures = 0
try:
    _d = httpx.get(f"{API}/getUpdates", params={"timeout": 0}, timeout=15).json()
    for _up in _d.get("result", []):
        off = _up["update_id"] + 1
    print(f"STARTUP drained pending updates, off={off}", flush=True)
except Exception as e:
    print("STARTUP-DRAIN-ERROR " + str(e)[:150], flush=True)
while True:
    try:
        u = httpx.get(f"{API}/getUpdates", params={"timeout": 25, "offset": off}, timeout=35).json()
        poll_failures = 0
    except Exception as e:
        poll_failures += 1
        print(f"POLL-ERROR n={poll_failures} " + str(e)[:150], flush=True)
        time.sleep(min(5 * poll_failures, 60))
        continue
    for up in u.get("result", []):
        off = up["update_id"] + 1
        m = up.get("message", {})
        cid = str(m.get("chat", {}).get("id", ""))
        txt = (m.get("text", "") or "").strip()
        doc = m.get("document")
        ph = m.get("photo")
        if (doc or ph) and cid == ALLOWED:
            fid = doc["file_id"] if doc else sorted(ph, key=lambda x: x.get("file_size", 0))[-1]["file_id"]
            fname = doc.get("file_name", "photo.jpg") if doc else "photo.jpg"
            try:
                meta = httpx.get(f"{API}/getFile", params={"file_id": fid}, timeout=30).json()
                fpath = meta["result"]["file_path"]
                data = httpx.get(f"https://api.telegram.org/file/bot{TOKEN}/{fpath}", timeout=180).content
            except Exception:
                api("sendMessage", chat_id=cid, text="cannot fetch that file")
                continue
            inbox = WAGENTS_INBOX
            os.makedirs(inbox, exist_ok=True)
            dest = os.path.join(inbox, os.path.basename(fname))
            open(dest, "wb").write(data)
            print(f"UPLOAD saved={dest} bytes={len(data)}", flush=True)
            api(
                "sendMessage",
                chat_id=cid,
                text="saved to inbox %s (%d KB)" % (os.path.basename(dest), len(data) // 1024),
            )
            if ph:
                api(
                    "sendMessage",
                    chat_id=cid,
                    text="photo saved. Ask me about it here or in chat (e.g. what does this error say).",
                )
            continue
        if cid != ALLOWED or not txt:
            v = m.get("voice")
            if v and cid == ALLOWED:
                dur = v.get("duration", 0) or 0
                if dur > 300:
                    api("sendMessage", chat_id=cid, text="voice note too long (>5 min), send a shorter one")
                    continue
                if (v.get("file_size", 0) or 0) > 20 * 1024 * 1024:
                    api("sendMessage", chat_id=cid, text="voice file too big for Telegram download (>20MB)")
                    continue
                fid = v["file_id"]
                try:
                    meta = httpx.get(f"{API}/getFile", params={"file_id": fid}, timeout=30).json()
                    fpath = meta["result"]["file_path"]
                    data = httpx.get(f"https://api.telegram.org/file/bot{TOKEN}/{fpath}", timeout=180).content
                except Exception:
                    api("sendMessage", chat_id=cid, text="cannot fetch that voice note")
                    continue
                tmp = tempfile.mktemp(suffix=".ogg")
                try:
                    open(tmp, "wb").write(data)
                    try:
                        heard = transcribe(tmp)
                    except Exception as e:
                        print("VOICE-TRANSCRIBE-ERROR " + str(e)[:200], flush=True)
                        api("sendMessage", chat_id=cid, text="could not transcribe that voice note")
                        continue
                finally:
                    if os.path.exists(tmp):
                        os.remove(tmp)
                if not heard:
                    api("sendMessage", chat_id=cid, text="heard nothing in that voice note, try again")
                    continue
                print(f"VOICE heard={heard[:80]}", flush=True)
                if heard.startswith("/"):
                    txt = heard
                else:
                    api("sendMessage", chat_id=cid, text='heard: "%s" - working on it in chat' % heard[:500])
                    run_in_session_thread(cid, "[voice] " + heard)
                    continue
            if cid != ALLOWED or not txt:
                continue
        print(f"HANDLING cid={cid} txt={txt[:40]}", flush=True)
        root = SCRIPTS_DIR
        if txt.strip() == "/voice":
            api(
                "sendMessage",
                chat_id=cid,
                text="hold the mic and talk - I transcribe on this PC and load it "
                "into chat automatically. Slash commands in voice still run here.",
            )
            continue
        if txt.startswith("/help"):
            api(
                "sendMessage",
                chat_id=cid,
                text=(
                    "/shot - desktop screenshot as photo\n"
                    "/screen <url> [iphone|ipad|desktop] [full] [dark] "
                    "[jpg|webp] [selector <css>] - web screenshot via Iris (Brave) as photo\n"
                    "/status - GPU + running Python processes\n"
                    "/ls <folder> - list files (relative to home, e.g. /ls Documents)\n"
                    "/get <file> - send file to chat, up to 45MB\n"
                    "/drive <file> - upload to Google Drive, replies with link\n"
                    "/zip <path> - zip a file or folder, sends zip or Drive link\n"
                    "/unzip <file.zip> - extract next to archive, replies with listing\n"
                    "/clip - read PC clipboard text\n"
                    "/clip <text> - set PC clipboard text\n"
                    "/upload - send any file/photo in chat, lands in the inbox\n"
                    "/photo - send a picture, then ask about it\n"
                    "/voice - talk (local transcription), loads into chat\n"
                    "/sessions [n] - list ALL sessions (every project), * = current\n"
                    "/switch <n> - talk to session number n from the list\n"
                    "/current - which session you are talking to now\n"
                    "plain text - runs in chat, answer comes back here\n"
                    "/help - this list"
                ),
            )
            continue
        if txt.startswith("/shot"):
            p = ""
            try:
                out_lines = run_ps(os.path.join(root, "screenshot-desktop.ps1")).strip().splitlines()
                p = out_lines[-1] if out_lines else ""
                if not p or not os.path.isfile(p):
                    raise ValueError("no screenshot produced")
                with open(p, "rb") as f:
                    httpx.post(
                        f"{API}/sendPhoto", data={"chat_id": cid, "caption": "desktop"}, files={"photo": f}, timeout=60
                    )
            except Exception as e:
                api("sendMessage", chat_id=cid, text="screenshot failed: " + str(e)[:200])
            try:
                if p and os.path.exists(p):
                    os.remove(p)
            except Exception:
                pass
            continue
        if txt.startswith("/screen"):
            p = ""
            try:
                args = txt[len("/screen") :].strip().split()
                if not args:
                    raise ValueError(
                        "usage: /screen <url> [iphone|ipad|desktop] [full] [dark] [jpg|webp] [selector <css>]"
                    )
                url = args[0]
                if "://" not in url:
                    url = "https://" + url
                size, full, dark, fmt, selector = "desktop", False, False, "png", None
                rest = args[1:]
                i = 0
                while i < len(rest):
                    a = rest[i].lower()
                    if a in ("iphone", "ipad", "desktop"):
                        size = a
                    elif a == "full":
                        full = True
                    elif a == "dark":
                        dark = True
                    elif a in ("jpg", "jpeg", "webp"):
                        fmt = "jpg" if a == "jpeg" else a
                    elif a == "selector" and i + 1 < len(rest):
                        i += 1
                        selector = rest[i]
                    i += 1
                p = os.path.join(tempfile.gettempdir(), f"iris-tg-{int(time.time())}.{fmt}")
                cmd = [
                    os.path.expandvars(r"C:\Users\eminha\.cargo\bin\iris.exe"),
                    "--chrome",
                    r"C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe",
                    "--size",
                    size,
                    "--format",
                    fmt,
                    "-o",
                    p,
                ]
                if full:
                    cmd.append("--full")
                if dark:
                    cmd.append("--dark")
                if selector:
                    cmd += ["--selector", selector, "--padding", "16"]
                else:
                    cmd += ["--scale", "1"]
                cmd.append(url)
                si = subprocess.STARTUPINFO()
                si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
                r = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=120,
                    startupinfo=si,
                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
                )
                if not os.path.isfile(p) or os.path.getsize(p) == 0:
                    raise ValueError("iris failed: " + (r.stdout + r.stderr)[-200:])
                with open(p, "rb") as f:
                    httpx.post(
                        f"{API}/sendPhoto", data={"chat_id": cid, "caption": url[:200]}, files={"photo": f}, timeout=60
                    )
            except Exception as e:
                api("sendMessage", chat_id=cid, text="screen failed: " + str(e)[:200])
            try:
                if p and os.path.exists(p):
                    os.remove(p)
            except Exception:
                pass
            continue
            out = run_ps(os.path.join(root, "sysinfo.ps1"))
            api("sendMessage", chat_id=cid, text=out[:4000] or "no-status")
            continue
        if txt.startswith("/ls"):
            arg = txt[3:].strip() or "."
            p = jail(arg)
            if not p or not os.path.isdir(p):
                api("sendMessage", chat_id=cid, text="no such folder (relative to home): " + arg[:200])
                continue
            items = sorted(os.listdir(p))[:60]
            lines = [("DIR " if os.path.isdir(os.path.join(p, x)) else "FILE ") + x for x in items]
            api("sendMessage", chat_id=cid, text=("\n".join(lines)[:4000] or "(empty)"))
            continue
        if txt.startswith("/get"):
            arg = txt[4:].strip()
            p = jail(arg) if arg else None
            if not p or not os.path.isfile(p):
                api("sendMessage", chat_id=cid, text="no such file (relative to home): " + arg[:200])
                continue
            if os.path.getsize(p) > MAX_SEND_BYTES:
                api("sendMessage", chat_id=cid, text="too big for Telegram (>45MB). Use /drive instead.")
                continue
            try:
                with open(p, "rb") as f:
                    httpx.post(
                        f"{API}/sendDocument",
                        data={"chat_id": cid, "caption": os.path.basename(p)[:200]},
                        files={"document": (os.path.basename(p), f)},
                        timeout=120,
                    )
            except Exception as e:
                api("sendMessage", chat_id=cid, text="send failed: " + str(e)[:200])
            continue
        if txt.startswith("/drive"):
            arg = txt[6:].strip()
            p = jail(arg) if arg else None
            if not p or not os.path.isfile(p):
                api("sendMessage", chat_id=cid, text="no such file (relative to home): " + arg[:200])
                continue
            rclone = shutil.which("rclone") or os.path.expandvars(
                r"C:\Users\eminha\AppData\Local\Microsoft\WinGet\Packages\Rclone.Rclone_Microsoft.Winget.Source_8wekyb3d8bbwe\rclone-v1.75.1-windows-amd64\rclone.exe"
            )
            name = os.path.basename(p)
            up = subprocess.run([rclone, "copy", p, "gdrive:wagents-pc/"], capture_output=True, text=True, timeout=600)
            if up.returncode != 0:
                api("sendMessage", chat_id=cid, text="upload failed: " + (up.stderr[-500:] or up.stdout[-500:]))
                continue
            link = subprocess.run(
                [rclone, "link", "gdrive:wagents-pc/" + name], capture_output=True, text=True, timeout=120
            )
            api("sendMessage", chat_id=cid, text=(link.stdout.strip() or "uploaded, link failed")[:1000])
            continue
        if txt.startswith("/zip"):
            import zipfile
            import tempfile

            arg = txt[4:].strip()
            p = jail(arg) if arg else None
            if not p or not os.path.exists(p):
                api("sendMessage", chat_id=cid, text="no such file/folder (relative to home): " + arg[:200])
                continue
            tmp = tempfile.mktemp(suffix=".zip")
            try:
                if os.path.isdir(p):
                    shutil.make_archive(tmp[:-4], "zip", p)
                else:
                    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as z:
                        z.write(p, os.path.basename(p))
                if os.path.getsize(tmp) > MAX_SEND_BYTES:
                    rclone = shutil.which("rclone") or RCLONE_EXE
                    name = os.path.basename(arg.rstrip("/\\")) + ".zip"
                    subprocess.run([rclone, "copy", tmp, "gdrive:wagents-pc/"], capture_output=True, timeout=600)
                    link = subprocess.run(
                        [rclone, "link", "gdrive:wagents-pc/" + name], capture_output=True, text=True, timeout=120
                    )
                    api(
                        "sendMessage",
                        chat_id=cid,
                        text="zipped %s, too big for chat:\n%s" % (name, link.stdout.strip()[:900]),
                    )
                else:
                    try:
                        with open(tmp, "rb") as f:
                            httpx.post(
                                f"{API}/sendDocument",
                                data={"chat_id": cid},
                                files={"document": (os.path.basename(arg) + ".zip", f)},
                                timeout=180,
                            )
                    except Exception as e:
                        api("sendMessage", chat_id=cid, text="send failed: " + str(e)[:200])
            finally:
                if os.path.exists(tmp):
                    os.remove(tmp)
            continue
        if txt.startswith("/unzip"):
            arg = txt[6:].strip()
            p = jail(arg) if arg else None
            if not p or not os.path.isfile(p) or not p.lower().endswith(".zip"):
                api("sendMessage", chat_id=cid, text="no such zip (relative to home): " + arg[:200])
                continue
            import zipfile

            dest = os.path.join(os.path.dirname(p), os.path.splitext(os.path.basename(p))[0])
            os.makedirs(dest, exist_ok=True)
            with zipfile.ZipFile(p) as z:
                z.extractall(dest)
            api(
                "sendMessage",
                chat_id=cid,
                text="extracted to %s:\n%s"
                % (os.path.relpath(dest, HOME), "\n".join(sorted(os.listdir(dest))[:40])[:3500]),
            )
            continue
        if txt == "/clip" or txt.startswith("/clip "):
            arg = txt[5:].strip()
            if arg:
                out = run_ps(os.path.join(root, "clip-set.ps1"), "-Text", arg)
                api("sendMessage", chat_id=cid, text="clipboard set (%d chars)" % len(arg))
            else:
                out = run_ps(os.path.join(root, "clip-get.ps1"))
                api("sendMessage", chat_id=cid, text=out[:4000] or "(empty)")
            continue
        if txt == "/sessions" or txt.startswith("/sessions "):
            arg = txt[len("/sessions") :].strip()
            try:
                maxn = max(1, min(50, int(arg))) if arg else 20
            except Exception:
                maxn = 20
            raw, err = list_all_sessions()
            if raw is None:
                api("sendMessage", chat_id=cid, text="cannot list sessions: " + (err or "?"))
                continue
            try:
                raw.sort(key=lambda s: ((s.get("time") or {}).get("updated") or 0), reverse=True)
            except Exception:
                pass
            items = [norm_session(s) for s in raw[:maxn]]
            SESSIONS_CACHE["items"] = items
            import time as _tt

            SESSIONS_CACHE["time"] = _tt.time()
            cur = read_target_session()
            lines = []
            for i, s in enumerate(items, 1):
                try:
                    mark = "*" if s["id"] == cur else " "
                    lines.append(
                        "%s%d. %s [%s, %s]"
                        % (mark, i, s["title"][:80], session_age(s["updated"]), short_dir(s["directory"]))
                    )
                except Exception:
                    continue
            body = "\n".join(lines)[:3800] or "(no sessions)"
            api("sendMessage", chat_id=cid, text=body + "\n* = current. Reply /switch <n> to change.")
            continue
        if txt == "/current":
            cur = read_target_session()
            if not cur:
                api("sendMessage", chat_id=cid, text="no target session set")
                continue
            raw, err = list_all_sessions()
            title = None
            if raw:
                for s in raw:
                    if isinstance(s, dict) and s.get("id") == cur:
                        title = s.get("title") or "(untitled)"
                        break
            if title:
                api("sendMessage", chat_id=cid, text="talking to: %s\n%s" % (title[:200], cur))
            else:
                api("sendMessage", chat_id=cid, text="talking to session id:\n" + cur)
            continue
        if txt == "/switch" or txt.startswith("/switch "):
            arg = txt[len("/switch") :].strip()
            items = SESSIONS_CACHE.get("items") or []
            if not items:
                raw, err = list_all_sessions()
                if raw is None:
                    api("sendMessage", chat_id=cid, text="cannot list sessions: " + (err or "?"))
                    continue
                try:
                    raw.sort(key=lambda s: ((s.get("time") or {}).get("updated") or 0), reverse=True)
                except Exception:
                    pass
                items = [norm_session(s) for s in raw[:20]]
                SESSIONS_CACHE["items"] = items
            try:
                n = int(arg)
            except Exception:
                api("sendMessage", chat_id=cid, text="usage: /switch <n> (see /sessions)")
                continue
            if n < 1 or n > len(items):
                api("sendMessage", chat_id=cid, text="no session %d (list has %d, see /sessions)" % (n, len(items)))
                continue
            s = items[n - 1]
            sid = s.get("id", "")
            if not sid.startswith("ses"):
                api("sendMessage", chat_id=cid, text="session %d has no valid id, pick another (see /sessions)" % n)
                continue
            set_target_session(sid)
            api("sendMessage", chat_id=cid, text="switched to %d. %s" % (n, (s.get("title") or "(untitled)")[:200]))
            continue
        api("sendMessage", chat_id=cid, text="working on it in chat")
        run_in_session_thread(cid, "[telegram] " + txt)
    try:
        if time.time() - last_sweep > 3600:
            last_sweep = time.time()
            retention_sweep()
    except Exception as e:
        print("SWEEP-ERROR " + str(e)[:150], flush=True)
