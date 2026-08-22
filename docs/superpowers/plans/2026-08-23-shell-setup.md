# Shell Setup Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all bugs in existing dotfile configs, unify prompt via Starship across zsh + PowerShell, add PowerShell profile, deploy scripts, and README.

**Architecture:** Repo stays single source of truth on Windows (`C:\Users\li_sz\zshconfig`). `deploy.sh` runs inside WSL (copies `.zshrc`, links starship.toml). `deploy.ps1` runs on Windows (copies wezterm/starship/pwsh-profile into live locations — copies not symlinks because Windows symlinks need admin/Developer Mode). Both idempotent, both back up targets to `.bak`.

**Tech Stack:** zsh + zinit (turbo), Starship, PowerShell 7 + PSReadLine, WezTerm, WSL2 (Arch primary, Ubuntu-22.04 secondary), mise, Homebrew-on-Linux.

## Global Constraints

- WSL username: `li_sz`
- Cyberpunk palette anchors: green `#00ff9f`, purple `#bd00ff`, cyan `#00b8ff`, magenta `#d600ff`, red-pink `#ff008d`, amber `#ffd580`
- No startup eye-candy on shell load path; flair behind `fetch` alias only
- Every external tool invocation in rc/profile guarded (`command -v` / `Get-Command`) so missing binaries never break startup
- p10k removed everywhere; Starship is the only prompt
- Deploy scripts idempotent; never overwrite without `.bak` backup
- No comments explaining removed features linger in rewritten files

---

### Task 1: Rewrite `.zshrc`

**Files:**
- Modify: `.zshrc` (full rewrite)

**Interfaces:**
- Consumes: zinit repo clone (self-bootstraps), `~/.p10k.zsh` NOT consumed anymore
- Produces: aliases (`ls cat grep find top vim c reload matrix fetch`, git: `gs gc gp gco gl gd`), guarded inits for zoxide/starship/mise/fzf, `timezsh` function used by verification

- [ ] **Step 1: Write new `.zshrc`**

Replace entire file content with:

```zsh
# ~/.zshrc — managed by zshconfig repo. Re-deploy after editing: ./deploy.sh

# ── Zinit ────────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# ── Plugins (turbo mode) ─────────────────────────────────────────────
# zsh-syntax-highlighting LAST: wraps widgets defined by earlier plugins
zinit ice depth=1 wait'0' lucid; zinit light zsh-users/zsh-autosuggestions
zinit ice depth=1 wait'0' lucid; zinit light zsh-users/zsh-history-substring-search
zinit ice depth=1 wait'1' lucid; zinit light Aloxaf/fzf-tab
zinit ice depth=1 wait'1' lucid; zinit light MichaelAquilina/zsh-you-should-use
zinit ice depth=1 wait'2' lucid; zinit light zsh-users/zsh-syntax-highlighting

# ── History ──────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt appendhistory sharehistory inc_append_history extended_history \
       hist_ignore_space hist_ignore_dups hist_find_no_dups hist_save_no_dups \
       hist_verify hist_expire_dups_first

# ── Directories ──────────────────────────────────────────────────────
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT

# ── Completion ───────────────────────────────────────────────────────
autoload -Uz compinit
local _zdump="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n ${~_zdump}(#qN.mh+24) ]]; then
  compinit          # dump older than 24h: full security-checked rebuild
else
  compinit -C       # fresh dump: fast path
fi

# ── Environment ──────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export MANPAGER='nvim +Man!'
export LS_COLORS="di=1;36:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=1;34:cd=1;34:su=0;41:sg=0;46:tw=0;42:ow=0;43"

# Homebrew (guarded — never writes to other rc files)
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
fi

# ── ssh-agent: reuse one instance across shells ──────────────────────
SSH_ENV="$HOME/.cache/ssh-agent.env"
mkdir -p "$HOME/.cache"
if [[ -r "$SSH_ENV" ]]; then
  source "$SSH_ENV" > /dev/null
fi
if ! ssh-add -l &> /dev/null && [[ $? -eq 2 ]]; then   # 2 = no agent reachable
  ssh-agent -s > "$SSH_ENV"
  source "$SSH_ENV" > /dev/null
fi
export GPG_TTY="$(tty)"

# ── Aliases ──────────────────────────────────────────────────────────
alias ls='eza --long --group-directories-first --icons --color=always'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias top='btop'
alias vim='nvim'
alias c='clear'
alias reload='source ~/.zshrc && echo "ZSH config reloaded!"'
alias matrix='cmatrix -C cyan --bold'
alias fetch='fastfetch | lolcat'

# Git
alias gs='git status'
alias gc='git commit -m'
alias gp='git push'
alias gco='git checkout'
alias gl='git log --graph --oneline --decorate'
alias gd='git diff'

# ── Keybindings ──────────────────────────────────────────────────────
bindkey -e
autoload -Uz history-substring-search-up history-substring-search-down
zle -N history-substring-search-up
zle -N history-substring-search-down
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ── Tool integrations (each guarded) ─────────────────────────────────
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
command -v zoxide  > /dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship > /dev/null 2>&1 && eval "$(starship init zsh)"
command -v mise    > /dev/null 2>&1 && eval "$(mise activate zsh)"

# ── Functions ────────────────────────────────────────────────────────
function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

function cyber_matrix() {
  clear && cmatrix -C cyan --bold | lolcat
}

function cyber_ascii() {
  jp2a --colors "$1" | lolcat
}
```

