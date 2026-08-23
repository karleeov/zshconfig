#Requires -Version 7
# Run from repo root on Windows: ./deploy.ps1
$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot

function Backup-Copy {
    param([string]$Source, [string]$Target)
    $parent = Split-Path $Target -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (Test-Path $Target) {
        Copy-Item $Target "$Target.bak" -Force
        Write-Host "backed up: $Target -> $Target.bak"
    }
    Copy-Item $Source $Target -Force
    Write-Host "installed: $Target"
}

Backup-Copy -Source (Join-Path $repo '.wezterm.lua') `
            -Target (Join-Path $env:USERPROFILE '.config\wezterm\wezterm.lua')
Backup-Copy -Source (Join-Path $repo 'starship.toml') `
            -Target (Join-Path $env:USERPROFILE '.config\starship\starship.toml')
Backup-Copy -Source (Join-Path $repo 'pwsh\Microsoft.PowerShell_profile.ps1') `
            -Target $PROFILE

Write-Host ''
Write-Host 'done. restart your terminal.'
