# Shell Setup Redesign — PowerShell + WSL zsh

Date: 2026-08-22
Status: Approved
Scope: Full setup — fix existing configs, add PowerShell profile, deploy scripts, README.

## Goals

- Fast shell startup on both zsh (WSL Arch) and PowerShell (Windows).
- Identical prompt and aliases across both shells.
- Fix known bugs and dead-tool usage.
- Repeatable deploy: one script per side, idempotent, backs up existing files.

## Non-Goals

- Oh My Zsh or other frameworks.
- Nushell/fish support.
- Managing editor (nvim) config in this repo.

## Current Problems (fixed by this design)

| File | Problem | Fix |
|---|---|---|
| .zshrc:144-145 | Appends brew shellenv to `/root/.bashrc` on every startup — unbounded file growth, wrong user | Delete; guarded brew init once |
| .zshrc:30 | `ssh-agent` spawned per shell — agent leak | Reuse agent if socket exists |
| .zshrc:50 | compinit cache glob broken when `ZDOTDIR` unset | Correct dump-path check with fallback |
| .zshrc:67,75,138 | `exa` (dead), `neofetch` (dead) | `eza`, `fastfetch`; flair off startup path |
| .zshrc:61,105-107 | `FUNCNEST=1000000`, no-op `cd()` wrapper | Removed |
| wsl.conf:13 | Placeholder username | `li_sz` |
| .wezterm.lua:42,45 | Background images at `/Users/vlad/...` (foreign Mac paths) | Removed |
| .wezterm.lua:62-63 | `CTRL+C/V` = copy/paste kills SIGINT | Copy/paste → `CTRL+SHIFT+C/V`; `CTRL+C` → SIGINT |

## Target Layout

```
zshconfig/
├── .zshrc                                  rewritten
├── starship.toml                           shared prompt config
├── wsl.conf                                fixed
├── .wezterm.lua                            fixed
├── .theme                                  kept as-is (Windows Terminal scheme)
├── pwsh/Microsoft.PowerShell_profile.ps1   new
├── deploy.ps1                              new (Windows side)
├── deploy.sh                               new (WSL side)
└── README.md                               new
```

## Design

### 1. zsh (.zshrc rewrite)

- p10k removed. Starship prompt (`starship.toml`) for both shells.
- zinit kept, turbo mode: zsh-syntax-highlighting, zsh-autosuggestions,
  history-substring-search, fzf-tab, you-should-use.
- History/directory options unchanged.
- brew shellenv: only `eval` if `brew` exists; never writes to other rc files.
- ssh-agent: start only when `SSH_AUTH_SOCK` missing/unreachable.
- compinit: cache check against `$HOME/.zcompdump` (or `${ZDOTDIR:-$HOME}`), 24h.
- Tools: eza/bat/rg/fd/btop/nvim/zoxide/fzf/mise/fastfetch. Aliases guard nothing —
  README lists required packages; `deploy.sh` reports missing commands.
- Startup visuals removed from load path. `fetch` alias runs fastfetch + lolcat on demand.
- mise activate zsh. zoxide init zsh (default `z` cmd, keep plain `cd` untouched).

### 2. starship.toml

- Cyberpunk palette matching WezTerm scheme (#00ff9f green on black, #bd00ff purple,
  #00b8ff cyan). Directory, git branch/status, node/python/rust/docker modules,
  command duration >2s, 1-line right-padded layout.

### 3. PowerShell profile

- PSReadLine: PredictionSource History, ListView windowed, emacs-style default,
  ANSI colors matching cyberpunk palette.
- Starship + zoxide + mise init (each guarded by command existence).
- Aliases mirroring zsh: ls→eza, cat→bat, grep→rg, find→fd, top→btop;
  git functions gs/gc/gp/gco/gl/gd. All guarded via `Get-Command`.
- `reload` function re-dots profile.

### 4. wezterm

- Remove foreign background entries. Keep font (FiraCode Nerd Font Mono),
  Custom Cyberpunk scheme, scrollback, padding.
- Keys: `CTRL+SHIFT+C` copy, `CTRL+SHIFT+V` paste, `CTRL+C` SIGINT restored;
  keep font-size keys, F11, command palette, Arch/Ubuntu tab spawns.

### 5. wsl.conf

- `[user] default = li_sz`. Rest unchanged (automount metadata, interop
  appendWindowsPath=false, systemd).

### 6. Deploy scripts

**deploy.ps1** (run on Windows):
- Symlink `$PROFILE` → repo pwsh profile.
- Symlink `~/.config/wezterm/wezterm.lua` → repo `.wezterm.lua`.
- Symlink `~/.config/starship/starship.toml` → repo `starship.toml`.
- Creates parent dirs; backs up existing targets to `<name>.bak` before linking.

**deploy.sh** (run inside WSL):
- Copies `.zshrc` → `$HOME/.zshrc`; symlinks `~/.config/starship/starship.toml`.
- Backs up existing files to `.bak`.
- Dependency check (command -v): eza bat rg fd btop nvim zoxide fzf mise starship
  fastfetch lolcat cmatrix — prints install hints (pacman) for missing ones.

### Error Handling

- All deploy steps idempotent; re-run safe.
- Missing binaries never break shell startup: profile/zshrc tolerate absence
  (aliases to nonexistent tools just error on use — documented in README).

### Testing / Verification

- Fresh WSL shell: starts <150ms (`timezsh`), prompt renders, no errors.
- Fresh PowerShell window: prompt renders, predictions work.
- Alias smoke test both shells: gs, ls, cat behavior.
- `CTRL+C` stops a running process in WezTerm.
- deploy.ps1/deploy.sh run twice without error or duplication.

## Trade-offs Accepted

- p10k dropped → starship (slightly less rich git detail, unified cross-shell config).
- appendWindowsPath=false stays → Windows exes not on PATH inside WSL (perf win).
- Files copied (not symlinked) into WSL home → 9P filesystem symlink would slow
  every shell start; user must re-run deploy.sh after editing .zshrc (README notes this).
