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

# git: XDG config merged with ~/.gitconfig (delta pager, aliases, ghq root)
Backup-Copy -Source (Join-Path $repo 'git\config') `
            -Target (Join-Path $env:USERPROFILE '.config\git\config')

# mise: global tool versions (node/python/rust/go/ghq)
Backup-Copy -Source (Join-Path $repo 'mise\config.toml') `
            -Target (Join-Path $env:USERPROFILE '.config\mise\config.toml')

# nvim: LazyVim config (Neovim on Windows reads %LOCALAPPDATA%\nvim)
$nvimTarget = Join-Path $env:LOCALAPPDATA 'nvim'
New-Item -ItemType Directory -Path $nvimTarget -Force | Out-Null
Copy-Item (Join-Path $repo 'nvim\*') $nvimTarget -Recurse -Force
Write-Host "installed: $nvimTarget (LazyVim)"

# Local shared skill: Cursor, Kimi Code, and pi discover ~/.agents/skills natively.
$skillStore = Join-Path $env:USERPROFILE '.agents\skills'
$skillSource = Join-Path $repo 'skills\chef-knife-roll'
$skillLink = Join-Path $skillStore 'chef-knife-roll'
New-Item -ItemType Directory -Path $skillStore -Force | Out-Null
if (Test-Path $skillLink) {
    $item = Get-Item $skillLink -Force
    $target = @($item.Target)[0]
    if ($item.LinkType -eq 'Junction' -and $target -eq $skillSource) {
        Write-Host "linked: $skillLink -> $skillSource"
    } else {
        Write-Warning "$skillLink already exists and is not the expected junction; leaving it alone"
    }
} else {
    New-Item -ItemType Junction -Path $skillLink -Target $skillSource | Out-Null
    Write-Host "linked: $skillLink -> $skillSource"
}

# zsc CLI shim: %USERPROFILE%\bin\zsc.cmd on PATH
$binDir = Join-Path $env:USERPROFILE 'bin'
New-Item -ItemType Directory -Path $binDir -Force | Out-Null
$shimPath = Join-Path $binDir 'zsc.cmd'
Set-Content -Path $shimPath -Value "@pwsh -NoProfile -ExecutionPolicy Bypass -File `"$repo\bin\zsc.ps1`" %*" -Encoding Ascii
$key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
$curPath = [string]$key.GetValue('Path', '', 'DoNotExpandEnvironmentNames')
if ($curPath -notlike "*$binDir*") {
    $key.SetValue('Path', ($curPath.TrimEnd(';') + ";$binDir"), [Microsoft.Win32.RegistryValueKind]::ExpandString)
    [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User'), 'User')
    Write-Host "PATH updated: $binDir (new terminals only)"
}
$key.Close()
Write-Host "installed: $shimPath"

Write-Host ''
Write-Host 'done. restart your terminal.'
