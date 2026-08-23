# Microsoft.PowerShell_profile.ps1 — managed by zshconfig repo
# Mirrors .zshrc aliases. Missing tools are skipped silently (guard pattern).

# ── PSReadLine ────────────────────────────────────────────────────────
if (Get-Module -ListAvailable PSReadLine) {
    Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
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
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# ── Prompt / tool integrations (guarded) ─────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (&zoxide init powershell | Out-String)
}
if (Get-Command mise -ErrorAction SilentlyContinue) {
    mise activate powershell | Out-String | Invoke-Expression
}

# ── Aliases mirroring zsh (guarded) ──────────────────────────────────
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls { & eza --long --group-directories-first --icons @args }
}
foreach ($pair in @{ cat='bat'; grep='rg'; find='fd'; top='btop'; vim='nvim' }.GetEnumerator()) {
    if (Get-Command $pair.Value -ErrorAction SilentlyContinue) {
        Set-Alias -Name $pair.Key -Value $pair.Value -Force
    }
}

# ── Git shortcuts ────────────────────────────────────────────────────
function gs  { git status @args }
function gc  { git commit -m @args }
function gp  { git push @args }
function gco { git checkout @args }
function gl  { git log --graph --oneline --decorate @args }
function gd  { git diff @args }

# ── Misc ─────────────────────────────────────────────────────────────
function reload { . $PROFILE ; Write-Host 'PowerShell profile reloaded!' }
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    function fetch { fastfetch }
}
