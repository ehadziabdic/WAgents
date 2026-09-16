#!/usr/bin/env node
import { cpSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const output = process.argv[2]
  ? resolve(process.argv[2])
  : join(root, 'plugins', 'wagents');
const packageJson = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
const repository = packageJson.repository.url.replace(/^git\+/, '');
const commandSlugs = readdirSync(join(root, 'commands'))
  .filter(f => f.endsWith('.md'))
  .map(f => f.replace(/\.md$/, ''))
  .sort();

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

rmSync(output, { recursive: true, force: true, maxRetries: 10, retryDelay: 100 });
mkdirSync(output, { recursive: true });

copy('skills', 'skills');
copy('agents', 'agents');
copy('instructions', 'instructions');
copy('LICENSE');
// Per-skill licenses and provenance are retained by the recursive skills copy.

// License gates: claude-red is a local authorized-only full copy and the office-skill
// bodies carry Proprietary wording, so strip them from the portable core plugin.
rmSync(join(output, 'skills', 'base-hacker-claude-red'), { recursive: true, force: true });
for (const officeSkill of ['anth-docx', 'anth-pdf', 'anth-pptx', 'anth-xlsx']) {
  rmSync(join(output, 'skills', officeSkill), { recursive: true, force: true });
}

// Slash-command documentation and lifecycle hooks are portable and live under the plugin root.
// hooks.json references ${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd, so the whole hooks/ tree is packaged.
copy('commands', 'commands');
copy('hooks', 'hooks');

const coreManifest = {
  '$schema': 'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json',
  name: 'wagents',
  version: packageJson.version,
  description: packageJson.description,
  author: { name: 'wagents maintainers' },
  homepage: packageJson.homepage,
  repository,
  license: 'MIT',
  keywords: [...new Set([...packageJson.keywords, ...commandSlugs])],
  commands: commandSlugs.length
    ? commandSlugs.map(slug => ({ name: `/wagents:${slug}`, file: `commands/${slug}.md` }))
    : undefined
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
writeFileSync(join(output, 'README.md'), `# wagents plugin\n\nThis directory is generated from the repository source by \`npm run build:plugin\`.\n\nSkills, agent roles, slash-command documentation, and lifecycle hooks are portable.\nSlash commands are documented under \`commands/\`; lifecycle hooks are under \`hooks/\`.\n\nMCP connections are intentionally not bundled: they can require OAuth, local vault access, paid licenses, or privileged credentials. Use the repository [MCP setup guide](../../mcp/README.md).\n`);
console.log(`[wagents] built portable plugin at ${output}`);
