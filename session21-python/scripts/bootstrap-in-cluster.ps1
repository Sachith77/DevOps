# Run the large chart operations beside the Kubernetes API, avoiding flaky local
# connections. The temporary installer and its administrator binding are removed.
param([string]$Context='herodesk-eks', [string]$MonitoringChartVersion='92.9.0', [string]$ArgoChartVersion='10.10.5')
. "$PSScriptRoot/common.ps1"
$project=Split-Path $PSScriptRoot -Parent
Push-Location "$project/terraform"
try {
    $cluster=Invoke-Checked terraform output -raw cluster_name
    $region=Invoke-Checked terraform output -raw aws_region
    $vpc=Invoke-Checked terraform output -raw vpc_id
} finally {Pop-Location}
if ($cluster -ne $Context) {throw 'Use the Terraform-managed lab context.'}
function Apply-Object($Object) {
    $manifestPath = Join-Path ([IO.Path]::GetTempPath()) ('herodesk-bootstrap-' + [guid]::NewGuid().ToString('N') + '.json')
    [IO.File]::WriteAllText($manifestPath, ($Object | ConvertTo-Json -Depth 20 -Compress), (New-Object Text.UTF8Encoding($false)))
    $previousPreference=$ErrorActionPreference
    try {
        $ErrorActionPreference='Continue'
        for ($attempt=1; $attempt -le 3; $attempt++) {
            & kubectl --context $Context apply --validate=false --request-timeout=30s -f $manifestPath
            $applyCode=$LASTEXITCODE
            if ($applyCode -eq 0) {break}
        }
    } finally {
        $ErrorActionPreference=$previousPreference
        Remove-Item -LiteralPath $manifestPath -Force
    }
    if ($applyCode -ne 0) {throw 'Could not apply temporary installer resource.'}
}
$namespace='herodesk-ops'
$jobName='herodesk-chart-bootstrap'
$installScript=@'
#!/bin/sh
set -eu
helm repo add eks https://aws.github.io/eks-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
# Recover only an interrupted initial monitoring installation.
if helm status kube-prometheus-stack -n monitoring -o json 2>/dev/null | grep -Eq '"status"[[:space:]]*:[[:space:]]*"(pending-install|uninstalling)"'; then
  helm uninstall kube-prometheus-stack -n monitoring --no-hooks --wait --timeout 5m
fi
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --version 1.14.0 -n kube-system --set image.tag=v2.14.1 --set "clusterName=$CLUSTER" --set "region=$REGION" --set "vpcId=$VPC" --set serviceAccount.create=true --set serviceAccount.name=aws-load-balancer-controller --wait --timeout 10m
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --version "$MONITORING_VERSION" -n monitoring --create-namespace -f /config/prometheus-values.yaml --wait --timeout 15m
helm upgrade --install argocd argo/argo-cd --version "$ARGO_VERSION" -n argocd --create-namespace --wait --timeout 15m
'@
$installScript = $installScript.Replace("`r`n", "`n")
try {
    Apply-Object @{apiVersion='v1';kind='Namespace';metadata=@{name=$namespace}}
    Apply-Object @{apiVersion='v1';kind='ServiceAccount';metadata=@{name='chart-installer';namespace=$namespace}}
    Apply-Object @{apiVersion='rbac.authorization.k8s.io/v1';kind='ClusterRoleBinding';metadata=@{name='herodesk-chart-installer'};roleRef=@{apiGroup='rbac.authorization.k8s.io';kind='ClusterRole';name='cluster-admin'};subjects=@(@{kind='ServiceAccount';name='chart-installer';namespace=$namespace})}
    Apply-Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='chart-bootstrap';namespace=$namespace};data=@{'install.sh'=$installScript;'prometheus-values.yaml'=[IO.File]::ReadAllText("$project/monitoring/prometheus-values.yaml")}}
    Apply-Object @{apiVersion='batch/v1';kind='Job';metadata=@{name=$jobName;namespace=$namespace};spec=@{backoffLimit=0;activeDeadlineSeconds=1800;ttlSecondsAfterFinished=600;template=@{spec=@{serviceAccountName='chart-installer';restartPolicy='Never';containers=@(@{name='helm';image='alpine/helm:3.17.3';command=@('/bin/sh','/config/install.sh');env=@(@{name='CLUSTER';value=$cluster},@{name='REGION';value=$region},@{name='VPC';value=$vpc},@{name='MONITORING_VERSION';value=$MonitoringChartVersion},@{name='ARGO_VERSION';value=$ArgoChartVersion});resources=@{requests=@{cpu='100m';memory='256Mi'};limits=@{cpu='1000m';memory='1Gi'}};volumeMounts=@(@{name='config';mountPath='/config';readOnly=$true})});volumes=@(@{name='config';configMap=@{name='chart-bootstrap'}})}}}}
    $deadline=(Get-Date).AddMinutes(31)
    $pollFailures=0
    do {
        Start-Sleep -Seconds 10
        try {
            $job=Invoke-Checked kubectl --context $Context -n $namespace get job $jobName --request-timeout=30s -o json | ConvertFrom-Json
            $pollFailures=0
        } catch {
            $pollFailures++
            Write-Warning "Cannot read installer status (attempt $pollFailures): $_"
            if ($pollFailures -ge 5) {throw}
            continue
        }
        Write-Host "Chart bootstrap: active=$($job.status.active) succeeded=$($job.status.succeeded) failed=$($job.status.failed)"
        if ($job.status.succeeded -eq 1) {break}
        if ($job.status.failed -ge 1) {throw 'In-cluster chart installation failed. See the saved bootstrap log.'}
        if ((Get-Date) -gt $deadline) {throw 'In-cluster chart installation timed out.'}
    } while ($true)
    Invoke-Checked kubectl --context $Context apply -f "$project/monitoring/dashboard.yaml"
} finally {
    $ErrorActionPreference='Continue'
    $log=& kubectl --context $Context -n $namespace logs "job/$jobName" --tail=300 --request-timeout=30s 2>&1 | Out-String -Width 240
    [IO.Directory]::CreateDirectory("$project/artifacts") | Out-Null
    [IO.File]::WriteAllText("$project/artifacts/bootstrap-in-cluster.local.log",$log,(New-Object Text.UTF8Encoding($false)))
    Write-Host $log
    & kubectl --context $Context -n $namespace delete job $jobName --ignore-not-found --wait=false --request-timeout=30s
    & kubectl --context $Context delete clusterrolebinding herodesk-chart-installer --ignore-not-found --request-timeout=30s
    & kubectl --context $Context delete namespace $namespace --ignore-not-found --wait=false --request-timeout=30s
}