Removed vs old file: p10k instant-prompt block, p10k source line, `zmodload zsh/zprof`, `FUNCNEST`, no-op `cd()` wrapper, WezTerm opacity env, iTerm block, startup `colorscript/neofetch/lolcat` block, `/root/.bashrc` append lines, unguarded `eval "$(ssh-agent -s)"`.

- [ ] **Step 2: Syntax-check inside WSL**

Run: `wsl -d Arch -- zsh -n /mnt/c/Users/li_sz/zshconfig/.zshrc`
Expected: exit 0, no output. If Arch distro name differs, check `wsl -l`.

- [ ] **Step 3: Commit**

```powershell
git add .zshrc
git commit -m "fix(zshrc): brew append loop, ssh-agent leak, compinit cache; swap exa->eza, neofetch->fastfetch; starship prompt"
```

---

### Task 2: Create `starship.toml`

**Files:**
- Create: `starship.toml`

**Interfaces:**
- Produces: shared prompt config consumed by zsh (Task 1) and PowerShell (Task 5); deployed by Task 6 + Task 7 to `~/.config/starship/starship.toml` / `%USERPROFILE%\.config\starship\starship.toml`

- [ ] **Step 1: Write `starship.toml`**

```toml
# Cyberpunk palette — matches .wezterm.lua Custom Cyberpunk scheme
add_newline = false

format = "$directory$git_branch$git_status$nodejs$python$rust$docker_context$cmd_duration$line_break$character"

[directory]
style = "bold #00b8ff"
truncation_length = 3

[character]
success_symbol = "[❯](bold #00ff9f)"
error_symbol = "[❯](bold #ff008d)"

[cmd_duration]
min_time = 2000
style = "bold #ffd580"

[git_branch]
symbol = " "
style = "bold #bd00ff"

[git_status]
style = "bold #bd00ff"

[nodejs]
symbol = " "
style = "bold #00ff9f"

[python]
symbol = " "
style = "bold #ffd580"

[rust]
symbol = " "
style = "bold #d600ff"

[docker_context]
symbol = " "
style = "bold #00b8ff"
```

- [ ] **Step 2: Validate TOML parses**

Run (from repo root):
`python -c "import tomllib; tomllib.load(open('starship.toml','rb')); print('OK')"`
Expected: `OK` (Python 3.11+; any TOML validator acceptable)

- [ ] **Step 3: Commit**

```powershell
git add starship.toml
git commit -m "feat: shared cyberpunk starship prompt config"
```

---

### Task 3: Fix `.wezterm.lua`

**Files:**
- Modify: `.wezterm.lua` (full rewrite)

**Interfaces:**
- Produces: deployed by Task 7 to `%USERPROFILE%\.config\wezterm\wezterm.lua`; spawns `wsl.exe --distribution Arch` by default

- [ ] **Step 1: Write fixed `.wezterm.lua`**

Changes vs old: foreign `/Users/vlad/...` background layers deleted; `CTRL+C` restored to SIGINT (copy/paste move to CTRL+SHIFT); `macos_window_background_blur` dropped; `default_prog` uses `wsl.exe`.

