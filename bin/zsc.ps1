#Requires -Version 7
# zsc - knife-set CLI, Windows side. WSL subcommands bridge via wsl.exe.
# The repo's install/deploy scripts do the work; this only routes.
[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Command = 'help',
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)

$repo = (Split-Path $PSScriptRoot -Parent)
$wslRepo = (($repo -replace '\\', '/') -replace '^[A-Za-z]:', '/mnt/c').ToLower()
$skillsCli = if ($env:SKILLS_CLI_VERSION) { "skills@$($env:SKILLS_CLI_VERSION)" } else { 'skills@1.8.1' }
$env:DISABLE_TELEMETRY = '1'
$env:DO_NOT_TRACK = '1'

$script:winTools = 'nvim', 'lazygit', 'spf', 'fzf', 'starship', 'zoxide', 'eza', 'bat', 'fd', 'rg', 'gh', 'git', 'pwsh', 'delta', 'mise'

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
zsc - knife-set setup CLI

  zsc setup     install tools + deploy configs (Windows), then WSL if reachable
  zsc install   Windows: winget tool set only
  zsc deploy    Windows: push configs only
  zsc wsl       WSL: install.sh + deploy.sh inside the default distro
  zsc pentest   WSL: bug-hunt toolkit (pdtm suite, massdns, Caido, wordlists)
  zsc knife     WSL: opt-in CLI profiles; preview with: zsc knife --dry-run all
  zsc skills    agent skills: install / check / update / doctor / schedule
  zsc update    git pull + redeploy + skills update check (no auto-update)
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
    Cmd-SkillsCheck
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
    if (Test-Path "$env:USERPROFILE\.agents\skills\chef-knife-roll\SKILL.md") { Write-Host '  ok      shared chef-knife-roll skill' }
    else { Write-Host '  MISSING shared chef-knife-roll skill   -> zsc deploy' -ForegroundColor Yellow; $fail++ }

    Write-Host '== WSL =='
    $w = Get-Wsl
    switch ($w.State) {
        'broken' { Write-Host '  broken  -> elevated: Add-AppxPackage ...\Temp\wsl.msixbundle ; wsl --shutdown' -ForegroundColor Red; $fail++ }
        'empty'  { Write-Host '  no distro  -> elevated: wsl --install -d Ubuntu' -ForegroundColor Yellow }
        default {
            $d = $w.Distributions[0]
            Write-Host ("  distro  {0}" -f $d)
            $probe = 'for c in zsh tmux nvim fzf zoxide eza bat rg fd starship mise lazygit workmux recon; do command -v $c >/dev/null 2>&1 || echo "MISSING:$c"; done; [ -d ~/.tmux/plugins/tpm ] || echo "MISSING:tpm"; [ -f ~/.config/tmux/tmux.conf ] || echo "MISSING:tmux.conf"; [ -f ~/.agents/skills/chef-knife-roll/SKILL.md ] || echo "MISSING:chef-knife-roll"'
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

function Cmd-Pentest {
    $w = Get-Wsl
    switch ($w.State) {
        'broken' { Show-WslFix; exit 1 }
        'empty'  { Write-Host 'No WSL distro installed - the pentest toolkit is Linux-side.' -ForegroundColor Yellow; Write-Host 'From elevated PowerShell:  wsl --install -d Ubuntu'; exit 1 }
        default {
            $d = $w.Distributions[0]
            Write-Host "==> WSL distro: $d (deploy configs + pentest toolkit)"
            $cmd = './deploy.sh && ./pentest.sh'
            if ($Rest) { $cmd += ' ' + ($Rest -join ' ') }
            $code = Invoke-InWsl $d $cmd
            if ($code -ne 0) { exit $code }
            Write-Host ''
            Write-Host 'Caido Desktop (Windows proxy UI): https://www.caido.io/download/'
            Write-Host '  CLI is installed in WSL - pair it with the Desktop app or run `caido` inside WSL.'
        }
    }
}

function Cmd-Knife {
    $allowed = @('--dry-run', '--yes', '-n', '-y', 'list', 'all', 'development', 'security', 'infrastructure', 'databases', 'work', 'design', 'business')
    foreach ($arg in @($Rest)) {
        if ($allowed -notcontains $arg) { throw "invalid zsc knife argument: $arg" }
    }
    $w = Get-Wsl
    switch ($w.State) {
        'broken' { Show-WslFix; exit 1 }
        'empty'  { Write-Host 'No WSL distro installed - knife profiles are Linux-side.' -ForegroundColor Yellow; exit 1 }
        default {
            $d = $w.Distributions[0]
            $cmd = './knife-roll/install.sh'
            if ($Rest) { $cmd += ' ' + ($Rest -join ' ') }
            $code = Invoke-InWsl $d $cmd
            if ($code -ne 0) { exit $code }
        }
    }
}

function Show-SkillsUsage {
    @'
usage: zsc skills <command>

  install    add curated repos in skills-packages.txt to ~/.agents/skills
  check      report available updates without changing skills
  update     manually apply updates after reviewing changes
  doctor     check store, native discovery, Claude link, node version
  schedule   legacy task: off / status (automatic updates are discouraged)
'@ | Write-Host
}

function Ensure-SkillsLink([string]$Store) {
    # ~/.claude/skills must be a junction to the store; never touch what already exists
    $link = "$HOME\.claude\skills"
    if (Test-Path $link) {
        $item = Get-Item $link -Force
        $target = @($item.Target)[0]
        if ($item.LinkType -eq 'Junction' -and $target -eq $Store) { return }
        if ($item.LinkType) { Write-Host "warning: $link is a $($item.LinkType) to $target, expected junction -> $Store - leaving it alone" -ForegroundColor Yellow }
        else { Write-Host "warning: $link is a real directory, expected junction -> $Store - leaving it alone" -ForegroundColor Yellow }
        return
    }
    $parent = Split-Path $link -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    New-Item -ItemType Junction -Path $link -Target $Store | Out-Null
    Write-Host "linked: $link -> $Store"
}

function Cmd-SkillsCheck {
    $npx = Resolve-Tool 'npx'
    if (-not $npx) { Write-Host 'npx not found - skipping skills check (install Node >= 22.20)' -ForegroundColor Yellow; return }
    Write-Host '==> skills update check (read-only)'
    & $npx --yes $skillsCli check -g
    if ($LASTEXITCODE -ne 0) { Write-Host 'skills check failed' -ForegroundColor Red }
}

function Cmd-SkillsUpdate {
    $npx = Resolve-Tool 'npx'
    if (-not $npx) { Write-Host 'npx not found - skipping skills update (install Node >= 22.20)' -ForegroundColor Yellow; return }
    Write-Host '==> manual skills update; review changed instructions, hooks, and scripts afterwards'
    & $npx --yes $skillsCli update -g -y
    if ($LASTEXITCODE -ne 0) { Write-Host 'skills update failed' -ForegroundColor Red }
}

function Cmd-SkillsInstall {
    $npx = Resolve-Tool 'npx'
    if (-not $npx) { Write-Host 'npx not found - install Node >= 22.20, then re-run: zsc skills install' -ForegroundColor Yellow; return }

    $store = "$HOME\.agents\skills"
    if (-not (Test-Path $store)) { New-Item -ItemType Directory -Path $store -Force | Out-Null }
    Ensure-SkillsLink $store

    $fail = 0
    $entries = Get-Content (Join-Path $repo 'skills-packages.txt') | Where-Object { $_ -notmatch '^\s*(#|$)' }
    foreach ($line in $entries) {
        $slug = $line.Trim()
        $sel = '*'
        $i = $slug.IndexOf(':')
        if ($i -ge 0) {
            $sel = $slug.Substring($i + 1)
            $slug = $slug.Substring(0, $i)
        }
        Write-Host "==> $slug"
        $skillArgs = $sel -split ','
        & $npx --yes $skillsCli add $slug -g -y -a pi -a cursor -a claude-code -a github-copilot -s @skillArgs
        if ($LASTEXITCODE -ne 0) { Write-Host "  failed  $slug" -ForegroundColor Red; $fail++ }
    }
    if ($fail) { Write-Host "$fail skill repo(s) failed" -ForegroundColor Red; exit 1 }
}

function Cmd-SkillsDoctor {
    $fail = 0
    $store = "$HOME\.agents\skills"

    Write-Host '== skills store =='
    if (Test-Path $store) {
        $count = @(Get-ChildItem -Path "$HOME\.agents\skills\*\SKILL.md" -ErrorAction SilentlyContinue).Count
        Write-Host ("  ok      {0} ({1} skills)" -f $store, $count)
    }
    else { Write-Host ("  MISSING {0}   -> zsc skills install" -f $store) -ForegroundColor Red; $fail++ }

    Write-Host '== claude link =='
    $link = "$HOME\.claude\skills"
    if (-not (Test-Path $link)) { Write-Host ("  MISSING {0}   -> zsc skills install" -f $link) -ForegroundColor Red; $fail++ }
    else {
        $item = Get-Item $link -Force
        $target = @($item.Target)[0]
        if ($item.LinkType -eq 'Junction' -and $target -eq $store) { Write-Host ("  ok      {0} -> {1}" -f $link, $store) }
        elseif ($item.LinkType) { Write-Host ("  WRONG   {0} -> {1} (expected {2})   -> remove it, re-run: zsc skills install" -f $link, $target, $store) -ForegroundColor Yellow; $fail++ }
        else { Write-Host ("  REALDIR {0} is a real directory (expected junction -> {1})   -> move its contents into the store, re-run: zsc skills install" -f $link, $store) -ForegroundColor Yellow; $fail++ }
    }

    Write-Host '== native discovery =='
    Write-Host '  pi / Cursor / Kimi Code / OpenCode: ~/.agents/skills'
    if (Test-Path "$store\chef-knife-roll\SKILL.md") { Write-Host '  ok      chef-knife-roll' }
    else { Write-Host '  MISSING chef-knife-roll   -> zsc deploy' -ForegroundColor Red; $fail++ }

    Write-Host '== node =='
    $node = Resolve-Tool 'node'
    if (-not $node) { Write-Host '  MISSING node   -> install Node >= 22.20 (npx needs it)' -ForegroundColor Red; $fail++ }
    else {
        $ver = ((& $node --version) -replace '^v', '').Trim()
        $v = $ver -as [version]
        if (-not $v) { Write-Host "  note    node $ver (unrecognized version string)" }
        elseif ($v -lt [version]'22.20.0') { Write-Host "  OLD     node $ver   needs >= 22.20.0   -> upgrade Node" -ForegroundColor Yellow; $fail++ }
        else { Write-Host "  ok      node $ver" }
    }

    if ($fail) { Write-Host "`n$fail issue(s). Fix with: zsc skills install" -ForegroundColor Yellow; exit 1 }
    Write-Host "`nall green." -ForegroundColor Green
}

function Cmd-SkillsUnblock {
    Write-Host 'Defender exclusions are not part of the curated setup. Keep antivirus scanning enabled and remove the offensive mega-packs from the daily store.' -ForegroundColor Yellow
    exit 1
}

function Cmd-SkillsSchedule([string]$Action = 'status') {
    $task = 'ZscSkillsUpdate'
    switch ($Action) {
        'on' {
            Write-Host 'automatic skill updates are disabled in the curated setup. Run zsc skills check, review changes, then zsc skills update manually.' -ForegroundColor Yellow
            exit 1
        }
        'off' {
            $null = & schtasks.exe /Delete /TN $task /F 2>$null
            if ($LASTEXITCODE -eq 0) { Write-Host "removed scheduled task $task" }
            else { Write-Host "no scheduled task $task" }
        }
        default {
            $null = & schtasks.exe /Query /TN $task 2>$null
            if ($LASTEXITCODE -eq 0) { Write-Host "legacy task active: $task - disable it with: zsc skills schedule off" -ForegroundColor Yellow }
            else { Write-Host 'not scheduled (recommended); use zsc skills check for manual review' }
        }
    }
}

function Cmd-Skills {
    $sub = ''
    $more = @()
    if ($Rest) {
        $r = @($Rest)
        $sub = [string]$r[0]
        if ($r.Count -gt 1) { $more = $r[1..($r.Count - 1)] }
    }
    switch ($sub) {
        'install'  { Cmd-SkillsInstall }
        'check'    { Cmd-SkillsCheck }
        'update'   { Cmd-SkillsUpdate }
        'doctor'   { Cmd-SkillsDoctor }
        'schedule' { Cmd-SkillsSchedule ([string]@($more)[0]) }
        'unblock'  { Cmd-SkillsUnblock }
        'help'     { Show-SkillsUsage }
        default    { Show-SkillsUsage; exit 1 }
    }
}

switch ($Command) {
    'setup'  { Cmd-Setup }
    'install' { Cmd-Install }
    'deploy' { Cmd-Deploy }
    'wsl'    { Cmd-Wsl }
    'pentest' { Cmd-Pentest }
    'knife'   { Cmd-Knife }
    'skills'  { Cmd-Skills }
    'update' { Cmd-Update }
    'doctor' { Cmd-Doctor }
    default  { Show-Usage; if ($Command -ne 'help') { exit 1 } }
}
