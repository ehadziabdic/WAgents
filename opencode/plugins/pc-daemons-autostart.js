// pc-daemons-autostart - keeps PC-side daemons running.
// Loaded from ~/.config/opencode/plugins at opencode startup (v2 format).
// Singleton-guarded via pidfile, so repeated loads no-op. Requires
// OPENCODE_TELEGRAM_TOKEN in scripts/.telegram.env for the bot leg.
import { spawn } from "node:child_process";
import {
	existsSync,
	readFileSync,
	writeFileSync,
	unlinkSync,
	openSync,
} from "node:fs";
import { join } from "node:path";
import os from "node:os";

const PYTHON =
	"C:\\Users\\eminha\\AppData\\Local\\Programs\\Python\\Python313\\python.exe";

function alive(pid) {
	try {
		process.kill(pid, 0);
		return true;
	} catch {
		return false;
	}
}

function ensureBot() {
	const scriptsDir = join(os.homedir(), ".config", "opencode", "scripts");
	const botPy = join(scriptsDir, "telegram-pc-bot.py");
	const pidFile = join(scriptsDir, ".telegram-bot.pid");
	const logFile = join(scriptsDir, "telegram-bot.log");
	const envFile = join(scriptsDir, ".telegram.env");
	if (!existsSync(botPy) || !existsSync(PYTHON)) return;
	let token = "";
	try {
		const m = readFileSync(envFile, "utf-8").match(
			/^OPENCODE_TELEGRAM_TOKEN\s*=\s*(\S+)/m,
		);
		if (m) token = m[1];
	} catch {
		token = "";
	}
	if (!token) {
		console.log(
			"[telegram-bot] skipped: no OPENCODE_TELEGRAM_TOKEN in .telegram.env",
		);
		return;
	}
	try {
		const oldPid = parseInt(readFileSync(pidFile, "utf-8").trim(), 10);
		if (oldPid && alive(oldPid)) return;
	} catch {
		// no pidfile or unreadable: proceed to claim
	}
	try {
		writeFileSync(pidFile, `starting:${process.pid}`, { flag: "wx" });
	} catch {
		let rival = NaN;
		try {
			rival = parseInt(readFileSync(pidFile, "utf-8").trim(), 10);
		} catch {
			rival = NaN;
		}
		if (rival && alive(rival)) return;
		try {
			unlinkSync(pidFile);
		} catch {
			return;
		}
		try {
			writeFileSync(pidFile, `starting:${process.pid}`, { flag: "wx" });
		} catch {
			return;
		}
	}
	const out = openSync(logFile, "a");
	const child = spawn(PYTHON, [botPy], {
		detached: true,
		stdio: ["ignore", out, out],
		windowsHide: true,
		cwd: scriptsDir,
	});
	child.unref();
	writeFileSync(pidFile, String(child.pid));
	console.log(`[telegram-bot] started pid=${child.pid}`);
}

export default {
	id: "pc-daemons-autostart",
	async setup() {
		try {
			ensureBot();
		} catch (e) {
			console.log(
				`[telegram-bot] autostart failed: ${String(e?.message || e)}`,
			);
		}
	},
};