```lua
local wezterm = require 'wezterm'

local wsl_domains = wezterm.default_wsl_domains()

wezterm.on("gui-startup", function(cmd)
  wezterm.mux.spawn_window(cmd or {})
end)

for _, domain in ipairs(wsl_domains) do
  domain.default_cwd = "~"
end

return {
  default_prog = { 'wsl.exe', '--distribution', 'Arch' },
  font = wezterm.font {
    family = 'FiraCode Nerd Font Mono',
    weight = 'Light',
    stretch = 'Normal',
    style = 'Normal',
    harfbuzz_features = { 'cv29', 'cv30', 'ss01', 'ss03', 'ss06', 'ss07', 'ss09' },
  },
  font_size = 12,
  color_schemes = {
    ['Custom Cyberpunk'] = {
      foreground = '#00ff9f',
      background = '#000000',
      cursor_bg = '#00ff9f',
      cursor_border = '#00ff9f',
      cursor_fg = '#000000',
      selection_bg = '#00b8ff',
      selection_fg = '#000000',
      ansi = {'#000000', '#bd00ff', '#00ff9f', '#d600ff', '#00b8ff', '#001eff', '#00ff9f', '#ffffff'},
      brights = {'#000000', '#bd00ff', '#00ff9f', '#d600ff', '#00b8ff', '#001eff', '#00ff9f', '#ffffff'},
    },
  },
  color_scheme = 'Custom Cyberpunk',
  adjust_window_size_when_changing_font_size = false,
  audible_bell = 'Disabled',
  disable_default_key_bindings = true,
  exit_behavior = 'Close',
  force_reverse_video_cursor = true,
  hide_mouse_cursor_when_typing = true,
  hide_tab_bar_if_only_one_tab = true,
  keys = {
    { action = wezterm.action.ActivateCommandPalette, mods = 'CTRL|SHIFT', key = 'P' },
    { action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection', mods = 'CTRL|SHIFT', key = 'C' },
    { action = wezterm.action.PasteFrom 'Clipboard', mods = 'CTRL|SHIFT', key = 'V' },
    { action = wezterm.action.DecreaseFontSize, mods = 'CTRL', key = '-' },
    { action = wezterm.action.IncreaseFontSize, mods = 'CTRL', key = '=' },
    { action = wezterm.action.ResetFontSize, mods = 'CTRL', key = '0' },
    { action = wezterm.action.ToggleFullScreen, key = 'F11' },
    { action = wezterm.action.Nop, mods = 'ALT', key = 'Enter' },
    { action = wezterm.action_callback(function(window, pane)
        window:perform_action(wezterm.action.SpawnCommandInNewTab {
          args = {'wsl.exe', '--distribution', 'Ubuntu-22.04'}
        }, pane)
      end), mods = 'CTRL|SHIFT', key = 'U' },
    { action = wezterm.action_callback(function(window, pane)
        window:perform_action(wezterm.action.SpawnCommandInNewTab {
          args = {'wsl.exe', '--distribution', 'Arch'}
        }, pane)
      end), mods = 'CTRL|SHIFT', key = 'A' },
  },
  scrollback_lines = 10000,
  show_update_window = true,
  use_dead_keys = false,
  unicode_version = 15,
  window_close_confirmation = 'NeverPrompt',
  window_padding = {
    left = 0,
    right = 0,
    top = '0.6cell',
    bottom = 0,
  },
  wsl_domains = wsl_domains,
}
```

- [ ] **Step 2: Config-load check**

Run: `wezterm show-keys --config-file C:\Users\li_sz\zshconfig\.wezterm.lua`
Expected: prints key table, no Lua error. (`Ctrl+C` absent from copy binding confirms SIGINT preserved.)

- [ ] **Step 3: Commit**

```powershell
git add .wezterm.lua
git commit -m "fix(wezterm): drop broken Mac background paths, restore Ctrl+C SIGINT, copy/paste on Ctrl+Shift"
```

---

### Task 4: Fix `wsl.conf`

**Files:**
- Modify: `wsl.conf`

**Interfaces:**
- Consumes: nothing
- Produces: reference config; deploy.sh (Task 6) diffs against `/etc/wsl.conf` and instructs manual `sudo cp`

- [ ] **Step 1: Replace username placeholder**

Change line under `[user]` from `default = yourusername` to:

```ini
[user]
default = li_sz
```

Rest of file unchanged (automount metadata, interop `appendWindowsPath = false`, systemd).

- [ ] **Step 2: Commit**

```powershell
git add wsl.conf
git commit -m "fix(wsl.conf): set real default user li_sz"
```

---

### Task 5: Create PowerShell profile

**Files:**
- Create: `pwsh/Microsoft.PowerShell_profile.ps1`

**Interfaces:**
- Consumes: `starship.toml` from Task 2 (via starship auto-discovery of `~/.config/starship/starship.toml`)
- Produces: aliases/functions `ls cat grep find top vim gs gc gp gco gl gd reload fetch` mirroring zsh; deployed by Task 7 to `$PROFILE`

- [ ] **Step 1: Write profile**

```powershell
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
```

