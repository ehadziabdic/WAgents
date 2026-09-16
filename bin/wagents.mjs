#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { cpSync, existsSync, mkdirSync, readFileSync } from 'node:fs';
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
  wagents install --provider <name> [--dry-run]
  wagents init [directory]
  wagents provider <name>
  wagents mcp <server-id>

This CLI never installs an MCP, external skill, or plugin without an explicit
provider command from you. See docs/providers.md and mcp/README.md.`);
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
  if (!dryRun) {
    const result = spawnSync(binary, binaryArgs, { stdio: 'inherit' });
    if (result.status !== 0) process.exitCode = result.status ?? 1;
  }
}

// Auto-install npm-based MCPs (codebase-memory-mcp is the primary one)
function installMcps(dryRun) {
  const npmProbe = process.platform === 'win32' ? 'where.exe' : 'command';
  const npmArgs = process.platform === 'win32' ? ['npm'] : ['-v', 'npm'];
  const npmAvailable = spawnSync(npmProbe, npmArgs, { stdio: 'ignore', shell: process.platform !== 'win32' }).status === 0;

  if (!npmAvailable) {
    console.log('[wagents][warn] npm not found — skipping MCP installation');
    console.log('[wagents][info] Other MCPs are configured via mcp/servers.json');
    console.log('[wagents][info]  and should be installed by your MCP client at runtime.');
    return;
  }

  console.log('[wagents] Installing MCPs...');

  // Check if codebase-memory-mcp is already installed
  const listResult = spawnSync('npm', ['list', '-g', 'codebase-memory-mcp'], { stdio: 'pipe', shell: process.platform === 'win32' });
  const alreadyInstalled = listResult.status === 0 && listResult.stdout.toString().includes('codebase-memory-mcp');

  if (alreadyInstalled) {
    console.log('[wagents] codebase-memory-mcp already installed globally');
  } else {
    console.log('[wagents] Installing codebase-memory-mcp@0.10.0 (npm global)...');
    const installResult = spawnSync('npm', ['install', '-g', 'codebase-memory-mcp@0.10.0'], {
      stdio: dryRun ? 'pipe' : 'inherit',
      shell: process.platform === 'win32'
    });
    if (installResult.status !== 0) {
      console.error('[wagents][warn] Failed to install codebase-memory-mcp globally');
    } else {
      console.log('[wagents] codebase-memory-mcp installed');
    }
  }

  console.log('[wagents] MCP installation complete.');
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
    const provider = option('--provider');
    const dryRun = args.includes('--dry-run');
    if (!provider || !providers[provider]) {
      console.error('Choose one provider explicitly: wagents install --provider <name> [--dry-run]');
      process.exitCode = 1;
      break;
    }
    // Auto-install npm-based MCPs before provider plugin installation
    installMcps(dryRun);
    runNode('scripts/build-plugin.mjs');
    if (process.exitCode) break;
    if (!commandExists(provider === 'claude-code' ? 'claude' : provider === 'antigravity' ? 'agy' : provider)) {
      console.error(`[wagents] ${providers[provider].display_name} command is not installed or not on PATH.`);
      process.exitCode = 1;
      break;
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
      showOrRun('agy', ['plugin', 'install', join(root, 'plugins', 'wagents')], dryRun);
    } else if (provider === 'cline') {
      const target = join(process.cwd(), '.cline', 'skills');
      console.log(`Copy skills to ${target}`);
      if (!dryRun) {
        mkdirSync(target, { recursive: true });
        cpSync(join(root, 'plugins', 'wagents', 'skills'), target, { recursive: true, force: false, errorOnExist: true });
      }
    } else if (provider === 'hermes') {
      showOrRun('hermes', ['plugins', 'install', root, '--enable'], dryRun);
    }
    break;
  }
  case 'init': {
    const target = resolve(process.cwd(), args[1] ?? '.');
    const source = join(root, 'templates', 'project');
    if (!existsSync(source)) throw new Error('Project template is missing.');
    mkdirSync(target, { recursive: true });
    cpSync(source, target, { recursive: true, force: false, errorOnExist: true });
    console.log(`[wagents] project template copied to ${target}`);
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
