# Destructive teardown of this Terraform lab. Run only after saving evidence.
param([string]$Context = 'herodesk-eks')
. "$PSScriptRoot/common.ps1"
$project = Split-Path $PSScriptRoot -Parent
Push-Location "$project/terraform"
try {
    $expectedCluster = Invoke-Checked terraform output -raw cluster_name
    if ($Context -ne $expectedCluster) { throw 'Context must match the Terraform-managed lab cluster.' }
    # Removing only this Application stops reconciliation. No resource finalizer is configured.
    Invoke-Checked kubectl --context $Context -n argocd delete application herodesk --ignore-not-found --cascade=orphan
    foreach ($namespace in @('taskboard','taskboard-helm-demo')) {
        $exists = & kubectl --context $Context get namespace $namespace --ignore-not-found -o name
        if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect lab namespace.' }
        if ($exists) {
            Invoke-Checked kubectl --context $Context -n $namespace delete ingress --all --ignore-not-found --wait=true --timeout=10m
            Invoke-Checked kubectl --context $Context delete namespace $namespace --wait=true --timeout=10m
        }
    }
    # Wait for CSI to finish deleting app EBS volumes before deleting its controller.
    $deadline = (Get-Date).AddMinutes(10)
    do {
        $volumes = Invoke-Checked kubectl --context $Context get pv -o json | ConvertFrom-Json
        $remaining = @($volumes.items | Where-Object { $_.spec.claimRef.namespace -in @('taskboard','taskboard-helm-demo') })
        if ($remaining.Count -eq 0) { break }
        if ((Get-Date) -gt $deadline) { throw 'App volumes remain. Inspect PV finalizers before destroying EKS.' }
        Start-Sleep -Seconds 10
    } while ($true)
    Invoke-Checked terraform destroy -auto-approve -input=false -no-color
} finally { Pop-Location }