- [ ] **Step 2: Parse-check**

Run (from repo root):

```powershell
$errs = $null
[System.Management.Automation.Language.Parser]::ParseFile(
  (Resolve-Path 'pwsh/Microsoft.PowerShell_profile.ps1'),
  [ref]$null, [ref]$errs) | Out-Null
$errs.Count
```

Expected: `0`

- [ ] **Step 3: Commit**

```powershell
git add pwsh/Microsoft.PowerShell_profile.ps1
git commit -m "feat(pwsh): profile with PSReadLine predictions, starship, zsh-mirrored aliases"
```

---

### Task 6: Create `deploy.sh` (WSL side)

**Files:**
- Create: `deploy.sh`

**Interfaces:**
- Consumes: repo files `.zshrc`, `starship.toml`, `wsl.conf`
- Produces: `$HOME/.zshrc` (copy), `$HOME/.config/starship/starship.toml` (symlink), dependency report

- [ ] **Step 1: Write `deploy.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

backup_copy() {   # backup_copy SRC DST — copy, backing up existing DST
  local src=$1 dst=$2
  if [[ -e "$dst" ]]; then
    cp "$dst" "$dst.bak"
    echo "backed up: $dst -> $dst.bak"
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "installed: $dst"
}

backup_link() {   # backup_link SRC DST — symlink, backing up real file
  local src=$1 dst=$2
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    mv "$dst" "$dst.bak"
    echo "backed up: $dst -> $dst.bak"
  fi
  rm -f "$dst"
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "linked:    $dst -> $src"
}

backup_copy "$REPO_DIR/.zshrc" "$HOME/.zshrc"
backup_link "$REPO_DIR/starship.toml" "$HOME/.config/starship/starship.toml"

# wsl.conf lives at /etc — needs root, so advise instead of touching
if ! diff -q /etc/wsl.conf "$REPO_DIR/wsl.conf" > /dev/null 2>&1; then
  echo ""
  echo "NOTE: repo wsl.conf differs from /etc/wsl.conf."
  echo "Review, then apply:"
  echo "  sudo cp $REPO_DIR/wsl.conf /etc/wsl.conf"
  echo "  (then from Windows: wsl --shutdown)"
fi

# Dependency report
echo ""
echo "dependency check:"
missing=()
for cmd in eza bat rg fd btop nvim zoxide fzf starship mise fastfetch lolcat cmatrix git; do
  command -v "$cmd" > /dev/null 2>&1 || missing+=("$cmd")
done
if (( ${#missing[@]} )); then
  echo "  MISSING: ${missing[*]}"
  echo "  install: sudo pacman -S --needed ${missing[*]}"
else
  echo "  all present"
fi

echo ""
echo "done. restart your shell."
```

Note: `.zshrc` is copied (not linked) because sourcing from `/mnt/c` (9P filesystem) slows every shell start. Re-run script after editing.

- [ ] **Step 2: Make executable + syntax check**

Run: `wsl -d Arch -- bash -n /mnt/c/Users/li_sz/zshconfig/deploy.sh && wsl -d Arch -- chmod +x /mnt/c/Users/li_sz/zshconfig/deploy.sh`
Expected: exit 0

- [ ] **Step 3: Commit**

```powershell
git add deploy.sh
git commit -m "feat(deploy): WSL-side installer with backups and dependency report"
```

---

### Task 7: Create `deploy.ps1` (Windows side)

**Files:**
- Create: `deploy.ps1`

**Interfaces:**
- Consumes: repo files `.wezterm.lua`, `starship.toml`, `pwsh/Microsoft.PowerShell_profile.ps1`
- Produces: `%USERPROFILE%\.config\wezterm\wezterm.lua`, `%USERPROFILE%\.config\starship\starship.toml`, `$PROFILE` (all copies with `.bak` backup)

- [ ] **Step 1: Write `deploy.ps1`**

Copies (not symlinks): Windows symlinks require admin or Developer Mode; copies are robust. Re-run after editing.

```powershell
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
```

- [ ] **Step 2: Parse-check**

Run (from repo root):

```powershell
$errs = $null
[System.Management.Automation.Language.Parser]::ParseFile(
  (Resolve-Path 'deploy.ps1'), [ref]$null, [ref]$errs) | Out-Null
$errs.Count
```

Expected: `0`

- [ ] **Step 3: Commit**

```powershell
git add deploy.ps1
git commit -m "feat(deploy): Windows-side installer for wezterm, starship, pwsh profile"
```

---

### Task 8: Create `README.md` + final verification

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: everything above
- Produces: setup docs; final verification evidence

