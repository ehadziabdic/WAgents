import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, writeFileSync, existsSync, rmSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
function sandbox(t) {
  const dir = mkdtempSync(join(tmpdir(), 'wagents test '));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  return dir;
}
function cli(cwd, args, env = {}) {
  return spawnSync(process.execPath, [join(root, 'bin/wagents.mjs'), ...args], {
    cwd, encoding: 'utf8', env: { ...process.env, ...env }
  });
}
for (const provider of ['cline', 'claude-code', 'copilot', 'codex', 'antigravity', 'hermes']) {
  test(`install dry-run for ${provider} does not launch subprocesses or write files`, t => {
    const cwd = sandbox(t);
    const preload = join(cwd, 'intercept.cjs');
    const log = join(cwd, 'calls.jsonl');
    writeFileSync(preload, `const cp = require('node:child_process');
const fs = require('node:fs');
cp.spawnSync = (binary, args) => {
 fs.appendFileSync(process.env.WAGENTS_TEST_LOG, JSON.stringify([binary, args]) + '\\n');
 return { status: 0, stdout: Buffer.from(''), stderr: Buffer.from('') };
};
require('node:module').syncBuiltinESMExports();\n`);
    const result = cli(cwd, ['install', '--provider', provider, '--dry-run'], {
      NODE_OPTIONS: `--require="${preload.replaceAll('\\', '/')}"`, WAGENTS_TEST_LOG: log
    });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(existsSync(log), false, existsSync(log) ? readFileSync(log, 'utf8') : '');
    assert.equal(existsSync(join(cwd, '.cline')), false);
    assert.equal(existsSync(join(cwd, '.wagents')), false);
  });
}
test('init creates project instructions, preserves existing files, and can be repeated', t => {
  const cwd = sandbox(t);
  writeFileSync(join(cwd, 'README.md'), 'My project\n');
  let result = cli(cwd, ['init', '.']);
  assert.equal(result.status, 0, result.stderr);
  assert.ok(existsSync(join(cwd, 'AGENTS.md')));
  assert.ok(existsSync(join(cwd, '.github/copilot-instructions.md')));
  writeFileSync(join(cwd, 'AGENTS.md'), 'Custom instructions\n');
  result = cli(cwd, ['init', '.']);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(readFileSync(join(cwd, 'AGENTS.md'), 'utf8'), 'Custom instructions\n');
  assert.equal(readFileSync(join(cwd, 'README.md'), 'utf8'), 'My project\n');
});
test('init dry-run does not create the target directory', t => {
  const cwd = sandbox(t);
  const result = cli(cwd, ['init', 'new project', '--dry-run']);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(existsSync(join(cwd, 'new project')), false);
});

test('build:plugin packages commands/, hooks/, the right skill count, and an empty mcp.json', t => {
  const out = sandbox(t);
  const build = spawnSync(process.execPath, [join(root, 'scripts/build-plugin.mjs'), out], {
    encoding: 'utf8'
  });
  assert.equal(build.status, 0, build.stderr);

  // Slash-command documentation: 7 .md slugs mirrored from the repo commands/ tree.
  const commands = readdirSync(join(out, 'commands'));
  assert.equal(commands.length, 7);
  for (const c of commands) assert.ok(c.endsWith('.md'), c);

  // Expected command slugs mirror the source tree at test time.
  const sourceCommands = readdirSync(join(root, 'commands'));
  for (const c of sourceCommands) assert.ok(commands.includes(c), `missing ${c}`);

  // Lifecycle hooks: hooks.json, run-hook.cmd (referenced by hooks.json), and both session-start scripts.
  const hooks = readdirSync(join(out, 'hooks'));
  assert.equal(hooks.length, 4);
  assert.ok(hooks.includes('hooks.json'));
  assert.ok(hooks.includes('run-hook.cmd'));
  assert.ok(hooks.includes('session-start.ps1'));
  assert.ok(hooks.includes('session-start.sh'));

  // hooks.json SessionStart must point at ${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd so the
  // command resolves once hooks/ is packaged under the plugin root.
  const hooksJson = JSON.parse(readFileSync(join(out, 'hooks/hooks.json'), 'utf8'));
  const sessionStart = hooksJson.hooks && hooksJson.hooks.SessionStart;
  assert.ok(Array.isArray(sessionStart) && sessionStart.length);
  const hookCmd = sessionStart[0].command;
  assert.ok(hookCmd.includes('${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd'), hookCmd);
  assert.ok(hookCmd.includes('session-start.sh'), hookCmd);

  // Full skill set ships everywhere (personal-use repository): the bundle mirrors the source 1:1.
  const sourceSkills = readdirSync(join(root, 'skills'));
  const skills = readdirSync(join(out, 'skills'));
  assert.equal(skills.length, sourceSkills.length);
  for (const s of sourceSkills) assert.ok(skills.includes(s), `missing skill: ${s}`);

  // MCPs are deliberately empty in the portable core (credentials/OAuth/selection are user-specific).
  const mcp = JSON.parse(readFileSync(join(out, 'mcp.json'), 'utf8'));
  assert.deepEqual(mcp.mcpServers, {});

  // plugin.json exposes the CLI command slugs as keywords so hosts can surface /wagents:*.
  const plugin = JSON.parse(readFileSync(join(out, 'plugin.json'), 'utf8'));
  const keywords = plugin.keywords || [];
  for (const slug of sourceCommands.map(c => c.replace(/\.md$/, ''))) {
    assert.ok(keywords.includes(slug), `plugin.json keywords missing /wagents:${slug}`);
  }

  // Generated README must mention the newly packaged commands/ and hooks/ directories.
  const readme = readFileSync(join(out, 'README.md'), 'utf8');
  assert.ok(readme.includes('commands/'), 'README missing commands/');
  assert.ok(readme.includes('hooks/'), 'README missing hooks/');
});

test('build:plugin without argument syncs root manifests (repo root is the plugin)', t => {
  const build = spawnSync(process.execPath, [join(root, 'scripts/build-plugin.mjs')], {
    encoding: 'utf8'
  });
  assert.equal(build.status, 0, build.stderr);
  const version = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')).version;
  const plugin = JSON.parse(readFileSync(join(root, 'plugin.json'), 'utf8'));
  assert.equal(plugin.version, version);
  assert.equal(JSON.parse(readFileSync(join(root, '.claude-plugin/plugin.json'), 'utf8')).name, 'wagents');
  assert.equal(JSON.parse(readFileSync(join(root, '.codex-plugin/plugin.json'), 'utf8')).skills, './skills/');
  const mcp = JSON.parse(readFileSync(join(root, 'mcp.json'), 'utf8'));
  assert.deepEqual(mcp.mcpServers, {});
  const keywords = plugin.keywords || [];
  for (const c of readdirSync(join(root, 'commands'))) {
    assert.ok(keywords.includes(c.replace(/\.md$/, '')), `keywords missing ${c}`);
  }
});

