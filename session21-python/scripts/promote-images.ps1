param([Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{40}$')][string]$ImageSha)
. "$PSScriptRoot/common.ps1"
$project = Split-Path $PSScriptRoot -Parent
foreach ($component in @('backend','frontend')) {
    $null = Invoke-Checked docker manifest inspect "ghcr.io/sachith77/herodesk-${component}:$ImageSha"
}
$content = "backend:`n  image: ghcr.io/sachith77/herodesk-backend`n  tag: '$ImageSha'`nfrontend:`n  image: ghcr.io/sachith77/herodesk-frontend`n  tag: '$ImageSha'`n"
[IO.File]::WriteAllText("$project/gitops/images.yaml", $content, (New-Object Text.UTF8Encoding($false)))
Write-Host "Verified both published images and updated gitops/images.yaml to $ImageSha. Commit and push this file to main."
