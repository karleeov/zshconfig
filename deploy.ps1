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

# agent skills (SKILL.md format — read by Claude Code, pi, and other
# Agent Skills-compatible harnesses). Backups go OUTSIDE the skills dir,
# so stale copies are never indexed as skills.
$skillsSrc = Join-Path $repo 'skills'
function Sync-Skills {
    param([string]$TargetRoot)
    $bakRoot = "$TargetRoot.bak"
    New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
    foreach ($src in (Get-ChildItem $skillsSrc -Directory)) {
        $dst = Join-Path $TargetRoot $src.Name
        if ((Test-Path $dst) -and (& $DirHash $src.FullName) -ne (& $DirHash $dst)) {
            New-Item -ItemType Directory -Path $bakRoot -Force | Out-Null
            if (Test-Path (Join-Path $bakRoot $src.Name)) { Remove-Item (Join-Path $bakRoot $src.Name) -Recurse -Force }
            Copy-Item $dst (Join-Path $bakRoot $src.Name) -Recurse -Force
            Write-Host "backed up: $dst -> $bakRoot\$($src.Name)"
        }
        if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
        Copy-Item $src.FullName $dst -Recurse -Force
        Write-Host "installed: $dst"
    }
}
if (Test-Path $skillsSrc) {
    $DirHash = {
        param([string]$Path)
        (Get-ChildItem $Path -Recurse -File | Sort-Object FullName |
            ForEach-Object { '{0}:{1}' -f $_.FullName.Substring($Path.Length + 1), (Get-FileHash $_.FullName).Hash }) -join '|'
    }
    Sync-Skills (Join-Path $env:USERPROFILE '.claude\skills')     # Claude Code (one level deep)
    Sync-Skills (Join-Path $env:USERPROFILE '.pi\agent\skills')  # pi coding agent (discovers recursively)
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
