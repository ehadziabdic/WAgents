#!/usr/bin/env node
// install-mcp.mjs — the single MCP installer for wagents.
// Installs npm-deliverable MCP servers listed in mcp/servers.json (pinned versions)
// and prints explicit setup instructions for everything that must be configured
// manually (remote/OAuth servers, commercial, disabled-by-default).
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const dryRun = process.argv.includes('--dry-run');
const json = rel => JSON.parse(readFileSync(join(root, rel), 'utf8'));
const servers = json('mcp/servers.json').servers;

// Pinned npm-deliverable installs (validated against the npm registry).
const NPM_PINS = {
  'codebase-memory': { pkg: 'codebase-memory-mcp', version: '0.10.1' }
};
const BINARIES = { context7: 'npx', playwright: 'npx' }; // run via npx, nothing to install
const MANUAL = new Set(servers.filter(s => !NPM_PINS[s.id] && !BINARIES[s.id]).map(s => s.id));

function commandExists(name) {
  const probe = process.platform === 'win32' ? 'where.exe' : 'command';
  const probeArgs = process.platform === 'win32' ? [name] : ['-v', name];
  return spawnSync(probe, probeArgs, { stdio: 'ignore', shell: process.platform !== 'win32' }).status === 0;
}

function npm(args, inherit = true) {
  return spawnSync(process.platform === 'win32' ? 'npm.cmd' : 'npm', args, {
    stdio: inherit ? 'inherit' : 'pipe', shell: process.platform === 'win32'
  });
}

console.log('[wagents] mcp: validating servers.json...');
for (const server of servers) {
  if (!server.id || !server.transport || !Array.isArray(server.scope)) {
    console.error(`[wagents][fail] invalid MCP entry: ${JSON.stringify(server)}`);
    process.exitCode = 1;
  }
}
if (process.exitCode) process.exit(process.exitCode);
console.log('[wagents] mcp: servers.json valid');

if (dryRun) {
  for (const server of servers) {
    const pin = NPM_PINS[server.id];
    console.log(`[wagents][dry-run] ${server.id}: ${pin ? `would check/install ${pin.pkg}@${pin.version} (npm global)` : MANUAL.has(server.id) ? 'manual setup (see mcp/README.md)' : 'client-managed via npx/HTTP (nothing to install)'}`);
  }
  console.log('[wagents][dry-run] mcp: done (nothing was installed)');
  process.exit(0);
}

// 1. Install npm-deliverable servers (pinned).
for (const [id, { pkg, version }] of Object.entries(NPM_PINS)) {
  if (!commandExists('npm')) {
    console.error('[wagents][fail] npm not found; cannot install ' + pkg);
    process.exitCode = 1;
    continue;
  }
  const list = npm(['list', '-g', pkg, '--json', '--depth=0'], false);
  let installedVersion;
  if (list.status === 0) {
    try {
      installedVersion = JSON.parse(list.stdout?.toString() ?? '{}').dependencies?.[pkg]?.version;
    } catch {
      console.error(`[wagents][warn] ${pkg}: invalid npm list output; checking by reinstalling the pin`);
    }
  }
  if (installedVersion === version) {
    console.log(`[wagents] ${pkg}: already installed at ${version} (global)`);
    continue;
  }
  console.log(`[wagents] ${pkg}: installing ${pkg}@${version} (npm global)...`);
  const result = npm(['install', '-g', `${pkg}@${version}`]);
  if (result.status !== 0) {
    console.error(`[wagents][warn] ${pkg}: install failed — see mcp/README.md for manual setup`);
    process.exitCode = 1;
  } else {
    console.log(`[wagents] ${pkg}: installed ${version}`);
  }
}

// 2. Report manual/conditional servers (never guessed).
const manual = servers.filter(s => MANUAL.has(s.id));
if (manual.length) {
  console.log('[wagents] mcp: manual setup required for:');
  for (const server of manual) {
    const env = server.required_env?.length ? ` (env: ${server.required_env.join(', ')})` : '';
    console.log(`  - ${server.id}${env} — see mcp/README.md`);
  }
}
console.log('[wagents] mcp: done');