- [ ] **Step 1: Write `README.md`**

````markdown
# zshconfig

Dotfiles + deploy scripts for Windows (PowerShell 7 + WezTerm) and WSL2 Arch (zsh).
Single source of truth lives here; two scripts push configs into place.

## Layout

| File | Purpose |
|---|---|
| `.zshrc` | zsh config (zinit turbo, starship, mise) |
| `starship.toml` | Shared cyberpunk prompt — both shells |
| `.wezterm.lua` | Terminal config (Arch WSL default) |
| `wsl.conf` | Reference WSL2 config (systemd, metadata mounts) |
| `pwsh/Microsoft.PowerShell_profile.ps1` | PowerShell profile |
| `deploy.sh` | Run INSIDE WSL — installs zsh config |
| `deploy.ps1` | Run on WINDOWS — installs wezterm/starship/pwsh profile |

## Prerequisites — WSL Arch

```bash
sudo pacman -S --needed eza bat ripgrep fd btop neovim zoxide fzf starship mise fastfetch lolcat cmatrix git
```

Homebrew (optional): https://docs.brew.sh/Homebrew-on-Linux

## Prerequisites — Windows (PowerShell 7)

```powershell
winget install --id wez.wezterm
winget install --id Starship.Starship
winget install --id ajeetdsouza.zoxide
winget install --id junegunn.fzf
winget install --id eza-community.eza
winget install --id sharkdp.bat
winget install --id BurntSushi.ripgrep.MSVC
winget install --id sharkdp.fd
winget install --id Microsoft.PowerShell   # pwsh 7
```

Toolchains (both sides): `mise` manages node/python/rust — `mise use -g node@lts python@3.12 rust@stable`.

## Setup

Inside WSL (Arch):
```bash
/mnt/c/Users/li_sz/zshconfig/deploy.sh
```

On Windows (pwsh):
```powershell
cd C:\Users\li_sz\zshconfig
./deploy.ps1
```

Both scripts back up any existing file to `<name>.bak` first. Safe to re-run.

## After editing configs

Edit files in THIS repo, then re-run the matching deploy script.
(`.zshrc` is copied into WSL home — linking from /mnt/c would slow every shell start.)

## Key bindings (WezTerm)

| Keys | Action |
|---|---|
| `CTRL+SHIFT+C` / `CTRL+SHIFT+V` | Copy / Paste |
| `CTRL+C` | SIGINT (interrupt) — normal terminal behavior |
| `CTRL+-` / `CTRL+=` / `CTRL+0` | Font size down/up/reset |
| `F11` | Fullscreen |
| `CTRL+SHIFT+P` | Command palette |
| `CTRL+SHIFT+A` / `CTRL+SHIFT+U` | New tab: Arch / Ubuntu |

## Known trade-offs

- `appendWindowsPath=false`: Windows executables aren't on PATH inside WSL (big
  startup win). Call them by full path (`/mnt/c/...`) or re-enable if needed.
- `CTRL+C/V` are interrupt/paste-safe again — clipboard ops moved to SHIFT variants.
- Old p10k theme replaced by starship; delete `~/.p10k.zsh` if you want.
````

- [ ] **Step 2: Full verification sweep (run after deploys)**

In WSL:
```bash
timezsh          # expect ~<150ms per iteration after first
gs               # git status renders through starship prompt
echo 'ls -la' | zsh -ic 'ls'   # eza output, icons
```
On Windows (new pwsh window):
```powershell
gs               # works
reload           # profile reloads clean, no errors
```
In WezTerm: open build that hangs → `CTRL+C` kills it; `CTRL+SHIFT+C` copies selection.

- [ ] **Step 3: Commit**

```powershell
git add README.md
git commit -m "docs: setup guide, prerequisites, deploy workflow, trade-offs"
```

---

## Self-Review Notes

- Spec coverage: every row of spec's problem table maps to Task 1 (zshrc rows), Task 3 (wezterm rows), Task 4 (wsl.conf). Sections: starship→T2, pwsh profile→T5, deploy→T6/T7, README/tradeoffs→T8.
- Deviation from spec documented: Windows-side deploy uses copies not symlinks (privilege requirement); rationale in plan header + README. WSL-side keeps symlink for starship.toml.
- Type/name consistency: `backup_link`/`backup_copy` used consistently within deploy.sh; `Backup-Copy` consistent within deploy.ps1; alias sets match between .zshrc and pwsh profile (ls/cat/grep/find/top/vim/gs/gc/gp/gco/gl/gd/reload).
