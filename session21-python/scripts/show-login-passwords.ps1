# Run privately. Never include this output in screenshots, transcripts, or Git.
param([string]$Context = 'herodesk-eks')
. "$PSScriptRoot/common.ps1"
$argo = Invoke-Checked kubectl --context $Context -n argocd get secret argocd-initial-admin-secret -o 'jsonpath={.data.password}'
$grafana = Invoke-Checked kubectl --context $Context -n monitoring get secret kube-prometheus-stack-grafana -o 'jsonpath={.data.admin-password}'
Write-Host 'Argo CD username: admin'
Write-Host ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($argo)))
Write-Host 'Grafana username: admin'
Write-Host ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($grafana)))
Remove-Variable argo,grafana
