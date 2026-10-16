param([string]$Url = 'http://localhost:3000/api/tickets', [int]$Requests = 1000)
. "$PSScriptRoot/common.ps1"
for ($i = 0; $i -lt $Requests; $i++) {
    $null = Invoke-WebRequest -Uri $Url -UseBasicParsing
}
Write-Host "Completed $Requests requests. A simple read workload may not trigger CPU autoscaling."
