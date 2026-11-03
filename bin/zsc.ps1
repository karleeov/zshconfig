#Requires -Version 7
# zsc — knife-set CLI, Windows side. WSL subcommands bridge via wsl.exe.
# The repo's install/deploy scripts do the work; this only routes.
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Command = 'help',
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)

$repo = (Split-Path $PSScriptRoot -Parent)
$wslRepo = (($repo -replace '\\', '/') -replace '^[A-Za-z]:', '/mnt/c').ToLower()

$script:winTools = 'nvim', 'lazygit', 'spf', 'fzf', 'starship', 'zoxide', 'eza', 'bat', 'fd', 'rg', 'gh', 'git', 'pwsh'

function Get-FreshPath {
    $m = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $u = [Environment]::GetEnvironmentVariable('Path', 'User')
    return "$m;$u"
}

function Resolve-Tool([string]$Name) {
    $prev = $env:Path
    $env:Path = Get-FreshPath
    try { $c = Get-Command $Name -ErrorAction SilentlyContinue } finally { $env:Path = $prev }
    return $c
}

function Get-Wsl {
    # broken WSL can hang or error; probe in a job with a timeout
    $job = Start-Job { (& wsl.exe -l -q 2>&1 | Out-String) -replace "`0", '' }
    if (-not (Wait-Job $job -Timeout 20)) {
        Stop-Job $job; Remove-Job $job -Force
        return @{ State = 'broken' ; Distributions = @() }
    }
    $raw = Receive-Job $job
    Remove-Job $job
    if (-not $raw -or $LASTEXITCODE -ne 0 -or $raw -match 'Class not registered|REGDB|0x80070') {
        return @{ State = 'broken' ; Distributions = @() }
    }
    $distros = $raw -split "`r?`n" | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() }
    if (-not $distros -or $distros -contains 'Windows Subsystem for Linux has no installed distributions.') {
        return @{ State = 'empty' ; Distributions = @() }
    }
    return @{ State = 'ok' ; Distributions = @($distros | Where-Object { $_ -notmatch 'docker-desktop' }) }
}

function Show-WslFix {
    Write-Host 'WSL is broken (REGDB_E_CLASSNOTREG).' -ForegroundColor Red
    Write-Host 'Fix once from an ELEVATED PowerShell:'
    Write-Host '  Add-AppxPackage C:\Users\'"$env:USERNAME"'\AppData\Local\Temp\wsl.msixbundle'
    Write-Host '  wsl --shutdown'
    Write-Host 'Then re-run: zsc wsl'
}

function Invoke-InWsl([string]$Distro, [string]$Command) {
    & wsl.exe -d $Distro -e bash -lc "cd $wslRepo && $Command"
    return $LASTEXITCODE
}

function Show-Usage {
    @'
zsc — knife-set setup CLI

  zsc setup     install tools + deploy configs (Windows), then WSL if reachable
  zsc install   Windows: winget tool set only
  zsc deploy    Windows: push configs only
  zsc wsl       WSL: install.sh + deploy.sh inside the default distro
  zsc update    git pull this repo, redeploy both sides
  zsc doctor    health check: tools, WSL, config drift
'@ | Write-Host
}

function Cmd-Install { & (Join-Path $repo 'install.ps1') @Rest }

function Cmd-Deploy { & (Join-Path $repo 'deploy.ps1') @Rest }

function Cmd-Wsl {
    $w = Get-Wsl
    switch ($w.State) {
        'broken' { Show-WslFix; exit 1 }
        'empty'  { Write-Host 'No WSL distro installed.' -ForegroundColor Yellow; Write-Host 'From elevated PowerShell:  wsl --install -d Ubuntu'; exit 1 }
        default  {
            $d = $w.Distributions[0]
            Write-Host "==> WSL distro: $d (install + deploy)"
            $code = Invoke-InWsl $d './install.sh && ./deploy.sh'
            if ($code -eq 0) { Write-Host "WSL done. Start tmux once and press prefix+I to load plugins." }
            exit $code
        }
    }
}

