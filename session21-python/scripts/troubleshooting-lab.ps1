param([string]$Context = 'herodesk-eks', [switch]$KeepNamespace)
. "$PSScriptRoot/common.ps1"
$project = Split-Path $PSScriptRoot -Parent
$namespace = 'herodesk-lab'
$namespaceObject = @{apiVersion='v1';kind='Namespace';metadata=@{name=$namespace}} | ConvertTo-Json -Depth 5
$namespaceObject | & kubectl --context $Context apply -f -
if ($LASTEXITCODE -ne 0) { throw 'Could not create the isolated troubleshooting namespace.' }
Invoke-Checked kubectl --context $Context -n $namespace apply -f "$project/troubleshooting/broken-image.yaml"
Start-Sleep -Seconds 20
Invoke-Checked kubectl --context $Context -n $namespace get pods
Invoke-Checked kubectl --context $Context -n $namespace describe deployment taskboard-broken-image
Invoke-Checked kubectl --context $Context -n $namespace get events --sort-by=.lastTimestamp
Write-Host 'Repair: use an existing image and wait for the deployment.'
Invoke-Checked kubectl --context $Context -n $namespace set image deployment/taskboard-broken-image backend=nginx:stable-alpine
Invoke-Checked kubectl --context $Context -n $namespace rollout status deployment/taskboard-broken-image --timeout=5m
Invoke-Checked kubectl --context $Context -n $namespace apply -f "$project/troubleshooting/broken-service.yaml"
Invoke-Checked kubectl --context $Context -n $namespace get pods --show-labels
Invoke-Checked kubectl --context $Context -n $namespace get endpointslices -l kubernetes.io/service-name=broken-service
Write-Host 'Repair: align the Service selector and target port with the diagnostic Pod.'
$service = @{apiVersion='v1';kind='Service';metadata=@{name='broken-service'};spec=@{selector=@{app='broken-image'};ports=@(@{port=8000;targetPort=80})}} | ConvertTo-Json -Depth 8
$service | & kubectl --context $Context -n $namespace apply -f -
if ($LASTEXITCODE -ne 0) { throw 'Could not repair the diagnostic Service.' }
Start-Sleep -Seconds 5
Invoke-Checked kubectl --context $Context -n $namespace get endpointslices -l kubernetes.io/service-name=broken-service
if (-not $KeepNamespace) { Invoke-Checked kubectl --context $Context delete namespace $namespace --wait=true --timeout=5m }
