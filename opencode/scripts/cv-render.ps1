#!/usr/bin/env pwsh
# cv-render.ps1 - PerfectCV full render pipeline for the cv-maintainer agent.
# Runs cli.py (generate 4 targets + validate + render + page budgets),
# fast pytest suite, then copies the 4 PDFs to Desktop with the canonical
# mapping names. US Resume one-page overflow: tighten flags first,
# -UseTempMaster swap only as fallback (backup + guaranteed restore).
#
# Usage:
#   cv-render.ps1
#   cv-render.ps1 -MaxHighlights 1 -DropSection Interests
#   cv-render.ps1 -UseTempMaster C:\path\master-re-us.yaml
param(
  [string]$Keep = "",
  [string]$KeepUS = "",
  [int]$MaxHighlights = 1,
  [int]$FullHighlights = 3,
  [string]$Palette = "",
  [string[]]$DropSection = @(),
  [string]$UseTempMaster = "",
  [switch]$SkipTests,
  [switch]$NoDesktopCopy
)
$ErrorActionPreference = "Stop"
# RenderCV prints ✓/─ box-drawing to stdout; on Windows pipes that dies
# under cp1252 (UnicodeEncodeError) AFTER the PDF is written. UTF-8 mode
# fixes the whole tree (wrapper -> cli.py -> rendercv children).
$env:PYTHONUTF8 = "1"
$repo = "C:\Users\eminha\Documents\Projects\PerfectCV"
$py = Join-Path $repo ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) { throw "venv python missing: $py" }
$master = Join-Path $repo "backend\import\master.yaml"
$bak = "$master.bak-cvrender"
$swapped = $false

try {
  if ($UseTempMaster) {
    if (-not (Test-Path $UseTempMaster)) { throw "temp master not found: $UseTempMaster" }
    Copy-Item $master $bak -Force
    Copy-Item $UseTempMaster $master -Force
    $swapped = $true
    Write-Output "temp master swapped in (backup: master.bak-cvrender)"
  }
  $cli = Join-Path $repo "backend\scripts\cli.py"
  # Default keeps follow the sample-data pattern (3 EU / 2 US) using the
  # real master.yaml project order (curated, most relevant first).
  if (-not $Keep) {
    $names = & $py -c "import yaml; m = yaml.safe_load(open(r'$($master -replace "'", "''")', encoding='utf-8')); print(';'.join(p.get('name','') for p in m['cv']['sections'].get('Projects', [])))" 
    $all = $names.Split(';') | Where-Object { $_ } | ForEach-Object { ($_ -split ' - ')[0].Trim() }
    if ($all.Count -eq 0) { throw "no projects in master.yaml" }
    $Keep = ($all | Select-Object -First 3) -join ","
  }
  if (-not $KeepUS) {
    $KeepUS = ($Keep.Split(',') | Select-Object -First 2) -join ","
  }
  $cliArgs = @($cli, "--max-highlights", $MaxHighlights,
    "--full-highlights", $FullHighlights)
  if ($Keep) { $cliArgs += @("--keep", $Keep) }
  if ($KeepUS) { $cliArgs += @("--keep-us", $KeepUS) }
  if ($Palette) { $cliArgs += @("--palette", $Palette) }
  foreach ($d in $DropSection) { $cliArgs += @("--drop-section", $d) }
  Write-Output "=== cli.py ==="
  & $py @cliArgs
  if ($LASTEXITCODE -ne 0) { throw "cli.py failed (exit $LASTEXITCODE)" }

  if (-not $SkipTests) {
    Write-Output "=== pytest test_fast ==="
    # test_fast uses repo-relative paths: run from the repo root.
    Push-Location $repo
    try {
      & $py -m pytest (Join-Path $repo "tests\test_fast.py") -q --rootdir $repo
      if ($LASTEXITCODE -ne 0) { throw "pytest test_fast failed (exit $LASTEXITCODE)" }
    } finally { Pop-Location }
  }

  if (-not $NoDesktopCopy) {
    $map = @{
      "MasterCV-EU.pdf"  = "Full-EU.pdf"
      "MasterCV-US.pdf"  = "Full-US.pdf"
      "ResumeCV-EU.pdf"  = "ResumeEU.pdf"
      "ResumeCV-US.pdf"  = "ResumeUS.pdf"
    }
    $desk = [Environment]::GetFolderPath("Desktop")
    Write-Output "=== desktop copies ==="
    foreach ($kv in $map.GetEnumerator()) {
      $src = Join-Path $repo "output\PDF\$($kv.Key)"
      if (-not (Test-Path $src)) { throw "missing render output: $src" }
      Copy-Item $src (Join-Path $desk $kv.Value) -Force
      Write-Output "$($kv.Key) -> $($kv.Value)"
    }
  }
  Write-Output "CV-RENDER-OK"
}
finally {
  if ($swapped) {
    Copy-Item $bak $master -Force
    Remove-Item $bak -Force -ErrorAction SilentlyContinue
    Write-Output "master.yaml restored from backup"
  }
}