function Cmd-Update {
    git -C $repo pull --ff-only
    if ($LASTEXITCODE -ne 0) { exit 1 }
    Cmd-Deploy
    $w = Get-Wsl
    if ($w.State -eq 'ok') {
        Invoke-InWsl $w.Distributions[0] './deploy.sh' | Out-Host
    }
}

function Cmd-Setup {
    Cmd-Install
    Cmd-Deploy
    $w = Get-Wsl
    if ($w.State -eq 'ok') { Cmd-Wsl }
    elseif ($w.State -eq 'broken') { Write-Host ''; Show-WslFix }
    else { Write-Host 'No WSL distro yet; run "wsl --install -d Ubuntu" (elevated), then: zsc wsl' }
}

function Cmd-Doctor {
    $fail = 0

    Write-Host '== Windows tools =='
    foreach ($t in $script:winTools) {
        $c = Resolve-Tool $t
        if ($c) { Write-Host ("  ok      {0}" -f $t) }
        else { Write-Host ("  MISSING {0}   -> zsc install" -f $t) -ForegroundColor Red; $fail++ }
    }

    Write-Host '== Windows config drift =='
    $pairs = @(
        @{ src = "$repo\.wezterm.lua";  dst = "$env:USERPROFILE\.config\wezterm\wezterm.lua" },
        @{ src = "$repo\starship.toml"; dst = "$env:USERPROFILE\.config\starship.toml" },
        @{ src = "$repo\lazygit\config.yml"; dst = "$env:LOCALAPPDATA\lazygit\config.yml" },
        @{ src = "$repo\nvim\init.lua"; dst = "$env:LOCALAPPDATA\nvim\init.lua" },
        @{ src = "$repo\pwsh\Microsoft.PowerShell_profile.ps1"; dst = $PROFILE }
    )
    foreach ($p in $pairs) {
        if (-not (Test-Path $p.dst)) { Write-Host ("  absent  {0}   -> zsc deploy" -f $p.dst) -ForegroundColor Yellow; $fail++ }
        elseif ((Get-FileHash $p.src).Hash -ne (Get-FileHash $p.dst).Hash) {
            Write-Host ("  drift   {0}   -> zsc deploy" -f $p.dst) -ForegroundColor Yellow; $fail++
        }
        else { Write-Host ("  ok      {0}" -f $p.dst) }
    }

    Write-Host '== WSL =='
    $w = Get-Wsl
    switch ($w.State) {
        'broken' { Write-Host '  broken  -> elevated: Add-AppxPackage ...\Temp\wsl.msixbundle ; wsl --shutdown' -ForegroundColor Red; $fail++ }
        'empty'  { Write-Host '  no distro  -> elevated: wsl --install -d Ubuntu' -ForegroundColor Yellow }
        default {
            $d = $w.Distributions[0]
            Write-Host ("  distro  {0}" -f $d)
            $probe = 'for c in zsh tmux nvim fzf zoxide eza bat rg fd starship mise lazygit workmux; do command -v $c >/dev/null 2>&1 || echo "MISSING:$c"; done; [ -d ~/.tmux/plugins/tpm ] || echo "MISSING:tpm"; [ -f ~/.config/tmux/tmux.conf ] || echo "MISSING:tmux.conf"'
            $out = (& wsl.exe -d $d -e bash -lc $probe 2>&1) -replace "`0", ''
            $missing = @($out | Where-Object { $_ -match '^MISSING:' })
            if ($missing) {
                foreach ($m in $missing) { Write-Host ("  {0,-16} -> zsc wsl" -f $m) -ForegroundColor Yellow }
                $fail++
            }
            else { Write-Host '  ok      all tools + tpm + tmux.conf present' }
        }
    }

    if ($fail) { Write-Host "`n$fail issue(s). Fix with: zsc install / zsc deploy / zsc wsl" -ForegroundColor Yellow; exit 1 }
    Write-Host "`nall green." -ForegroundColor Green
}

switch ($Command) {
    'setup'  { Cmd-Setup }
    'install' { Cmd-Install }
    'deploy' { Cmd-Deploy }
    'wsl'    { Cmd-Wsl }
    'update' { Cmd-Update }
    'doctor' { Cmd-Doctor }
    default  { Show-Usage; if ($Command -ne 'help') { exit 1 } }
}
