#!/usr/bin/env node
// install-mcp.mjs — the single MCP installer for wagents.
//
// Install strategy per server (source of truth: mcp/servers.json, key "install"):
//   1. npm-pinned      — installed globally at an exact pinned version (enforced;
//                        newer globals are replaced). Officially published servers.
//   2. client-managed  — launched by the MCP client on demand via npx/uvx; nothing
//                        to pre-install. The installer only checks the launcher exists.
//   3. remote          — remote HTTP servers; nothing to install, OAuth in the client.
//   4. manual          — needs a non-npm binary, is commercial/project-managed, or has
//                        no trustworthy package; explicit instructions are printed.
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const dryRun = process.argv.includes('--dry-run');
const json = rel => JSON.parse(readFileSync(join(root, rel), 'utf8'));
const servers = json('mcp/servers.json').servers;

// Exact pins verified against the npm registry (official publisher, real bin names).
const NPM_PINS = {
  'codebase-memory': { pkg: 'codebase-memory-mcp', version: '0.10.1' },
  'sentry': { pkg: '@sentry/mcp-server', version: '0.39.0' },
  'supabase': { pkg: '@supabase/mcp-server-supabase', version: '0.12.0' },
  'agentmemory': {
    pkg: '@agentmemory/mcp', version: '0.9.29',
    runtime: { pkg: '@agentmemory/agentmemory', version: '0.9.29' }
  }
};
// Launched on demand by the client through npx/uvx — nothing to pre-install.
const CLIENT_MANAGED_LAUNCHERS = {
  context7: 'npx',
  playwright: 'npx',
  tavily: 'npx',
  semgrep: 'uvx',
  postgres: 'uvx'
};
// Remote HTTP endpoints — nothing to install; OAuth/PAT happens in the client.
const REMOTE = new Set(['github', 'notion']);
// No trustworthy auto-installable package today; explicit instructions are printed.
const MANUAL_NOTES = {
  sonarqube: 'community npm package (sonarqube-mcp-server) is DEPRECATED at 1.10.21 — not auto-installed; check for an official SonarSource server before adopting anything',
  trivy: 'needs the Trivy binary (winget install Trivy.Trivy / brew install trivy / official install script); its MCP mode is built in as `trivy mcp`',
  'react-bits': 'commercial and project-managed — use the official React Bits setup from the project root (see mcp/README.md)'
};

const isNpmPinned = id => Boolean(NPM_PINS[id]);
const isClientManaged = id => Boolean(CLIENT_MANAGED_LAUNCHERS[id]);
const isRemote = id => REMOTE.has(id);
const isManual = id => !isNpmPinned(id) && !isClientManaged(id) && !isRemote(id);

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

function nodeLessThan(minMajor, minMinor) {
  const match = process.versions.node.match(/^(\d+)\.(\d+)/);
  if (!match) return false;
  const major = Number(match[1]);
  const minor = Number(match[2]);
  return major < minMajor || (major === minMajor && minor < minMinor);
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
    const launcher = CLIENT_MANAGED_LAUNCHERS[server.id];
    let plan;
    if (pin) plan = `would check/install ${pin.pkg}@${pin.version}` + (pin.runtime ? ` + runtime ${pin.runtime.pkg}@${pin.runtime.version}` : '') + ' (npm global)';
    else if (launcher) plan = `client-managed via ${launcher} (nothing to pre-install)`;
    else if (isRemote(server.id)) plan = 'remote server (nothing to install; OAuth in the client)';
    else plan = `manual: ${MANUAL_NOTES[server.id] ?? 'see mcp/README.md'}`;
    console.log(`[wagents][dry-run] ${server.id}: ${plan}`);
  }
  console.log('[wagents][dry-run] mcp: done (nothing was installed)');
  process.exit(0);
}

// 1. Install npm-deliverable servers (pinned). Runtime companions install alongside their shim.
const PIN_TARGETS = Object.entries(NPM_PINS).flatMap(([id, pin]) =>
  pin.runtime ? [[id, pin], [id, { pkg: pin.runtime.pkg, version: pin.runtime.version }]] : [[id, pin]]
);
for (const [id, { pkg, version }] of PIN_TARGETS) {
  if (!commandExists('npm')) {
    console.error('[wagents][fail] npm not found; cannot install ' + pkg);
    process.exitCode = 1;
    continue;
  }
  if (id === 'sentry' && nodeLessThan(22, 13)) {
    console.warn(`[wagents][warn] @sentry/mcp-server requires Node >= 22.13 at runtime (you have ${process.versions.node}); installing anyway`);
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

// 1b. agentmemory runtime probe (the stdio shim falls back to 7 local tools without the server).
if (NPM_PINS.agentmemory) {
  try {
    const res = await fetch('http://localhost:3111/livez', { signal: AbortSignal.timeout(1500) });
    console.log(`[wagents] agentmemory server: running (livez ${res.status})`);
  } catch {
    console.warn('[wagents][warn] agentmemory server not reachable at http://localhost:3111 — start it with: npm run memory  (npx -y @agentmemory/agentmemory@latest). On native Windows also extract the pinned iii.exe to %USERPROFILE%\\.agentmemory\\bin, use WSL2, or set AGENTMEMORY_USE_DOCKER=1 (see mcp/README.md).');
  }
}

// 2. Client-managed servers: only the launcher matters.
for (const server of servers) {
  if (!isClientManaged(server.id)) continue;
  const launcher = CLIENT_MANAGED_LAUNCHERS[server.id];
  if (commandExists(launcher)) {
    console.log(`[wagents] ${server.id}: client-managed via ${launcher} — nothing to install`);
  } else {
    console.warn(`[wagents][warn] ${server.id}: ${launcher} not found — install ${launcher} first or configure this server manually (see mcp/README.md)`);
    process.exitCode = 1;
  }
}

// 3. Remote servers: nothing to install.
for (const server of servers) {
  if (isRemote(server.id)) console.log(`[wagents] ${server.id}: remote server — nothing to install; complete ${server.authentication ?? 'OAuth'} in your MCP client`);
}

// 4. Manual servers: never guessed.
const manual = servers.filter(s => isManual(s.id));
if (manual.length) {
  console.log('[wagents] mcp: manual setup required for:');
  for (const server of manual) {
    const env = server.required_env?.length ? ` (env: ${server.required_env.join(', ')})` : '';
    console.log(`  - ${server.id}${env}: ${MANUAL_NOTES[server.id] ?? 'see mcp/README.md'}`);
  }
}
console.log('[wagents] mcp: done');