# zshconfig

Dotfiles + deploy scripts for Windows (PowerShell 7 + WezTerm) and WSL2 Ubuntu (zsh).
Single source of truth lives here; two scripts push configs into place.

## Layout

| File | Purpose |
|---|---|
| `docs/user-guide.md` | Hands-on guide: zsc, tmux keys, workmux, daily workflows |
| `.zshrc` | zsh config (zinit turbo, starship, mise) |
| `starship.toml` | Shared cyberpunk prompt — both shells |
| `.wezterm.lua` | Terminal config (Ubuntu WSL default, spare Arch tab) |
| `wsl.conf` | Reference WSL2 config (systemd, metadata mounts) |
| `pwsh/Microsoft.PowerShell_profile.ps1` | PowerShell profile |
| `tmux/tmux.conf` | tmux config (prefix `C-a`, catppuccin, sessionx, floax, resurrect) |
| `tmux/tmux.reset.conf` | tmux keybinding set, sourced by tmux.conf |
| `nvim/` | Neovim config (LazyVim) — deployed to Windows AND WSL |
| `lazygit/config.yml` | lazygit theme matching the cyberpunk palette |
| `install.sh` | Run INSIDE WSL — one-time bootstrap (apt, starship, mise, lazygit, TPM, workmux) |
| `apt-packages.txt` / `winget-packages.txt` | Package manifests — installs are hash-guarded, skip when unchanged |
| `skills-packages.txt` | Curated agent-skills manifest — repos installed by `zsc skills` into `~/.agents/skills` |
| `skills/chef-knife-roll/` | Shared cross-agent routing, domain workflows, and scope validator |
| `knife-roll/` | Dry-runnable CLI profiles, scoped recon wrapper, scope example |
| `docs/knife-roll.md` | Apply guide, operating model, profiles, hardening roadmap |
| `git/config` | Shared git config (delta pager, aliases, ghq root) → `~/.config/git/config` |
| `mise/config.toml` | Global tool versions (node/python/rust/go/ghq) — installed by mise on first shell start |
| `.github/workflows/gitleaks.yml` | CI: secrets scanning on every push/PR |
| `pentest.sh` | Run INSIDE WSL — bug-hunt toolkit (pdtm suite, massdns, Caido, wordlists) |
| `deploy.sh` | Run INSIDE WSL — pushes configs into place |
| `install.ps1` | Run on WINDOWS — one-time winget bootstrap |
| `deploy.ps1` | Run on WINDOWS — pushes configs into place |
| `bin/zsc.ps1` | `zsc` CLI, Windows side (setup/install/deploy/wsl/update/doctor) |
| `bin/zsc` | `zsc` CLI, WSL side (setup/install/deploy/update/doctor) |
| `.gitattributes` | Forces LF for shell/zsh/lua files (prevents CRLF breakage) |

## Fresh-machine bootstrap

Stock Windows 10/11 has winget and PowerShell 5.1 — nothing else needed:

```powershell
winget install --id Git.Git            # git to clone this repo
powershell -ExecutionPolicy Bypass -File .\install.ps1   # 5.1-safe: installs pwsh 7 + all tools
cd C:\Users\<you>\zshconfig
./deploy.ps1                            # now on pwsh 7
```

Fresh WSL (from elevated PowerShell): `wsl --install -d Ubuntu`, finish the
first-run user setup, then inside Ubuntu:

```bash
sudo apt install -y git
git clone https://github.com/karleeov/zshconfig /mnt/c/Users/<you>/zshconfig  # or clone on Windows first
/mnt/c/Users/<you>/zshconfig/install.sh
/mnt/c/Users/<you>/zshconfig/deploy.sh
```

## The zsc CLI

Daily-use reference: [docs/user-guide.md](docs/user-guide.md).

After a first `deploy`, both sides get a `zsc` command (Windows via
`%USERPROFILE%\bin\zsc.cmd`, WSL via `~/.local/bin/zsc`):

```
zsc setup     full bootstrap (tools + configs; Windows zsc also drives WSL)
zsc install   packages only
zsc deploy    configs only
zsc wsl       from Windows: run install+deploy inside the default distro
zsc pentest   bug-hunt toolkit in WSL: pdtm + recon suite, massdns, Caido, resolvers/wordlists (docs/pentest.md)
zsc knife     opt-in CLI profiles; preview with: zsc knife --dry-run all
zsc skills    agent skills: install / check / update / doctor (skills-packages.txt)
zsc update    git pull + redeploy + skills update check (no auto-update)
zsc doctor    health check: tools, WSL state, config drift — run this first
```

`zsc doctor` is the entry point when anything feels off. It checks the tool
set, detects the broken-WSL case and prints the exact elevated fix.

## Chef's knife roll

The curated professional layer keeps the existing base but reduces overlapping
skills, adds domain playbooks and CLI profiles, and makes recon passive by
default. Cursor and Kimi Code discover `~/.agents/skills` natively, alongside pi
and OpenCode. Read [docs/knife-roll.md](docs/knife-roll.md) for the apply path,
harness roles, profiles, business-service checklist, and remaining hardening
work.

```bash
zsc knife --dry-run development databases security
zsc knife development databases security
zsc skills check    # read-only; run zsc skills update manually after review
```

## Setup — WSL Ubuntu

```bash
/mnt/c/Users/li_sz/zshconfig/install.sh   # one-time: packages, starship, mise, TPM, workmux
/mnt/c/Users/li_sz/zshconfig/deploy.sh    # configs (re-run after every repo edit)
```

`install.sh` is idempotent. It also handles the Ubuntu renames (`batcat`→`bat`,
`fdfind`→`fd`), offers `chsh` to zsh, installs lazygit (latest GitHub release)
and [workmux](https://workmux.dev) (git worktrees + tmux windows for parallel
dev/agents).

## Setup — Windows (PowerShell 7)

```powershell
cd C:\Users\li_sz\zshconfig
./install.ps1    # one-time: winget tool set
./deploy.ps1    # configs (re-run after every repo edit)
```

Toolchains (both sides): mise manages node/python/rust/go/ghq — versions pinned in
`mise/config.toml` (deployed by both deploy scripts; `go` also feeds the pentest
stack, `ghq` clones repos into `~/src`). Git identity stays in `~/.gitconfig`;
the repo ships only the shared XDG config (`git/config`) — so `git hist`, `git ps`/`git pl`,
`git open` (gh browse) and conflict helpers `git edit-unmerged`/`git add-unmerged` work everywhere.
Patterns adopted from [craftzdog/dotfiles](https://github.com/craftzdog/dotfiles):
package manifests with hash-guarded installs, delta git config, mise pinning, gitleaks CI.

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

## Pentest toolkit (WSL)

```bash
zsc pentest            # from Windows or WSL: pdtm + recon suite, massdns, Caido, lists
recon example.com      # passive discovery only
recon example.com --active --scope ~/scopes/example.txt  # authorized targets only
```

Covers the [Bug Hunter's Methodology](docs/pentest.md) stack: subfinder →
shuffledns/massdns → alterx → dnsx → httpx → naabu → katana → urlfinder →
nuclei, plus [Caido](https://caido.io) as the proxy and Assetnote/Trickest
lists under `~/tools`.

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
