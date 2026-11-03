# zshconfig

Dotfiles + deploy scripts for Windows (PowerShell 7 + WezTerm) and WSL2 Ubuntu (zsh).
Single source of truth lives here; two scripts push configs into place.

## Layout

| File | Purpose |
|---|---|
| `.zshrc` | zsh config (zinit turbo, starship, mise) |
| `starship.toml` | Shared cyberpunk prompt — both shells |
| `.wezterm.lua` | Terminal config (Ubuntu WSL default, spare Arch tab) |
| `wsl.conf` | Reference WSL2 config (systemd, metadata mounts) |
| `pwsh/Microsoft.PowerShell_profile.ps1` | PowerShell profile |
| `tmux/tmux.conf` | tmux config (prefix `C-a`, catppuccin, sessionx, floax, resurrect) |
| `tmux/tmux.reset.conf` | tmux keybinding set, sourced by tmux.conf |
| `nvim/` | Neovim config (LazyVim) — deployed to Windows AND WSL |
| `lazygit/config.yml` | lazygit theme matching the cyberpunk palette |
| `install.sh` | Run INSIDE WSL — one-time bootstrap (apt, starship, mise, TPM, workmux) |
| `deploy.sh` | Run INSIDE WSL — pushes configs into place |
| `install.ps1` | Run on WINDOWS — one-time winget bootstrap |
| `deploy.ps1` | Run on WINDOWS — pushes configs into place |
| `.gitattributes` | Forces LF for shell/zsh/lua files (prevents CRLF breakage) |

## Setup — WSL Ubuntu

```bash
/mnt/c/Users/li_sz/zshconfig/install.sh   # one-time: packages, starship, mise, TPM, workmux
/mnt/c/Users/li_sz/zshconfig/deploy.sh    # configs (re-run after every repo edit)
```

`install.sh` is idempotent. It also handles the Ubuntu renames (`batcat`→`bat`,
`fdfind`→`fd`), offers `chsh` to zsh, and installs [workmux](https://workmux.dev)
(git worktrees + tmux windows for parallel dev/agents).

## Setup — Windows (PowerShell 7)

```powershell
cd C:\Users\li_sz\zshconfig
./install.ps1    # one-time: winget tool set
./deploy.ps1    # configs (re-run after every repo edit)
```

Toolchains (both sides): `mise` manages node/python/rust — `mise use -g node@lts python@3.12 rust@stable`.

## tmux (WSL)

Prefix is `CTRL+a`. First start: press `prefix + I` once so TPM installs plugins.

| Keys | Action |
|---|---|
| `prefix + o` | sessionx — fuzzy session/window switcher (zoxide-powered) |
| `prefix + p` | floax — popup scratch window |
| `prefix + d` | detach; sessions resurrect after reboot (continuum) |
| `prefix + I` / `U` | install / update TPM plugins |

workmux (installed by `install.sh`) pairs git worktrees with tmux windows:

```bash
workmux add feature-x   # new worktree + tmux window, ready for an agent
workmux                 # dashboard: monitor, review, open
workmux merge feature-x # merge branch, delete worktree, close window
```

## Neovim (LazyVim)

Same config deployed to `%LOCALAPPDATA%\nvim` (Windows) and `~/.config/nvim` (WSL).
First launch installs plugins. `<Space>` opens the which-key menu, `<Space>gg`
opens lazygit. Config source of truth is this repo; pin changes by copying
`lazy-lock.json` from the deployed location back into `nvim/`.

## After editing configs

Edit files in THIS repo, then re-run the matching deploy script.
(.zshrc is copied into WSL home — linking from /mnt/c would slow every shell start.)
PowerShell note: there is no `reload` function — run `. $PROFILE` to reload.

## Key bindings (WezTerm)

| Keys | Action |
|---|---|
| `CTRL+SHIFT+C` / `CTRL+SHIFT+V` | Copy / Paste |
| `CTRL+C` | SIGINT (interrupt) — normal terminal behavior |
| `CTRL+-` / `CTRL+=` / `CTRL+0` | Font size down/up/reset |
| `F11` | Fullscreen |
| `CTRL+SHIFT+P` | Command palette |
| `CTRL+SHIFT+A` / `CTRL+SHIFT+U` | New tab: Arch (spare, future) / Ubuntu |

## Known trade-offs

- `appendWindowsPath=false`: Windows executables aren't on PATH inside WSL (big
  startup win). Call them by full path (`/mnt/c/...`) or re-enable if needed.
- `CTRL+C/V` are interrupt/paste-safe again — clipboard ops moved to SHIFT variants.
- Old p10k theme replaced by starship; delete `~/.p10k.zsh` if you want.
- Deployers overwrite `~/.config/nvim` from the repo copy; local edits there die
  on re-deploy. Edit in the repo (see lazy-lock note above).

## Troubleshooting

- **WSL broken** (`Wsl/CallMsi/Install/REGDB_E_CLASSNOTREG`, "Class not registered"):
  reinstall the WSL package from an **elevated** PowerShell —
  `Add-AppxPackage C:\Users\li_sz\AppData\Local\Temp\wsl.msixbundle`
  (already downloaded), then `wsl --shutdown` and `wsl ~`.
- Ubuntu binary renames (`batcat`/`fdfind`) are fixed by `install.sh`.
