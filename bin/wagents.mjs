#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { cpSync, copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const args = process.argv.slice(2);
const command = args[0] ?? 'help';
const providers = JSON.parse(readFileSync(join(root, 'config/providers.json'), 'utf8')).providers;
const agents = JSON.parse(readFileSync(join(root, 'config/agents.json'), 'utf8')).agents;
const skills = JSON.parse(readFileSync(join(root, 'config/skills.json'), 'utf8')).skills;

function usage() {
  console.log(`wagents ${JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')).version}

Usage:
  wagents list [agents|skills|providers]
  wagents doctor
  wagents build
  wagents install --provider <name> [--dry-run] [--skip-mcps]
      providers: claude-code, codex, copilot, antigravity, cline, hermes, deepseek-harness
  wagents init [directory]
  wagents provider <name>
  wagents mcp <server-id>

Works on Linux, macOS, and Windows (Windows spawns provider CLIs through cmd.exe so
npm .cmd shims resolve; bash scripts need Git Bash/WSL, PowerShell entry points are
provided: install.ps1, bin/wagents.ps1, scripts/doctor.ps1, scripts/update.ps1).

This CLI never installs an MCP, external skill, or plugin without an explicit
provider command from you. See config/providers.json and mcp/README.md.`);
}

function runNode(script) {
  const result = spawnSync(process.execPath, [join(root, script)], { stdio: 'inherit' });
  process.exitCode = result.status ?? 1;
}

function option(name) {
  const index = args.indexOf(name);
  return index === -1 ? undefined : args[index + 1];
}

function commandExists(name) {
  const probe = process.platform === 'win32' ? 'where.exe' : 'command';
  const probeArgs = process.platform === 'win32' ? [name] : ['-v', name];
  return spawnSync(probe, probeArgs, { stdio: 'ignore', shell: process.platform !== 'win32' }).status === 0;
}

function showOrRun(binary, binaryArgs, dryRun) {
  console.log(`$ ${[binary, ...binaryArgs].join(' ')}`);
  if (dryRun) return;
  let result;
  if (process.platform === 'win32') {
    // npm-installed CLIs (claude, codex, copilot, npx, ...) are .cmd shims on Windows;
    // they only spawn through cmd.exe, and shell mode joins args, so pre-quote spaces.
    const line = [binary, ...binaryArgs.map(a => (/\s/.test(a) ? `"${a}"` : a))].join(' ');
    result = spawnSync(line, { stdio: 'inherit', shell: true });
  } else {
    result = spawnSync(binary, binaryArgs, { stdio: 'inherit' });
  }
  if (result.status !== 0) process.exitCode = result.status ?? 1;
}

// Auto-install npm-based MCPs via the single MCP installer
function installMcps(dryRun) {
  if (dryRun) {
    console.log('[wagents][dry-run] Would run scripts/install-mcp.mjs (installs pinned npm MCPs, prints manual setup for the rest)');
    return;
  }
  const result = spawnSync(process.execPath, [join(root, 'scripts', 'install-mcp.mjs')], { stdio: 'inherit' });
  if (result.status !== 0) console.error('[wagents][warn] MCP installation reported problems — continuing with provider setup');
}

