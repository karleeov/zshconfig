# Microsoft.PowerShell_profile.ps1 — managed by zshconfig repo
# Mirrors .zshrc aliases. Missing tools are skipped silently (guard pattern).

# ── PSReadLine ────────────────────────────────────────────────────────
if (Get-Module -ListAvailable PSReadLine) {
    try {
        Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
    } catch {
        # redirected/non-VT consoles reject predictive features
    }
    try {
        Set-PSReadLineOption -Colors @{
            Command            = '#00ff9f'
            Parameter          = '#00b8ff'
            String             = '#FFD580'
            Variable           = '#BD00FF'
            Operator           = '#D14EEA'
            Comment            = '#6c6c6c'
            Keyword            = '#D14EEA'
            Number             = '#FFCC66'
            Type               = '#6300FF'
            Member             = '#CBCCC6'
            InlinePrediction   = '#6c6c6c'
            Selection          = '#33415E'
        }
    } catch {
        # older PSReadLine rejects some color keys
    }
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# ── Prompt / tool integrations (guarded) ─────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    $starshipInit = &starship init powershell 2>$null | Out-String
    if ($starshipInit.Trim()) { Invoke-Expression $starshipInit }
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (&zoxide init powershell | Out-String)
}
if (Get-Command mise -ErrorAction SilentlyContinue) {
    $miseInit = mise activate pwsh 2>$null | Out-String
    if ($miseInit.Trim()) { Invoke-Expression $miseInit }
}

# ── Aliases mirroring zsh (guarded) ──────────────────────────────────
if ($ezaCommand = Get-Command eza -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1) {
    try {
        # WinGet links can fail with "untrusted mount point"; use the real binary.
        $ezaExecutable = Get-Item -LiteralPath $ezaCommand.Source -ErrorAction Stop
        if ($ezaExecutable.LinkType -eq 'SymbolicLink') {
            $ezaTarget = [string]$ezaExecutable.Target
            if (-not [System.IO.Path]::IsPathRooted($ezaTarget)) {
                $ezaTarget = Join-Path $ezaExecutable.DirectoryName $ezaTarget
            }
            $ezaExecutable = Get-Item -LiteralPath $ezaTarget -ErrorAction Stop
        }
        Set-Alias -Name eza -Value $ezaExecutable.FullName -Scope Global
        function ls { & eza --long --group-directories-first --icons=always @args }
        Remove-Item Alias:\ls -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "eza initialization skipped: $_"
    }
}
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat { & bat --style=plain @args }
}
Remove-Item Alias:\cat -Force -ErrorAction SilentlyContinue
foreach ($pair in @{ grep='rg'; find='fd'; top='btop'; vim='nvim' }.GetEnumerator()) {
    if (Get-Command $pair.Value -ErrorAction SilentlyContinue) {
        Set-Alias -Name $pair.Key -Value $pair.Value -Force
    }
}
# Default aliases would shadow our git shortcut functions (Alias beats Function)
Remove-Item Alias:\gc, Alias:\gp, Alias:\gl -Force -ErrorAction SilentlyContinue

# ── Git shortcuts ────────────────────────────────────────────────────
function gs  { git status @args }
function gc  { git commit -m @args }
function gp  { git push @args }
function gco { git checkout @args }
function gl  { git log --graph --oneline --decorate @args }
function gd  { git diff @args }

# ── Misc ─────────────────────────────────────────────────────────────
# PowerShell cannot dot-source into the caller's scope from a function;
# to reload the profile run:  . $PROFILE
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    if (Get-Command lolcat -ErrorAction SilentlyContinue) {
        function fetch { fastfetch | lolcat }
    } else {
        function fetch { fastfetch }
    }
}
