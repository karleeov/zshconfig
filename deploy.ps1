#Requires -Version 7
# Run from anywhere on Windows: ./deploy.ps1
$ErrorActionPreference = 'Stop'

$repo = $PSScriptRoot

function Backup-Copy {
    param([string]$Source, [string]$Target)
    $parent = Split-Path $Target -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if ((Test-Path $Target) -and ((Get-FileHash $Source).Hash -ne (Get-FileHash $Target).Hash)) {
        Copy-Item $Target "$Target.bak" -Force
        Write-Host "backed up: $Target -> $Target.bak"
    }
    Copy-Item $Source $Target -Force
    Write-Host "installed: $Target"
}

Backup-Copy -Source (Join-Path $repo '.wezterm.lua') `
            -Target (Join-Path $env:USERPROFILE '.config\wezterm\wezterm.lua')
Backup-Copy -Source (Join-Path $repo 'starship.toml') `
            -Target (Join-Path $env:USERPROFILE '.config\starship.toml')
Backup-Copy -Source (Join-Path $repo 'pwsh\Microsoft.PowerShell_profile.ps1') `
            -Target $PROFILE

# lazygit (config lives at %LOCALAPPDATA%\lazygit\config.yml)
Backup-Copy -Source (Join-Path $repo 'lazygit\config.yml') `
            -Target (Join-Path $env:LOCALAPPDATA 'lazygit\config.yml')

# nvim: LazyVim config (Neovim on Windows reads %LOCALAPPDATA%\nvim)
$nvimTarget = Join-Path $env:LOCALAPPDATA 'nvim'
New-Item -ItemType Directory -Path $nvimTarget -Force | Out-Null
Copy-Item (Join-Path $repo 'nvim\*') $nvimTarget -Recurse -Force
Write-Host "installed: $nvimTarget (LazyVim)"

Write-Host ''
Write-Host 'done. restart your terminal.'
