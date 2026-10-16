$ErrorActionPreference = 'Stop'
# Refresh PATH so installs made in an Administrator shell are visible here.
$env:PATH = @($env:PATH, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';'
function Invoke-Checked {
    param([Parameter(Mandatory=$true)][string]$Tool, [Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments)
    & $Tool @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Tool failed with exit code $LASTEXITCODE" }
}
