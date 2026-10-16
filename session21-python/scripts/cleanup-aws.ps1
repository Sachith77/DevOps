# Destructive teardown of this Terraform lab. Run only after saving evidence.
param([string]$Context = 'herodesk-eks')
. "$PSScriptRoot/common.ps1"
$project = Split-Path $PSScriptRoot -Parent
Push-Location "$project/terraform"
try {
    $expectedCluster = Invoke-Checked terraform output -raw cluster_name
    if ($Context -ne $expectedCluster) { throw 'Context must match the Terraform-managed lab cluster.' }
    # Removing only this Application stops reconciliation. No resource finalizer is configured.
    $applicationCrd = Invoke-Checked kubectl --context $Context get crd applications.argoproj.io --ignore-not-found -o name --request-timeout=30s
    if ($applicationCrd) {
        Invoke-Checked kubectl --context $Context -n argocd delete application herodesk --ignore-not-found --cascade=orphan --request-timeout=30s
    }
    foreach ($namespace in @('taskboard','taskboard-helm-demo')) {
        $exists = Invoke-Checked kubectl --context $Context get namespace $namespace --ignore-not-found -o name --request-timeout=30s
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
    # Remove the temporary cluster installer even after an interrupted bootstrap.
    Invoke-Checked kubectl --context $Context delete clusterrolebinding herodesk-chart-installer --ignore-not-found --request-timeout=30s
    foreach ($namespace in @('herodesk-ops','herodesk-lab','argocd','monitoring')) {
        Invoke-Checked kubectl --context $Context delete namespace $namespace --ignore-not-found --wait=true --timeout=5m
    }
    Invoke-Checked terraform destroy -auto-approve -input=false -no-color
} finally { Pop-Location }