switch (command) {
  case 'list': {
    const subject = args[1] ?? 'all';
    if (subject === 'all' || subject === 'agents') for (const agent of agents) console.log(`agent  ${agent.id}\t${agent.role}`);
    if (subject === 'all' || subject === 'skills') for (const skill of skills) console.log(`skill  ${skill.name}\t${skill.status}`);
    if (subject === 'all' || subject === 'providers') for (const [id, provider] of Object.entries(providers)) console.log(`provider  ${id}\t${provider.status}`);
    break;
  }
  case 'doctor':
    runNode('scripts/verify.mjs');
    break;
  case 'build':
    runNode('scripts/build-plugin.mjs');
    break;
  case 'install': {
    const provider = option('--provider') ?? 'copilot';
    const dryRun = args.includes('--dry-run');
    const skipMcps = args.includes('--skip-mcps');
    if (!providers[provider]) {
      console.error(`Unknown provider: ${provider}. Run: wagents list providers`);
      process.exitCode = 1;
      break;
    }
    // Auto-install npm-based MCPs before provider plugin installation
    if (!skipMcps) installMcps(dryRun);
    if (dryRun) {
      console.log(`[wagents][dry-run] Would build the portable plugin, then run the ${providers[provider].display_name} install steps below.`);
    } else {
      runNode('scripts/build-plugin.mjs');
      if (process.exitCode) break;
      const binaryMap = { 'claude-code': 'claude', antigravity: 'agy', 'deepseek-harness': null };
      const requiredBinary = provider in binaryMap ? binaryMap[provider] : provider;
      if (requiredBinary && !commandExists(requiredBinary)) {
        console.error(`[wagents] ${providers[provider].display_name} command is not installed or not on PATH.`);
        process.exitCode = 1;
        break;
      }
    }
    if (provider === 'claude-code') {
      showOrRun('claude', ['plugin', 'marketplace', 'add', root], dryRun);
      showOrRun('claude', ['plugin', 'install', 'wagents@wagents'], dryRun);
    } else if (provider === 'codex') {
      showOrRun('codex', ['plugin', 'marketplace', 'add', root], dryRun);
      showOrRun('codex', ['plugin', 'add', 'wagents@wagents'], dryRun);
    } else if (provider === 'copilot') {
      showOrRun('copilot', ['plugin', 'marketplace', 'add', root], dryRun);
      showOrRun('copilot', ['plugin', 'install', 'wagents@wagents'], dryRun);
    } else if (provider === 'antigravity') {
      showOrRun('agy', ['plugin', 'install', root], dryRun);
    } else if (provider === 'cline') {
      const target = join(process.cwd(), '.cline', 'skills');
      console.log(`Copy skills to ${target} (full skill set)`);
      if (!dryRun) {
        mkdirSync(target, { recursive: true });
        cpSync(join(root, 'skills'), target, { recursive: true, force: false, errorOnExist: true });
      }
    } else if (provider === 'hermes') {
      showOrRun('hermes', ['plugins', 'install', root, '--enable'], dryRun);
    } else if (provider === 'deepseek-harness') {
      // dsh is npx-first with a loader-config plugin model (no marketplace subcommand in
      // the developer preview). Everything below is printed, never executed: dsh ships
      // compatibility-breaking changes and wagents never rewrites a user's cordis.yml.
      console.log(`dsh (DeepSeek Harness) is npx-first — no marketplace subcommand yet. Setup steps:
  1. Start the harness:       npx -y @deepseek-ai/dsh web   (Web UI http://127.0.0.1:3080; dsh itself needs Node ^22.19 || >=24)
  2. Make this repo loadable: npm install github:ehadziabdic/wagents   (in the dsh workspace)
  3. Register the plugin in cordis.yml:
       plugins:
         wagents:
  4. MCP servers: add them to $DSH_HOME/cordis.patch.yml (the home-level patch layer every
     profile loads); tools surface as mcp__agentmemory__* etc. See skills/agentmemory-agents/REFERENCE.md.
  5. Auto-capture hooks: dsh bridges Claude Code hooks — wire the hooks/agentmemory/*.mjs
     scripts through dsh's hook bridge if you want memory hooks (see mcp/README.md).
  Note: developer preview — compatibility-breaking changes are expected; pin the dsh version you test with.`);
    }
    break;
  }
  case 'init': {
    const dryRun = args.includes('--dry-run');
    const target = resolve(process.cwd(), args.find(a => !a.startsWith('--') && a !== args[0]) ?? '.');
    const source = join(root, 'templates', 'project');
    if (dryRun) {
      console.log(`[wagents][dry-run] Would copy missing files from ${source} to ${target} (existing files are never overwritten).`);
      break;
    }
    if (!existsSync(source)) throw new Error('Project template is missing.');
    let copied = 0;
    const copyMissing = (src, dest) => {
      mkdirSync(dest, { recursive: true });
      for (const entry of readdirSync(src, { withFileTypes: true })) {
        const from = join(src, entry.name);
        const to = join(dest, entry.name);
        if (entry.isDirectory()) copyMissing(from, to);
        else if (!existsSync(to)) { copyFileSync(from, to); copied += 1; }
      }
    };
    copyMissing(source, target);
    console.log(`[wagents] init complete: ${copied} file(s) copied to ${target}; existing files were not overwritten.`);
    break;
  }
  case 'provider': {
    const id = args[1];
    if (!providers[id]) throw new Error(`Unknown provider: ${id ?? '(missing)'}. Run: wagents list providers`);
    console.log(`${providers[id].display_name} (${providers[id].status})`);
    for (const line of providers[id].install) console.log(`  ${line}`);
    console.log(`  MCP: ${providers[id].mcp}`);
    break;
  }
  case 'mcp': {
    const id = args[1];
    if (!id) throw new Error('Usage: wagents mcp <server-id>');
    // Load MCP servers config and give setup instructions
    try {
      const mcpConfig = JSON.parse(readFileSync(join(root, 'mcp', 'servers.json'), 'utf8'));
      const server = mcpConfig.servers.find(s => s.id === id);
      if (!server) throw new Error(`Unknown MCP server: ${id}. Run: wagents mcp --list`);
      console.log(`MCP Server: ${server.id}`);
      if (server.install) console.log(`  Install: ${server.install}`);
      console.log(`  Status: ${server.status}`);
      console.log(`  Transport: ${server.transport}`);
      console.log(`  Scope: ${server.scope.join(', ')}`);
      if (server.notes) console.log(`  Notes: ${server.notes}`);
      console.log(`\nSee mcp/README.md for the full ${id} setup and required consent/credentials.`);
      if (server.upstream) console.log(`\nUpstream: ${server.upstream}`);
      if (server.required_env?.length) console.log(`\nRequired env vars: ${server.required_env.join(', ')}`);
      if (server.pinned_release) console.log(`\nPinned release: ${server.pinned_release}`);
    } catch (err) {
      if (err.code === 'MODULE_NOT_FOUND') {
        console.log(`See mcp/README.md for the verified ${id} setup and required consent/credentials.`);
      } else {
        throw err;
      }
    }
    break;
  }
  case 'help':
  case '--help':
  case '-h':
    usage();
    break;
  default:
    usage();
    process.exitCode = 1;
}
