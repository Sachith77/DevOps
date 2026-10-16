# Keep the validated Helm version local to this project; preserve system Helm.
. "$PSScriptRoot/common.ps1"
$version='3.17.3'
$directory=Join-Path (Split-Path $PSScriptRoot -Parent) '.tools/helm'
New-Item -ItemType Directory -Path $directory -Force | Out-Null
$archive=Join-Path $directory 'helm.zip'
$checksumFile=Join-Path $directory 'helm.sha256sum'
if (-not ((Test-Path $archive) -and (Test-Path $checksumFile))) {
    Invoke-WebRequest "https://get.helm.sh/helm-v$version-windows-amd64.zip" -OutFile $archive -UseBasicParsing
    Invoke-WebRequest "https://get.helm.sh/helm-v$version-windows-amd64.zip.sha256sum" -OutFile $checksumFile -UseBasicParsing
}
$expected=((Get-Content $checksumFile -Raw) -split '\s+')[0]
$actual=(Get-FileHash $archive -Algorithm SHA256).Hash
if ($expected -ne $actual) { throw 'Helm archive checksum mismatch.' }
Expand-Archive -LiteralPath $archive -DestinationPath $directory -Force
Invoke-Checked (Join-Path $directory 'windows-amd64/helm.exe') version --short
Write-Host 'Verified project-local Helm installed. The lab scripts select it automatically.'
