import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
function run(t, version, extra = [], listStatus = 0) {
  const dir = mkdtempSync(join(tmpdir(), 'wagents mcp test '));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const preload = join(dir, 'intercept.cjs');
  const log = join(dir, 'calls.jsonl');
  writeFileSync(log, '');
  writeFileSync(preload, `const cp = require('node:child_process');
const fs = require('node:fs');
cp.spawnSync = (binary, args) => {
  fs.appendFileSync(process.env.WAGENTS_TEST_LOG, JSON.stringify([binary, args]) + '\\n');
  return { status: args[0] === 'list' ? ${listStatus} : 0,
    stdout: Buffer.from(${JSON.stringify(JSON.stringify({ dependencies: version ? { 'codebase-memory-mcp': { version } } : {} }))}) };
};
require('node:module').syncBuiltinESMExports();
`);
  const result = spawnSync(process.execPath, [join(root, 'scripts/install-mcp.mjs'), ...extra], {
    cwd: dir, encoding: 'utf8', env: { ...process.env,
      NODE_OPTIONS: `--require="${preload.replaceAll('\\', '/')}"`, WAGENTS_TEST_LOG: log }
  });
  assert.equal(result.status, 0, result.stderr);
  return { result, calls: readFileSync(log, 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse) };
}
for (const version of [undefined, '0.10.0', '0.10.1', '0.10.2']) {
  test(`MCP pin check: installed ${version ?? 'nothing'}`, t => {
    const { calls } = run(t, version);
    const list = calls.find(([, args]) => args[0] === 'list');
    assert.ok(list[1].includes('--json'));
    const installs = calls.filter(([, args]) => args[0] === 'install');
    // The mock registry only reports codebase-memory-mcp; the other two official
    // pins (@sentry/mcp-server, @supabase/mcp-server-supabase) always (re)install.
    assert.equal(installs.length, version === '0.10.1' ? 2 : 3);
    const expected = ['codebase-memory-mcp@0.10.1', '@sentry/mcp-server@0.39.0', '@supabase/mcp-server-supabase@0.12.0']
      .filter(pin => pin !== 'codebase-memory-mcp@0.10.1' || version !== '0.10.1');
    for (const pin of expected) {
      assert.ok(installs.some(([, args]) => args.includes(pin)), `missing install of ${pin}`);
    }
  });
}
test('MCP dry-run never launches subprocesses', t => {
  const { calls, result } = run(t, undefined, ['--dry-run']);
  assert.deepEqual(calls, []);
  assert.match(result.stdout, /nothing was installed/);
});
test('failed npm list does not count as an installed pin', t => {
  const { calls } = run(t, '0.10.1', [], 1);
  assert.equal(calls.filter(([, args]) => args[0] === 'install').length, 3);
});
