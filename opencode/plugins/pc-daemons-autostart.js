// pc-daemons-autostart - keeps PC-side daemons running.
// Loaded from ~/.config/opencode/plugins at opencode startup (v2 format).
// Singleton-guarded via pidfile, so repeated loads no-op. Requires
// OPENCODE_TELEGRAM_TOKEN in scripts/.telegram.env for the bot leg.
//
// Gated by scripts/.autostart.json (managed by scripts/autostart-control.ps1):
//   { "telegramBot": true | false }
// Missing file means OFF. Env override OPENCODE_AUTOSTART_TELEGRAM=1/0 wins.
import { spawn, execFileSync } from "node:child_process";
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

// A recycled Windows PID must not count as a running bot, or the autostart
// silently skips after a reboot.
function isBotProcess(pid) {
	if (!pid || !alive(pid)) return false;
	try {
		const out = execFileSync(
			"powershell",
			[
				"-NoProfile",
				"-Command",
				`(Get-CimInstance Win32_Process -Filter "ProcessId=${pid}").CommandLine`,
			],
			{ encoding: "utf-8", timeout: 5000, windowsHide: true },
		);
		return /telegram-pc-bot\.py/.test(out);
	} catch {
		return false;
	}
}

function enabledBySwitch() {
	const env = process.env.OPENCODE_AUTOSTART_TELEGRAM;
	if (env === "0" || env === "false") return false;
	if (env === "1" || env === "true") return true;
	try {
		const stateFile = join(
			os.homedir(),
			".config",
			"opencode",
			"scripts",
			".autostart.json",
		);
		const state = JSON.parse(
			readFileSync(stateFile, "utf-8").replace(/^\uFEFF/, ""),
		);
		return state.telegramBot === true;
	} catch {
		return false;
	}
}

function ensureBot() {
	const scriptsDir = join(os.homedir(), ".config", "opencode", "scripts");
	if (!enabledBySwitch()) {
		console.log(
			"[telegram-bot] autostart off (scripts/.autostart.json or env override)",
		);
		return;
	}
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
		if (isBotProcess(oldPid)) return;
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
		if (isBotProcess(rival)) return;
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
