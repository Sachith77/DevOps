param([string]$Context = 'herodesk-eks', [string]$Application = 'herodesk', [int]$TimeoutSeconds = 1200)
. "$PSScriptRoot/common.ps1"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
    $raw = & kubectl --context $Context -n argocd get application $Application -o json
    if ($LASTEXITCODE -ne 0) { throw 'Cannot read the Argo CD Application.' }
    $applicationState = $raw | ConvertFrom-Json
    $sync = $applicationState.status.sync.status
    $health = $applicationState.status.health.status
    Write-Host "Argo CD: sync=$sync health=$health"
    if ($sync -eq 'Synced' -and $health -eq 'Healthy') {
        Invoke-Checked kubectl --context $Context -n taskboard rollout status deployment/taskboard-backend --timeout=5m
        Invoke-Checked kubectl --context $Context -n taskboard rollout status deployment/taskboard-frontend --timeout=5m
        return
    }
    if ((Get-Date) -gt $deadline) { throw 'Timed out waiting for Argo CD. Inspect Application conditions and Pod events.' }
    Start-Sleep -Seconds 10
} while ($true)
