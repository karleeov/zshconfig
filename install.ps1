# One-time Windows bootstrap: installs the tool set via winget.
# Runs on stock Windows PowerShell 5.1 (this script installs pwsh 7 itself).
# Idempotent: package list read from winget-packages.txt, hash-guarded —
# already-installed packages are skipped by winget, and unchanged lists
# skip the whole pass (delete %LOCALAPPDATA%\zsc\winget-packages.sha256 to force).
$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot
$list = Join-Path $repo 'winget-packages.txt'
$markerDir = Join-Path $env:LOCALAPPDATA 'zsc'
$marker = Join-Path $markerDir 'winget-packages.sha256'
$newHash = (Get-FileHash -Algorithm SHA256 $list).Hash

if ((Test-Path $marker) -and ((Get-Content $marker -ErrorAction SilentlyContinue) -eq $newHash)) {
    Write-Host "winget packages unchanged since last run - skipping"
} else {
    $packages = Get-Content $list | ForEach-Object { ($_ -split '#')[0].Trim() } | Where-Object { $_ }
    foreach ($pkg in $packages) {
        Write-Host "==> $pkg"
        winget install --id $pkg --accept-package-agreements --accept-source-agreements --disable-interactivity
    }
    New-Item -ItemType Directory -Path $markerDir -Force | Out-Null
    Set-Content -Path $marker -Value $newHash
}

Write-Host ''
Write-Host 'done. run ./deploy.ps1 to push configs.'
