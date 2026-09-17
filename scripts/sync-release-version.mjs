#!/usr/bin/env node
// sync-release-version.mjs — sync one release version across EVERY version-bearing
// wagents file (repo-root-is-plugin layout).
//
// Usage: node scripts/sync-release-version.mjs <version>
//        npm run release -- 0.4.0
//
// Covered files (missing files are skipped with a notice):
//   VERSION                              plain text
//   manifest.json, package.json          top-level "version"
//   plugin.json                          top-level "version"
//   .claude-plugin/plugin.json           top-level "version"
//   .codex-plugin/plugin.json            top-level "version"
//   .claude-plugin/marketplace.json      ALL "version" keys (nested in plugins[])
//   .github/plugin/marketplace.json      ALL "version" keys (metadata + plugins[])
//   .agents/plugins/marketplace.json     ALL "version" keys (none today; future-proof)
//   config/*.json                        top-level "version"
//
// Formatting is preserved via targeted key replacement (no re-serialization).
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const version = process.argv[2];
if (!version) {
  console.error('Usage: node scripts/sync-release-version.mjs <version>');
  process.exit(1);
}
if (!/^\d+\.\d+\.\d+(?:[-.][0-9A-Za-z.-]+)?$/.test(version)) {
  console.error(`Not a semver string: ${version}`);
  process.exit(1);
}

const jsonTargets = [
  'manifest.json',
  'package.json',
  'plugin.json',
  '.claude-plugin/plugin.json',
  '.codex-plugin/plugin.json',
  '.claude-plugin/marketplace.json',
  '.github/plugin/marketplace.json',
  '.agents/plugins/marketplace.json',
  ...readdirSync(join(root, 'config'))
    .filter((f) => f.endsWith('.json'))
    .map((f) => `config/${f}`),
];

const VERSION_KEY_RE = /("version"\s*:\s*")(\d[^"]*)(")/g;
let touched = 0;
let current = 0;
let failed = 0;

for (const rel of jsonTargets) {
  const fullPath = resolve(root, rel);
  let text;
  try {
    text = readFileSync(fullPath, 'utf8');
  } catch (err) {
    if (err.code === 'ENOENT') {
      console.log(`skip (missing): ${rel}`);
      continue;
    }
    throw err;
  }
  const match = VERSION_KEY_RE.exec(text);
  VERSION_KEY_RE.lastIndex = 0;
  if (!match) {
    console.log(`skip (no version key): ${rel}`);
    continue;
  }
  const before = match[2];
  if (before === version) {
    current += 1;
    console.log(`already current: ${rel} (${version})`);
    continue;
  }
  const next = text.replace(VERSION_KEY_RE, `$1${version}$3`);
  if (next !== text) {
    writeFileSync(fullPath, next, 'utf8');
    touched += 1;
    console.log(`synced: ${rel} (${before} -> ${version})`);
  } else {
    failed += 1;
    console.warn(`warning: could not rewrite ${rel} (had ${before}) — manual edit needed`);
  }
}

// VERSION plain-text file (single source of truth for tags)
const versionFile = resolve(root, 'VERSION');
try {
  const before = readFileSync(versionFile, 'utf8').trim();
  if (before === version) {
    current += 1;
    console.log(`already current: VERSION (${version})`);
  } else {
    writeFileSync(versionFile, `${version}\n`, 'utf8');
    touched += 1;
    console.log(`synced: VERSION (${before} -> ${version})`);
  }
} catch (err) {
  if (err.code === 'ENOENT') {
    writeFileSync(versionFile, `${version}\n`, 'utf8');
    touched += 1;
    console.log(`synced: VERSION (new file -> ${version})`);
  } else {
    throw err;
  }
}

console.log(`Done: ${touched} synced, ${current} already current, ${failed} failed -> ${version}`);
if (failed > 0) process.exit(1);
