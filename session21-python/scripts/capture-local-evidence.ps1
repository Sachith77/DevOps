. "$PSScriptRoot/common.ps1"
$project = Split-Path $PSScriptRoot -Parent
$destination = Join-Path (Split-Path $project -Parent) 'demo/evidence'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
function Save-Evidence {
    param([string]$Name, [scriptblock]$Action)
    $output = & $Action 2>&1 | Out-String -Width 220
    $code = $LASTEXITCODE
    $output = [regex]::Replace($output, '\b\d{12}\b', 'AWS_ACCOUNT_ID')
    $output = (($output -split '\r?\n' | ForEach-Object { $_.TrimEnd() }) -join "`n").TrimEnd() + "`n"
    [IO.File]::WriteAllText((Join-Path $destination $Name), $output, (New-Object Text.UTF8Encoding($false)))
    if ($code -ne 0) { throw "Evidence command failed: $Name" }
    Write-Host "Saved $Name"
}
Push-Location $project
try {
    Save-Evidence 'local-compose.txt' { docker compose ps }
    Save-Evidence 'local-pytest.txt' { docker run --rm --mount "type=bind,source=$project/backend,target=/app" -w /app session21-python-backend:latest pytest -v }
    Save-Evidence 'local-users.txt' { docker compose exec -T backend id; docker compose exec -T frontend id }
    Save-Evidence 'local-database.txt' { docker compose exec -T postgres psql -U taskboard -d taskboard -c 'SELECT id,title,requester,category,status FROM tasks;' }
    Save-Evidence 'git-history.txt' { git log --oneline -12 }
    Save-Evidence 'helm-lint.txt' { helm lint helm/taskboard --strict }
    Save-Evidence 'terraform-validate.txt' { terraform '-chdir=terraform' validate -no-color }
} finally { Pop-Location }
