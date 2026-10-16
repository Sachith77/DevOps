param([string]$Context='herodesk-eks')
. "$PSScriptRoot/common.ps1"
$project=Split-Path $PSScriptRoot -Parent
$destination=Join-Path (Split-Path $project -Parent) 'demo/evidence'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
function Save-CloudEvidence {
    param([string]$Name,[scriptblock]$Action)
    $output=& $Action 2>&1 | Out-String -Width 240
    $code=$LASTEXITCODE
    $output=[regex]::Replace($output,'\b\d{12}\b','AWS_ACCOUNT_ID')
    $output=(($output -split '\r?\n' | ForEach-Object {$_.TrimEnd()}) -join "`n").TrimEnd()+"`n"
    [IO.File]::WriteAllText((Join-Path $destination $Name),$output,(New-Object Text.UTF8Encoding($false)))
    if ($code -ne 0) {throw "Evidence capture failed: $Name"}
    Write-Host "Saved $Name"
}
Save-CloudEvidence 'cloud-nodes.txt' {kubectl --context $Context get nodes -o wide}
Save-CloudEvidence 'cloud-workloads.txt' {kubectl --context $Context -n taskboard get pods,svc,ingress,hpa,pvc -o wide}
Save-CloudEvidence 'cloud-argocd.txt' {kubectl --context $Context -n argocd get application herodesk -o wide}
Save-CloudEvidence 'cloud-helm.txt' {helm list --kube-context $Context -A}
Save-CloudEvidence 'cloud-service-monitor.txt' {kubectl --context $Context -n taskboard get servicemonitor}
Save-CloudEvidence 'cloud-cpu.txt' {kubectl --context $Context -n taskboard top pods}
Save-CloudEvidence 'cloud-deployment-images.txt' {kubectl --context $Context -n taskboard get deployments -o 'custom-columns=NAME:.metadata.name,DESIRED:.spec.replicas,READY:.status.readyReplicas,IMAGES:.spec.template.spec.containers[*].image'}
