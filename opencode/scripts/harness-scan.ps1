#!/usr/bin/env pwsh
# harness-scan.ps1 - scan THIS opencode setup (not other folders) with
# Harness Score, for the self-improving loop.
#
# The scanner rejects outside-root symlinks, so this builds a TEMP mirror
# as filtered COPIES (dependency dirs excluded - they are not harness
# content) and deletes it afterwards. Nothing fake is ever committed:
#   mirror/AGENTS.md            = copy of live global AGENTS.md
#   mirror/.opencode/agents/    = copy of live agents/ (native row)
#   mirror/.agents/skills/<id>  = copy per live skill dir
#   mirror/.agents/workflows/   = copy of live commands/
#   mirror/.agents/rules/       = copy of live instructions/
# MCP config has no recognized row: instead this script greps
# opencode.jsonc for literal-secret patterns and reports counts only
# (values are NEVER printed).
#
# Outputs (global wagents dir):
#   .wagents/harness-score.txt  (human report + secret-check line)
#   .wagents/harness-score.json (raw report, for --diff ratchet)
#
# Usage: harness-scan.ps1
$ErrorActionPreference = "Stop"
$Config = Join-Path $env:USERPROFILE ".config\opencode"
$OutDir = Join-Path $Config ".wagents"
$mirror = Join-Path ([System.IO.Path]::GetTempPath()) "hs-core-mirror"

try {
  if (Test-Path $mirror) { Remove-Item -Recurse -Force $mirror }
  New-Item -ItemType Directory -Force -Path $mirror | Out-Null
  $XD = @("node_modules", "__pycache__", ".venv", ".git")
  Copy-Item (Join-Path $Config "AGENTS.md") (Join-Path $mirror "AGENTS.md")
  # Root dotfiles/configs the scanner checks (real files, mirrored like all).
  foreach ($f in @("README.md", ".gitignore", "biome.json", "pyproject.toml", "package.json", "package-lock.json")) {
    $src = Join-Path $Config $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $mirror $f) }
  }
  robocopy (Join-Path $Config "agents") (Join-Path $mirror ".opencode\agents") /E /XD $XD /NFL /NDL /NJH /NJS | Out-Null
  $skRoot = New-Item -ItemType Directory -Force -Path (Join-Path $mirror ".agents\skills")
  $n = 0
  Get-ChildItem (Join-Path $Config "skills") -Directory | ForEach-Object {
    robocopy $_.FullName (Join-Path $skRoot $_.Name) /E /XD $XD /NFL /NDL /NJH /NJS | Out-Null; $n++
  }
  robocopy (Join-Path $Config "commands") (Join-Path $mirror ".agents\workflows") /E /XD $XD /NFL /NDL /NJH /NJS | Out-Null
  robocopy (Join-Path $Config "instructions") (Join-Path $mirror ".agents\rules") /E /XD $XD /NFL /NDL /NJH /NJS | Out-Null
  Write-Output "mirror: AGENTS.md + agents/ + $n skill copies + commands + instructions"

  $json = Join-Path $OutDir "harness-score.json"
  npx -y harness-score --json $mirror 2>$null | Out-File -FilePath $json -Encoding utf8
  if ($LASTEXITCODE -ne 0) { throw "harness-score failed (exit $LASTEXITCODE)" }
  npx -y harness-score --md - $mirror 2>$null | Out-File -FilePath (Join-Path $OutDir "harness-score.txt") -Encoding utf8
  # Out-File writes BOM; --diff chokes on it. Strip to plain UTF-8.
  $noBom = New-Object Text.UTF8Encoding $false
  foreach ($f in @($json, (Join-Path $OutDir "harness-score.txt"))) {
    [IO.File]::WriteAllText($f, [IO.File]::ReadAllText($f), $noBom)
  }

  # Own HYG-04 equivalent: literal secrets in opencode.jsonc (counts only).
  $cfg = Get-Content (Join-Path $Config "opencode.jsonc") -Raw
  $pats = @("Bearer [A-Za-z0-9_\-\.]+", "pat[A-Za-z0-9\.]+", "sk-[A-Za-z0-9]+",
            "ghp_[A-Za-z0-9]+", "sntryu_[A-Za-z0-9]+", "tvly-[A-Za-z0-9\-_]+",
            "vck_[A-Za-z0-9]+", "figu_[A-Za-z0-9\-_]+", "sbp_[A-Za-z0-9]+")
  $hits = 0
  foreach ($p in $pats) { $hits += ([regex]::Matches($cfg, $p)).Count }
  Add-Content (Join-Path $OutDir "harness-score.txt") ""
  Add-Content (Join-Path $OutDir "harness-score.txt") ("SECRET-CHECK opencode.jsonc literal-secret matches: " + $hits + " (values never printed; move to env vars to clear)")
  Write-Output "report: .wagents/harness-score.txt (+ .json) | secret-matches: $hits"
}
finally {
  if (Test-Path $mirror) { Remove-Item -Recurse -Force $mirror }
}
