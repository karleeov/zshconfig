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
| `deploy.sh` | Run INSIDE WSL — installs zsh config |
| `deploy.ps1` | Run on WINDOWS — installs wezterm/starship/pwsh profile |
| `.gitattributes` | Forces LF for shell/zsh/lua files (prevents CRLF breakage) |

## Prerequisites — WSL Ubuntu

```bash
sudo apt install -y eza bat ripgrep fd-find btop neovim zoxide fzf starship fastfetch git \
  lolcat cmatrix jp2a   # flair (optional):
# Ubuntu binary names differ: bat->batcat, fd-find->fdfind. Alias them:
mkdir -p ~/.local/bin
[ -n "$(command -v batcat || command -v bat)" ] && ln -sf "$(command -v batcat || command -v bat)" ~/.local/bin/bat
[ -n "$(command -v fdfind || command -v fd)" ] && ln -sf "$(command -v fdfind || command -v fd)" ~/.local/bin/fd
curl https://mise.run | sh   # mise
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

Inside WSL (Ubuntu):
```bash
/mnt/c/Users/li_sz/zshconfig/deploy.sh
```

On Windows (pwsh):
```powershell
cd C:\Users\li_sz\zshconfig
./deploy.ps1
```

Both scripts back up existing files to `<name>.bak` — but only when they differ from the repo copy. Safe to re-run.

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
