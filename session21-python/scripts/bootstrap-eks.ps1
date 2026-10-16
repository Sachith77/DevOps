# Installs cluster services AFTER terraform apply.
param([string]$MonitoringChartVersion = '92.9.0', [string]$ArgoChartVersion = '10.10.5')
. "$PSScriptRoot/common.ps1"
$project = Split-Path $PSScriptRoot -Parent
Push-Location "$project/terraform"
try {
    $region = Invoke-Checked terraform output -raw aws_region
    $cluster = Invoke-Checked terraform output -raw cluster_name
    $vpc = Invoke-Checked terraform output -raw vpc_id
} finally { Pop-Location }
Invoke-Checked aws eks update-kubeconfig --region $region --name $cluster --alias $cluster
Invoke-Checked kubectl --context $cluster get nodes
Invoke-Checked kubectl --context $cluster apply -f "$project/k8s/namespace.yaml"
Invoke-Checked kubectl --context $cluster apply -f "$project/k8s/gp3-storageclass.yaml"
Invoke-Checked helm repo add eks https://aws.github.io/eks-charts
Invoke-Checked helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
Invoke-Checked helm repo add argo https://argoproj.github.io/argo-helm
Invoke-Checked helm repo update
# Policy pinned to controller v2.14.1 / chart 1.14.0.
Invoke-Checked helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --version 1.14.0 --kube-context $cluster -n kube-system --set image.tag=v2.14.1 --set "clusterName=$cluster" --set "region=$region" --set "vpcId=$vpc" --set serviceAccount.create=true --set serviceAccount.name=aws-load-balancer-controller --wait --timeout 10m
Invoke-Checked helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --version $MonitoringChartVersion --kube-context $cluster -n monitoring --create-namespace -f "$project/monitoring/prometheus-values.yaml" --wait --timeout 15m
Invoke-Checked kubectl --context $cluster apply -f "$project/monitoring/dashboard.yaml"
Invoke-Checked helm upgrade --install argocd argo/argo-cd --version $ArgoChartVersion --kube-context $cluster -n argocd --create-namespace --wait --timeout 15m
Write-Host 'Controllers installed. Create the database Secret and publish images before applying argocd/application.yaml.'
