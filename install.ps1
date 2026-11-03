#Requires -Version 7
# One-time Windows bootstrap: installs the tool set via winget.
# Idempotent: already-installed packages are skipped by winget.
$ErrorActionPreference = 'Stop'

$packages = @(
    'Git.Git'
    'Microsoft.PowerShell'
    'Microsoft.WindowsTerminal'
    'wez.wezterm'
    'Starship.Starship'
    'ajeetdsouza.zoxide'
    'junegunn.fzf'
    'eza-community.eza'
    'sharkdp.bat'
    'BurntSushi.ripgrep.MSVC'
    'sharkdp.fd'
    'Neovim.Neovim'
    'JesseDuffield.lazygit'
    'yorukot.superfile'
    'GitHub.cli'
)

foreach ($pkg in $packages) {
    Write-Host "==> $pkg"
    winget install --id $pkg --accept-package-agreements --accept-source-agreements --disable-interactivity
}

Write-Host ''
Write-Host 'done. run ./deploy.ps1 to push configs.'
