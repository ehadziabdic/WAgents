#!/usr/bin/env node
// sync-release-version.mjs — sync one release version across wagents manifests.
// Integrated from third-party ui-ux/sync-release-version.mjs, adapted to wagents layout.
//
// Usage: node scripts/sync-release-version.mjs <version>
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
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

const manifestTargets = ['manifest.json', 'package.json'];

let touched = 0;
for (const rel of manifestTargets) {
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
  const data = JSON.parse(text);
  if (typeof data.version === 'undefined') {
    console.log(`skip (no version key): ${rel}`);
    continue;
  }
  const before = data.version;
  // Preserve formatting via targeted regex replace on the top-level "version"
  // line (multiline: first line in the file that starts with "version":).
  const next = text.replace(
    /^(\s*"version"\s*:\s*)"[^"]+"/m,
    `$1"${version}"`
  );
  if (next !== text) {
    writeFileSync(fullPath, next, 'utf8');
    touched += 1;
    console.log(`synced: ${rel} (${before} -> ${version})`);
  } else if (before === version) {
    console.log(`already current: ${rel} (${version})`);
  } else {
    console.warn(`warning: could not rewrite ${rel} — manual edit needed`);
  }
}

console.log(`Done. ${touched} manifest(s) synced to ${version}.`);
