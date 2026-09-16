// WAGENTS deep audit: cross-checks every config surface for completeness & compatibility.
const fs = require('fs'), path = require('path');
const R = (...p) => path.join(__dirname, '..', ...p);
const J = f => JSON.parse(fs.readFileSync(R(f), 'utf8'));
const exists = p => fs.existsSync(R(p));
let problems = 0;
const bad = msg => { problems++; console.log('PROBLEM: ' + msg); };
const ok = msg => console.log('ok: ' + msg);

const agents = J('config/agents.json');
const skills = J('config/skills.json');
const perms = J('config/permissions.json');
const servers = J('mcp/servers.json');
const plugin = J('plugin.json');
const manifest = J('manifest.json');
const pkg = J('package.json');
const providers = J('config/providers.json');
const ext = J('config/external-dependencies.json');
const agentIds = agents.agents.map(a => a.id);

// 1. skills dirs <-> skills.json (both directions)
const skillDirs = fs.readdirSync(R('skills')).filter(n => !n.startsWith('_') && fs.statSync(R('skills', n)).isDirectory());
const supportRecords = skills.skills.filter(s => String(s.status || '').includes('support-dir'));
const skillEntries = skills.skills.filter(s => !String(s.status || '').includes('support-dir'));
const reg = new Map(skillEntries.map(s => [s.name, s]));
const dirSet = new Set(skillDirs);
for (const d of skillDirs) if (!reg.has(d)) bad(`skill dir '${d}' not registered in config/skills.json`);
for (const [name, s] of reg) {
  if (!dirSet.has(name)) bad(`registered skill '${name}' has no skills/${name}/ dir`);
  else if (!exists(s.path || `skills/${name}/SKILL.md`)) bad(`registered skill '${name}' path missing: ${s.path}`);
}
ok(`skills: ${skillDirs.length} dirs, ${skillEntries.length} registered skills (+${supportRecords.length} support-dir records)`);
if (skillDirs.length !== skillEntries.length) bad(`skill dir count ${skillDirs.length} != registry skill count ${skillEntries.length}`);

// 2. target_agents validity
const agentSet = new Set(agentIds);
for (const s of skills.skills) {
  if (!Array.isArray(s.target_agents) || !s.target_agents.length) bad(`skill '${s.name}' has no target_agents`);
  else for (const a of s.target_agents) if (!agentSet.has(a) && a !== 'all') bad(`skill '${s.name}' targets unknown agent '${a}'`);
}

// 3. permissions.json agents <-> agents.json
for (const id of agentIds) if (!perms.agents[id]) bad(`no permissions entry for agent '${id}'`);
for (const id of Object.keys(perms.agents)) if (!agentSet.has(id)) bad(`permissions has unknown agent '${id}'`);

// 4. permissions mcp entries resolve to servers.json ids
const serverIds = new Set(servers.servers.map(s => s.id));
const resolveMcp = m => serverIds.has(m) ? m
  : (m.endsWith('-read') && serverIds.has(m.slice(0, -5)) ? m.slice(0, -5) : null)
  ?? (m.endsWith('-conditional') && serverIds.has(m.replace(/-conditional$/, '')) ? m.replace(/-conditional$/, '') : null);
for (const [id, p] of Object.entries(perms.agents)) {
  for (const m of p.mcp || []) if (!resolveMcp(m)) bad(`agent '${id}' mcp '${m}' does not resolve to any servers.json id`);
  if (p.exclusive_skills) for (const s of p.exclusive_skills) if (!reg.has(s)) bad(`agent '${id}' exclusive_skills unknown skill '${s}'`);
}

// 5. mcp scope values
const knownGroups = new Set(['all-agents', 'read-only-specialists', 'all-specialists-query']);
for (const s of servers.servers) {
  for (const sc of s.scope || []) {
    if (agentSet.has(sc) || knownGroups.has(sc)) continue;
    if (/^[a-z-]+-(read|query|index-and-query)(-default)?$/.test(sc)) continue; // documented compound scopes
    bad(`server '${s.id}' scope '${sc}' matches no agent/group pattern`);
  }
}

// 6. npm pins consistency (install-mcp.mjs vs servers.json)
const pinsSrc = fs.readFileSync(R('scripts/install-mcp.mjs'), 'utf8');
for (const s of servers.servers.filter(x => x.install === 'npm-pinned')) {
  const pin = s.pinned_version || s.pinned_release;
  if (!pin) bad(`npm-pinned server '${s.id}' has no pinned_version in servers.json`);
  if (pin && !pinsSrc.includes(pin.replace(/^v/, ''))) bad(`pin '${pin}' for '${s.id}' not found in scripts/install-mcp.mjs`);
}

