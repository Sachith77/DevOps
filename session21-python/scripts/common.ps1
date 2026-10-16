$ErrorActionPreference = 'Stop'
# Refresh PATH so installs made in an Administrator shell are visible here.
$labHelmDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/helm/windows-amd64'
$pathEntries = @($env:PATH, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User'))
if (Test-Path (Join-Path $labHelmDirectory 'helm.exe')) { $pathEntries = @($labHelmDirectory) + $pathEntries }
$env:PATH = ((($pathEntries -join ';') -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';')
function Invoke-Checked {
    # Keep this a simple function: advanced PowerShell parameters consume native
    # flags such as kubectl -o as ambiguous -OutVariable/-OutBuffer parameters.
    param([string]$Tool)
    $Arguments = foreach ($argument in $args) {
        # Match native-command comma syntax (for example get pods,svc).
        if ($argument -is [Array]) { $argument -join ',' } else { $argument }
    }
    $null = Get-Command $Tool -ErrorAction Stop
    $previousPreference = $ErrorActionPreference
    try {
        # Windows PowerShell 5 treats native stderr as ErrorRecords. Let the
        # program finish, then use its exit code instead of aborting on warnings.
        $ErrorActionPreference = 'Continue'
        & $Tool @Arguments
        $toolExitCode = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previousPreference }
    if ($toolExitCode -ne 0) { throw "$Tool failed with exit code $toolExitCode" }
}
