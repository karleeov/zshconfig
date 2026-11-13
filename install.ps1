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
    # Strip inline comments as well as full-line comments; never pass them to winget.
    $packages = Get-Content $list | ForEach-Object { ($_ -split '#', 2)[0].Trim() } | Where-Object { $_ }
    $failed = @()
    foreach ($pkg in $packages) {
        Write-Host "==> $pkg"
        $listOutput = & winget list --exact --id $pkg --accept-source-agreements --disable-interactivity 2>&1 | Out-String
        # Some winget versions can return success for an empty list; require the ID too.
        if ($LASTEXITCODE -eq 0 -and $listOutput.Contains($pkg)) {
            Write-Host "  already installed"
            continue
        }
        & winget install --exact --id $pkg --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "failed: $pkg (winget exit $LASTEXITCODE)"
            $failed += $pkg
        }
    }
    if ($failed.Count -gt 0) {
        # Do not mark a partial/failed pass as successful.
        throw "winget failed for: $($failed -join ', '). Fix these packages and re-run; the hash marker was not written."
    }
    New-Item -ItemType Directory -Path $markerDir -Force | Out-Null
    Set-Content -Path $marker -Value $newHash
}

Write-Host ''
Write-Host '==> applying configs (deploy.ps1)'
# deploy.ps1 requires pwsh 7; this script may run on 5.1, whose PATH predates a just-installed pwsh.
$pwshExe = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshExe) {
    $pwshExe = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    if (-not (Test-Path $pwshExe)) { $pwshExe = $null }
}
if ($pwshExe) {
    & $pwshExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'deploy.ps1')
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'deploy failed - restart the terminal, then run ./deploy.ps1'
    }
} else {
    Write-Host 'pwsh 7 not on PATH yet (installed this run) - restart the terminal, then run ./deploy.ps1' -ForegroundColor Yellow
}
Write-Host ''
Write-Host 'done. restart your terminal for the starship prompt.'
