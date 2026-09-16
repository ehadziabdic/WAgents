#!/usr/bin/env node
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
let failed = false;

function check(label, condition) {
  if (condition) console.log(`[ok] ${label}`);
  else {
    console.error(`[missing] ${label}`);
    failed = true;
  }
}

function json(relativePath) {
  try {
    JSON.parse(readFileSync(join(root, relativePath), 'utf8'));
    console.log(`[ok] json:${relativePath}`);
  } catch (error) {
    console.error(`[invalid] json:${relativePath}: ${error.message}`);
    failed = true;
  }
}

const required = [
  'README.md', 'LICENSE', 'manifest.json', 'mcp/README.md',
  'config/agents.json', 'config/skills.json', 'config/permissions.json', 'config/providers.json',
  'config/external-dependencies.json', 'agents/wagent.agent.md',
  'agents/wagent-hacker.agent.md', 'agents/frontend-designer.agent.md',
  'agents/backend-engineer.agent.md', 'agents/security-engineer.agent.md',
  'agents/code-reviewer.agent.md', 'agents/debugger.agent.md',
  'agents/qa-engineer.agent.md', 'agents/research-specialist.agent.md',
  'agents/documentation-specialist.agent.md', 'agents/ml-engineer.agent.md',
  'agents/devops-engineer.agent.md',
  'skills/base-design-references/SKILL.md',
  'skills/base-hacker-claude-red/SKILL.md',
  'skills/mcp-second-brain/SKILL.md', 'skills/mcp-shared-codebase-memory/SKILL.md'
];
for (const item of required) check(item, existsSync(join(root, item)));

for (const item of ['package.json', 'manifest.json', 'mcp/servers.json', 'config/skills.json', 'config/plugins.json', 'config/agents.json', 'config/permissions.json', 'config/providers.json', 'config/external-dependencies.json']) json(item);

const skillDirectory = join(root, '.github', 'skills');
if (existsSync(skillDirectory)) {
  for (const name of readdirSync(skillDirectory)) {
    const directory = join(skillDirectory, name);
    if (statSync(directory).isDirectory() && !name.startsWith('_')) check(`skill:${name}`, existsSync(join(directory, 'SKILL.md')));
  }
}

const raw = [
  'README.md', 'mcp/README.md', 'docs/skills.md', 'docs/security.md',
  'docs/architecture.md', 'docs/mcp.md', 'docs/troubleshooting.md', 'docs/ui-references.md',
  'config/providers.json', 'config/external-dependencies.json'
].map((file) => existsSync(join(root, file)) ? readFileSync(join(root, file), 'utf8') : '').join('\n');
check('no placeholder repository owner in publish docs', !raw.includes('<OWNER>'));
check('Claude-Red source is SnailSploit', !raw.includes('0xwilliamortiz/claude-red'));

const docChecks = [
  { file: 'docs/skills.md', must: ['config/skills.json', 'Updating a vendored set', 'Adding a new skill', 'PROVENANCE.md'] },
  { file: 'docs/architecture.md', must: ['wagent-hacker', 'never call each other', 'merged into wagent'] },
  { file: 'docs/mcp.md', must: ['servers.json', 'codebase-memory', 'mcp-second-brain'] },
  { file: 'docs/security.md', must: ['wagent-hacker', 'authorization', 'stripped'] },
  { file: 'docs/troubleshooting.md', must: ['verify-install', 'smoke-skills', 'validate-agent-guide'] },
  { file: 'mcp/README.md', must: ['servers.json', 'codebase-memory', 'mcp-second-brain'] },
];
for (const { file, must } of docChecks) {
  const path = join(root, file);
  const text = existsSync(path) ? readFileSync(path, 'utf8') : '';
  for (const token of must) {
    check(`${file} mentions ${token}`, text.includes(token));
  }
}

if (failed) process.exitCode = 1;
