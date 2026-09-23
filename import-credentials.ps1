# Import credential rows (opencode accounts, MCP OAuth, router keys) into the
# local opencode.db. Run AFTER first opencode launch (it creates the db).
# Skips labels already present, so re-running is safe.
param([string]$Repo = (Split-Path -Parent $MyInvocation.MyCommand.Path))
$src = Join-Path $Repo "local-share\credentials.json"
$dst = Join-Path $env:USERPROFILE ".local\share\opencode\opencode.db"
if (-not (Test-Path $src)) { Write-Host "CRED-NO-SOURCE"; exit 1 }
if (-not (Test-Path $dst)) { Write-Host "CRED-NO-DB (launch opencode once first)"; exit 1 }
python -c "
import sqlite3, json
rows = json.load(open(r'$src'.replace(chr(92), chr(92))))
con = sqlite3.connect(r'$dst'.replace(chr(92), chr(92)))
have = set(r[0] for r in con.execute('select label from credential'))
cols = ['id','integration_id','label','value','connector_id','method_id','active','time_created','time_updated']
added = 0
for r in rows:
    if r['label'] in have:
        continue
    con.execute('insert into credential values (?,?,?,?,?,?,?,?,?)', [r[c] for c in cols])
    added += 1
con.commit()
print('CRED-IMPORTED:' + str(added))
"
