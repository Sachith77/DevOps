# Password stays out of command arguments, stdout, Git, and temporary files.
param([Parameter(Mandatory=$true)][string]$Context, [string]$Namespace = 'taskboard', [string]$Release = 'taskboard')
. "$PSScriptRoot/common.ps1"
$existing = & kubectl --context $Context -n $Namespace get secret herodesk-postgres --ignore-not-found -o name
if ($LASTEXITCODE -ne 0) { throw 'Cannot read Kubernetes secrets in the selected namespace.' }
if ($existing) { Write-Host 'Database Secret already exists; preserving it.'; return }
$password = [Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N')
$databaseUrl = "postgresql+psycopg://taskboard:${password}@${Release}-postgres:5432/taskboard"
$secret = @{
    apiVersion = 'v1'; kind = 'Secret'; type = 'Opaque'
    metadata = @{name = 'herodesk-postgres'; namespace = $Namespace}
    data = @{
        username = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('taskboard'))
        password = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($password))
        'database-url' = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($databaseUrl))
    }
} | ConvertTo-Json -Depth 6 -Compress
$secret | & kubectl --context $Context create -f -
if ($LASTEXITCODE -ne 0) { throw 'Could not create database Secret.' }
Remove-Variable password, databaseUrl, secret
Write-Host 'Created herodesk-postgres. Retain this Secret while its database volume exists.'