// 7. commands/ <-> plugin.json
const cmdFiles = fs.readdirSync(R('commands')).filter(f => f.endsWith('.md'));
for (const c of plugin.commands || []) {
  if (!exists(c.file)) bad(`plugin.json command file missing: ${c.file}`);
  else if (!cmdFiles.includes(path.basename(c.file))) bad(`plugin.json command '${c.file}' not in commands/`);
}
for (const f of cmdFiles) if (!(plugin.commands || []).some(c => c.file.endsWith(f))) bad(`commands/${f} not declared in plugin.json`);
for (const c of cmdFiles) {
  const slug = c.replace(/\.md$/, '');
  if (!plugin.keywords.includes(slug)) bad(`plugin.json keywords missing command slug '${slug}'`);
}

// 8. hooks.json referenced scripts exist
const hooks = J('hooks/hooks.json');
let hookCount = 0;
for (const [event, entries] of Object.entries(hooks.hooks)) {
  for (const entry of entries) {
    for (const h of entry.hooks ?? [entry]) {
      hookCount++;
      const m = (h.command || '').match(/hooks[\\/]([A-Za-z0-9_\/.-]+?\.(mjs|sh|cmd|ps1))/);
      if (m) {
        const rel = m[1].replace(/\\/g, '/');
        if (!exists(`hooks/${rel}`)) bad(`hook '${event}' references missing hooks/${rel}`);
      }
    }
  }
}
ok(`hooks: ${Object.keys(hooks.hooks).length} events, ${hookCount} hook commands`);

// 9. manifest.json: entrypoints, structure, docs, agents
for (const [k, v] of Object.entries(manifest.entrypoints)) if (!exists(v.replace('./', ''))) bad(`manifest entrypoint ${k} missing: ${v}`);
for (const [k, v] of Object.entries(manifest.structure)) if (!exists(v.replace(/\/$/, ''))) bad(`manifest structure ${k} missing: ${v}`);
for (const d of manifest.docs) if (!exists(d)) bad(`manifest docs missing: ${d}`);
for (const a of manifest.agents) if (!agentSet.has(a)) bad(`manifest agents unknown: '${a}'`);

// 10. package.json files[] on disk
for (const f of pkg.files) if (!exists(f.replace(/\/$/, ''))) bad(`package.json files[] missing: ${f}`);

// 11. agents: file exists, frontmatter, delegation graph
for (const a of agents.agents) {
  if (!exists(a.file)) { bad(`agent '${a.id}' file missing: ${a.file}`); continue; }
  const t = fs.readFileSync(R(a.file), 'utf8');
  if (!/^---\r?\n/.test(t)) bad(`agent '${a.id}' has no frontmatter`);
  if (a.delegates_to) for (const d of a.delegates_to) if (!agentSet.has(d)) bad(`agent '${a.id}' delegates_to unknown '${d}'`);
}

// 12. providers <-> CLI branches
const cli = fs.readFileSync(R('bin/wagents.mjs'), 'utf8');
for (const id of Object.keys(providers.providers)) {
  if (!cli.includes(`'${id}'`)) bad(`provider '${id}' missing in bin/wagents.mjs`);
}

// 13. external-dependencies vendored sanity
for (const v of ext.vendored) {
  if (!v.source || !v.license) bad(`vendored '${v.id}' missing source/license`);
  if (!/(pinned|commit|version|release|tag|sha|tree)/i.test(JSON.stringify(v))) bad(`vendored '${v.id}' has no pin`);
}
if (!exists('skills/_memory-pack-docs/PROVENANCE.md')) bad('agentmemory PROVENANCE.md missing');
if (!exists('hooks/agentmemory')) bad('hooks/agentmemory missing');

// 14. smoke-skills.sh references the current skill count
const smoke = fs.readFileSync(R('scripts/smoke-skills.sh'), 'utf8');
if (!smoke.includes(`${skillEntries.length}`)) bad(`smoke-skills.sh does not reference current count ${skillEntries.length}`);

// 15. marketplace manifests point at root
for (const f of ['.claude-plugin/marketplace.json', '.github/plugin/marketplace.json', '.agents/plugins/marketplace.json']) {
  const m = J(f);
  const p = m.plugins[0];
  const src = typeof p.source === 'string' ? p.source : p.source.path;
  if (src !== './') bad(`${f} source is '${src}', expected './'`);
}

// summary stats
console.log(`stats: agents=${agentIds.length} skills=${skillEntries.length} servers=${servers.servers.length} providers=${Object.keys(providers.providers).length} vendored=${ext.vendored.length}`);
console.log(problems ? `\nAUDIT: ${problems} PROBLEM(S)` : '\nAUDIT: ALL CLEAN');