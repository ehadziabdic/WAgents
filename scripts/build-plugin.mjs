#!/usr/bin/env node
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const output = join(root, 'plugins', 'wagents');
const packageJson = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
const repository = packageJson.repository.url.replace(/^git\+/, '');

function writeJson(relativePath, value) {
  const target = join(output, relativePath);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, `${JSON.stringify(value, null, 2)}\n`);
}

function copy(relativeSource, relativeTarget = relativeSource) {
  const source = join(root, relativeSource);
  if (!existsSync(source)) throw new Error(`Missing source: ${relativeSource}`);
  cpSync(source, join(output, relativeTarget), { recursive: true });
}

rmSync(output, { recursive: true, force: true });
mkdirSync(output, { recursive: true });

copy('.github/skills', 'skills');
copy('.github/agents', 'agents');
copy('.github/instructions', 'instructions');
copy('LICENSE');
// Per-skill licenses and provenance are retained by the recursive skills copy.

// License gates: claude-red is a local authorized-only full copy and the office-skill
// bodies carry Proprietary wording, so strip them from the portable core plugin.
rmSync(join(output, 'skills', 'base-hacker-claude-red'), { recursive: true, force: true });
for (const officeSkill of ['anth-docx', 'anth-pdf', 'anth-pptx', 'anth-xlsx']) {
  rmSync(join(output, 'skills', officeSkill), { recursive: true, force: true });
}

const coreManifest = {
  '$schema': 'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json',
  name: 'wagents',
  version: packageJson.version,
  description: packageJson.description,
  author: { name: 'wagents maintainers' },
  homepage: packageJson.homepage,
  repository,
  license: 'MIT',
  keywords: packageJson.keywords
};

writeJson('plugin.json', coreManifest);
writeJson('.claude-plugin/plugin.json', {
  name: 'wagents',
  version: packageJson.version,
  description: packageJson.description,
  author: { name: 'wagents maintainers' },
  homepage: packageJson.homepage,
  repository,
  license: 'MIT'
});
writeJson('.codex-plugin/plugin.json', {
  name: 'wagents',
  version: packageJson.version,
  description: packageJson.description,
  author: { name: 'wagents maintainers' },
  homepage: packageJson.homepage,
  repository,
  license: 'MIT',
  skills: './skills/'
});

// MCPs need user-specific credentials, OAuth consent, and per-agent selection.
// Keep the portable core deliberately empty and generate client configuration from mcp/servers.json.
writeJson('mcp.json', {
  '$schema': 'https://agent-plugins.org/schemas/1.0.0/mcp.schema.json',
  mcpServers: {}
});
writeFileSync(join(output, 'README.md'), `# wagents plugin\n\nThis directory is generated from the repository source by \`npm run build:plugin\`.\n\nSkills and agent roles are portable. MCP connections are intentionally not bundled: they can require OAuth, local vault access, paid licenses, or privileged credentials. Use the repository [MCP setup guide](../../mcp/README.md).\n`);
console.log(`[wagents] built portable plugin at ${output}`);
