# telegram-pc-bot.py (minimal long-polling, httpx required: pip install httpx)
# Runs in-session only (no scheduled task): it answers while this PC + session are awake.
import os, time, shutil, subprocess, tempfile, threading, httpx
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
CONFIG_ROOT = os.path.abspath(os.environ.get("WAGENTS_CONFIG", os.path.join(os.path.expanduser("~"), ".config", "opencode")))
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
RCLONE_EXE = shutil.which("rclone")
INBOX = os.path.join(CONFIG_ROOT, "schedules", "inbox")
_WHISPER = None
def transcribe(ogg_path):
    global _WHISPER
    if _WHISPER is None:
        from faster_whisper import WhisperModel
        _WHISPER = WhisperModel("small", device="cpu", compute_type="int8")
    segs, _ = _WHISPER.transcribe(ogg_path)
    return "".join(s.text for s in segs).strip()
def api(m, **p):
    return httpx.post(f"{API}/{m}", data=p, timeout=30).json()
def run_ps(script, *args):
    r = subprocess.run(["powershell","-ExecutionPolicy","Bypass","-File",script,*args],capture_output=True,text=True)
    return (r.stdout + r.stderr)[:3500]
def jail(path_arg):
    p = os.path.abspath(os.path.join(HOME, path_arg.replace("/", os.sep)))
    if p != HOME and not p.startswith(HOME + os.sep):
        return None
    return p
def read_target_session():
    try:
        sidf = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".voice-target-session")
        sid = open(sidf, encoding="utf-8").read().strip().splitlines()[0].strip()
    except Exception:
        return None
    return sid if sid.startswith("ses") else None
def run_in_session(text):
    sid = read_target_session()
    if not sid:
        return False, "no-target-session"
    try:
        r = subprocess.run(["opencode", "run", "--session", sid, text],
                           capture_output=True, text=True, timeout=900, cwd=HOME)
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
                    api("sendMessage", chat_id=cid, text=out[i:i+4000])
            else:
                api("sendMessage", chat_id=cid, text="chat run failed: " + (out or "?")[:300])
        except Exception as e:
            try:
                api("sendMessage", chat_id=cid, text="chat run crashed: " + str(e)[:200])
            except Exception:
                pass
    threading.Thread(target=job, daemon=True).start()
