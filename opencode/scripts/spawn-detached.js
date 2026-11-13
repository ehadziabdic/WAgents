// spawn-detached.js - start a long-lived process fully detached, log to file.
// Usage: node spawn-detached.js <exe> <script> <logfile> <cwd>
// Prints the child pid on stdout and exits immediately.
const { spawn } = require("node:child_process");
const { openSync } = require("node:fs");

const [, , exe, script, logfile, cwd] = process.argv;
if (!exe || !script || !logfile) {
	console.error("usage: node spawn-detached.js <exe> <script> <logfile> <cwd>");
	process.exit(2);
}

const out = openSync(logfile, "a");
const child = spawn(exe, [script], {
	detached: true,
	stdio: ["ignore", out, out],
	windowsHide: true,
	cwd: cwd || process.cwd(),
});
child.unref();
process.stdout.write(String(child.pid));
