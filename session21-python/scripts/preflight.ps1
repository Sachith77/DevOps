# Run from any directory. LocalOnly does not require AWS or Kubernetes.
param([switch]$LocalOnly)
. "$PSScriptRoot/common.ps1"
$requiredTools = if ($LocalOnly) { @('git','docker') } else { @('git','docker','aws','terraform','helm','kubectl') }
foreach ($tool in $requiredTools) {
    $command = Get-Command $tool -ErrorAction SilentlyContinue
    if (-not $command) { throw "$tool is missing from PATH." }
    Write-Host "$tool found: $($command.Source)"
}
Invoke-Checked docker info --format '{{.ServerVersion}}'
if ($LocalOnly) { Write-Host 'Local preflight complete.'; return }
$identity = Invoke-Checked aws sts get-caller-identity --output json --no-cli-pager | ConvertFrom-Json
Write-Host 'AWS authentication succeeded. Access keys have not been printed.'
$region = & aws configure get region
Write-Host "AWS CLI region: $region. Terraform default: ap-southeast-2."
Write-Host "Current Kubernetes context: $(& kubectl config current-context)"
Write-Host 'Preflight complete. No cloud resources were created.'