off = 0
poll_failures = 0
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
        off = up["update_id"]+1
        m = up.get("message", {})
        cid = str(m.get("chat",{}).get("id",""))
        txt = (m.get("text","") or "").strip()
        doc = m.get("document")
        ph = m.get("photo")
        if (doc or ph) and cid == ALLOWED:
            fid = doc["file_id"] if doc else sorted(ph, key=lambda x: x.get("file_size", 0))[-1]["file_id"]
            fname = doc.get("file_name", "photo.jpg") if doc else "photo.jpg"
            meta = httpx.get(f"{API}/getFile", params={"file_id": fid}, timeout=30).json()
            if not meta.get("ok"):
                api("sendMessage", chat_id=cid, text="cannot fetch that file")
                continue
            fpath = meta["result"]["file_path"]
            data = httpx.get(f"https://api.telegram.org/file/bot{TOKEN}/{fpath}", timeout=180).content
            inbox = WAGENTS_INBOX
            os.makedirs(inbox, exist_ok=True)
            dest = os.path.join(inbox, os.path.basename(fname))
            open(dest, "wb").write(data)
            print(f"UPLOAD saved={dest} bytes={len(data)}", flush=True)
            api("sendMessage", chat_id=cid, text="saved to inbox %s (%d KB)" % (os.path.basename(dest), len(data)//1024))
            if ph:
                api("sendMessage", chat_id=cid, text="photo saved. Ask me about it here or in chat (e.g. what does this error say).")
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
                meta = httpx.get(f"{API}/getFile", params={"file_id": fid}, timeout=30).json()
                if not meta.get("ok"):
                    api("sendMessage", chat_id=cid, text="cannot fetch that voice note")
                    continue
                fpath = meta["result"]["file_path"]
                data = httpx.get(f"https://api.telegram.org/file/bot{TOKEN}/{fpath}", timeout=180).content
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
            if cid != ALLOWED or not txt: continue
        print(f"HANDLING cid={cid} txt={txt[:40]}", flush=True)
        root = SCRIPTS_DIR
        if txt.strip() == "/voice":
            api("sendMessage", chat_id=cid, text="hold the mic and talk - I transcribe on this PC and load it into chat automatically. Slash commands in voice still run here.")
            continue
        if txt.startswith("/help"):
            api("sendMessage", chat_id=cid, text=(
                "/shot - desktop screenshot as photo\n"
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
                "plain text - runs in chat, answer comes back here\n"
                "/help - this list"))
            continue
        if txt.startswith("/shot"):
            p = run_ps(os.path.join(root,"screenshot-desktop.ps1")).strip().splitlines()[-1]
            with open(p,"rb") as f:
                httpx.post(f"{API}/sendPhoto", data={"chat_id":cid,"caption":"desktop"}, files={"photo":f}, timeout=60)
            os.remove(p) if os.path.exists(p) else None
            continue
        if txt.startswith("/status"):
            out = run_ps(os.path.join(root,"sysinfo.ps1"))
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
            with open(p, "rb") as f:
                httpx.post(f"{API}/sendDocument", data={"chat_id": cid, "caption": os.path.basename(p)[:200]}, files={"document": (os.path.basename(p), f)}, timeout=120)
            continue
        if txt.startswith("/drive"):
            import shutil
            arg = txt[6:].strip()
            p = jail(arg) if arg else None
            if not p or not os.path.isfile(p):
                api("sendMessage", chat_id=cid, text="no such file (relative to home): " + arg[:200])
                continue
            rclone = shutil.which("rclone")
            if not rclone:
                api("sendMessage", chat_id=cid, text="rclone not on PATH. Install it, then retry.")
                continue
            name = os.path.basename(p)
            up = subprocess.run([rclone, "copy", p, "gdrive:wagents-pc/"], capture_output=True, text=True, timeout=600)
            if up.returncode != 0:
                api("sendMessage", chat_id=cid, text="upload failed: " + (up.stderr[-500:] or up.stdout[-500:]))
                continue
            link = subprocess.run([rclone, "link", "gdrive:wagents-pc/" + name], capture_output=True, text=True, timeout=120)
            api("sendMessage", chat_id=cid, text=(link.stdout.strip() or "uploaded, link failed")[:1000])
            continue
        if txt.startswith("/zip"):
            import zipfile, tempfile
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
                    if not rclone:
                        api("sendMessage", chat_id=cid, text="rclone not on PATH. Install it, then retry.")
                        continue
                    name = os.path.basename(arg.rstrip("/\\")) + ".zip"
                    subprocess.run([rclone, "copy", tmp, "gdrive:wagents-pc/"], capture_output=True, timeout=600)
                    link = subprocess.run([rclone, "link", "gdrive:wagents-pc/" + name], capture_output=True, text=True, timeout=120)
                    api("sendMessage", chat_id=cid, text="zipped %s, too big for chat:\n%s" % (name, link.stdout.strip()[:900]))
                else:
                    with open(tmp, "rb") as f:
                        httpx.post(f"{API}/sendDocument", data={"chat_id": cid}, files={"document": (os.path.basename(arg) + ".zip", f)}, timeout=180)
            finally:
                if os.path.exists(tmp): os.remove(tmp)
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
            api("sendMessage", chat_id=cid, text="extracted to %s:\n%s" % (os.path.relpath(dest, HOME), "\n".join(sorted(os.listdir(dest))[:40])[:3500]))
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
        api("sendMessage", chat_id=cid, text="working on it in chat")
        run_in_session_thread(cid, "[telegram] " + txt)
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
    global last_sweep
    try:
        if time.time() - last_sweep > 3600:
            last_sweep = time.time()
            retention_sweep()
    except Exception as e:
        print("SWEEP-ERROR " + str(e)[:150], flush=True)
    time.sleep(1)
