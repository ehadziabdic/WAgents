#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Write-Host "[wagents] doctor (windows)..."
$fail = 0
function Check($name, $path) {
  if (Test-Path $path) { Write-Host "[ok] $name" } else { Write-Host "[missing] $name"; $script:fail = 1 }
}
try {
  $agents = Get-Content -Raw -Encoding UTF8 "$Root/config/agents.json" | ConvertFrom-Json
  foreach ($agent in $agents.agents) {
    Check "agent:$($agent.id)" "$Root/$($agent.github_file)"
  }
  $skills = Get-Content -Raw -Encoding UTF8 "$Root/config/skills.json" | ConvertFrom-Json
  foreach ($skill in $skills.skills) {
    Check "skill:$($skill.name)" "$Root/$($skill.path)"
  }
} catch {
  Write-Host "[invalid] agent/skill registry: $_"; $fail = 1
}
foreach ($f in @("typescript.instructions.md","python.instructions.md","react.instructions.md","security.instructions.md","testing.instructions.md","documentation.instructions.md")) {
  Check "instruction:$f" "$Root/instructions/$f"
}
foreach ($f in @("mcp/servers.json","mcp/README.md","config/skills.json","config/plugins.json","config/agents.json","config/permissions.json","manifest.json",".env.example","install.sh","install.ps1","bin/wagents","bin/wagents.ps1",".github/hooks/README.md")) {
  Check $f "$Root/$f"
}
foreach ($d in @("architecture.md","skills.md","mcp.md","security.md","troubleshooting.md","ui-references.md")) {
  Check "docs:$d" "$Root/docs/$d"
}
if (-not (Test-Path "$Root/templates/project")) {
  Write-Host "[warn] project templates absent; legacy init commands are unavailable"
}
foreach ($f in @("manifest.json","mcp/servers.json","config/skills.json","config/plugins.json","config/agents.json","config/permissions.json","config/providers.json","config/external-dependencies.json")) {
  try {
    Get-Content -Raw -Encoding UTF8 "$Root/$f" | ConvertFrom-Json | Out-Null
    Write-Host "[ok] json:$f"
  } catch {
    Write-Host "[invalid] json:$f : $_"; $fail = 1
  }
}
if (Get-Command git -ErrorAction SilentlyContinue) { Write-Host "[ok] git" } else { Write-Host "[missing] git"; $fail = 1 }
if (Get-Command gh -ErrorAction SilentlyContinue) { Write-Host "[ok] gh" } else { Write-Host "[warn] gh missing (optional)" }
if (Get-Command node -ErrorAction SilentlyContinue) { Write-Host "[ok] node" } else { Write-Host "[warn] node missing (needed for some MCPs)" }
if (Get-Command python -ErrorAction SilentlyContinue) { Write-Host "[ok] python" } else { Write-Host "[warn] python missing" }
if (Test-Path "$Root/skills/base-hacker-claude-red/vendor/Claude-Red/Skills") { Write-Host "[ok] hacker vendor" } else { Write-Host "[info] hacker vendor not installed (use -IncludeHacker)" }
if ($fail -ne 0) { throw "doctor failed" }
Write-Host "[wagents] doctor complete."

