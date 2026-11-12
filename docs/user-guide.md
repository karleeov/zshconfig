# User Guide — zsc, tmux, workmux

Hands-on guide for daily use. For fresh-machine bootstrap see the
[top-level README](../README.md). Run `zsc doctor` first whenever anything
feels off — it tells you exactly what to run.

## The mental model

This repo is the **single source of truth**. You never edit deployed files
(`~/.zshrc`, `~/.config/tmux/tmux.conf`, `~/.config/nvim/…`) directly:

```
edit file in repo  ->  zsc deploy  ->  reload the app (e.g. prefix + R in tmux)
```

`zsc doctor` detects "drift" — deployed copies that no longer match the repo —
and prints the fix.

## The zsc CLI

`zsc` is a thin router over the repo's scripts, installed onto PATH by the
first `deploy` (`~/.local/bin/zsc` in WSL, `%USERPROFILE%\bin\zsc.cmd` on
Windows).

| Command | What it does | When to use it |
|---|---|---|
| `zsc setup` | `install.sh` + `deploy.sh` (full bootstrap) | Fresh machine / fresh WSL distro |
| `zsc install` | Packages only (apt tools, starship, mise, TPM, workmux) | Missing tools |
| `zsc deploy` | Push configs only (`.zshrc`, tmux, nvim, lazygit) | **After every edit in this repo** |
| `zsc wsl` | From Windows: run install+deploy inside WSL | Setting up WSL from PowerShell |
| `zsc knife` | Opt-in CLI profiles; supports `list`, `--dry-run`, `--yes` | Installing a domain toolset |
| `zsc skills` | Curated skills store: install / check / update / doctor / legacy schedule off | Adding or deliberately refreshing agent skills |
| `zsc update` | `git pull` this repo, re-deploy | Pulling changes from another machine |
| `zsc doctor` | Health check: tools, TPM, tmux.conf, config drift | **Run this first when unsure** |

Windows side (`zsc.ps1`) has the same commands plus `zsc wsl`; the WSL side
(`bin/zsc`) skips it (you're already inside).

### How zsc touches tmux

1. **`zsc install`** installs tmux (if missing) and **TPM** (the tmux plugin
   manager) into `~/.tmux/plugins/tpm`.
2. **`zsc deploy`** copies `tmux/tmux.conf` → `~/.config/tmux/tmux.conf` and
   `tmux/tmux.reset.conf` → `~/.config/tmux/tmux.reset.conf`.
3. **`zsc doctor`** verifies TPM exists and both files are deployed and in
   sync with the repo.

After a fresh deploy, start tmux once and press **`prefix + I`** so TPM
downloads the plugins (sessionx, floax, resurrect, continuum, catppuccin,
fzf-url, yank). Later: `prefix + U` updates them.

## Skills (one curated store, shared across CLIs)

`zsc skills` manages the agent-skills store with the
[vercel-labs skills CLI](https://github.com/vercel-labs/skills) via `npx`
(needs Node >= 22.20). One canonical store, shared by the daily harnesses:

| CLIs | How they see the store |
|---|---|
| pi / Cursor / Kimi Code / OpenCode | natively — `~/.agents/skills` |
| Claude Code / GitHub Copilot CLI | through the `~/.claude/skills` junction (Windows) / symlink (WSL) |

The manifest is `skills-packages.txt` at the repo root: `owner/repo` installs
every skill in that repo, `owner/repo:skill1,skill2` picks specific ones,
`#` lines are comments.

| Command | What it does |
|---|---|
| `zsc skills install` | create the store + `~/.claude/skills` link, install every manifest entry |
| `zsc skills check` | report available updates without changing skills |
| `zsc skills update` | manually update after reviewing upstream changes |
| `zsc skills doctor` | check store, native discovery, Claude link, node version |
| `zsc skills schedule off` | remove a legacy weekly auto-update task (Windows `schtasks`) |

`zsc update` only checks for skill updates; it never applies them automatically. On WSL the store is Windows-side when
`/mnt/c/Users/<you>/.agents/skills` exists — installs run from Windows, WSL
just links `~/.claude/skills` to it.

Cursor and Kimi Code both document `~/.agents/skills` as a native user-level
discovery path. `zsc skills doctor` checks the shared store and the local
`chef-knife-roll` skill rather than applying the old `~/.config/agents/skills`
warning. Kimi-specific skills can also live under its own data root; generic
shared skills remain in the canonical store.

Two quirks worth knowing:

- Removing a manifest line stops future updates but does not uninstall the
  skills. Clean up with `npx skills remove <owner/repo> -g -y`.
- The curated setup does not disable Defender or add exclusions for offensive
  skill packs. Keep those packs out of the daily store; use a separately
  reviewed, authorized lab setup if you genuinely need them. Automatic weekly
  skill updates are also disabled: check, review, then update manually.

## tmux

Prefix is **`Ctrl+a`**: press it, release, then hit the key. The key set lives
in `tmux/tmux.reset.conf`; plugins add more binds in `tmux/tmux.conf`.

### Sessions & windows

| Keys | Action |
|---|---|
| `prefix + o` | **sessionx** — fuzzy session/window switcher, zoxide-powered (jump straight to a project dir's session) |
| `prefix + p` | **floax** — 80% popup scratch window (toggle; follows your cwd) |
| `prefix + Ctrl+a` | last window (flip back and forth) |
| `prefix + Ctrl+c` | new window (starts in `$HOME`) |
| `prefix + Ctrl+d` | detach — sessions survive; **resurrect/continuum restores them after reboot** |
| `prefix + S` | choose session |
| `prefix + w` / `Ctrl+w` | list windows |
| `prefix + r` | rename window |
| `prefix + R` | **reload tmux.conf** (after a `zsc deploy`) |

### Panes

| Keys | Action |
|---|---|
| `prefix + v` | split horizontally, in current dir |
| `prefix + s` | split vertically, in current dir |
| `prefix + h` / `j` / `k` / `l` | focus left / down / up / right |
| `prefix + ,` / `.` | resize left / right (repeatable) |
| `prefix + -` / `=` | resize down / up (repeatable) |
| `prefix + z` | zoom pane (full-screen toggle) |
| `prefix + c` | kill pane |
| `prefix + x` | swap pane down |
| `prefix + H` / `L` | previous / next window |
| `prefix + *` | toggle synchronize-panes (type into all panes at once) |
| `prefix + P` | toggle pane border status |

Note: `tmux.reset.conf` binds a few keys twice (`l`, `R`, `*`) — the later
bind wins; the effective binding is the one listed above.

### Copy mode (vi-style)

Enter copy mode by scrolling (or `prefix + [`), then:

| Key | Action |
|---|---|
| `v` | begin selection |
| `y` | yank (tmux-yank; `set-clipboard on` syncs to system clipboard) |

### Plugin quick reference

| Plugin | What it gives you |
|---|---|
| `sessionx` | `prefix + o` fuzzy session switcher (zoxide mode on) |
| `floax` | `prefix + p` popup scratch window |
| `resurrect` + `continuum` | sessions persist and auto-restore across reboots (incl. nvim sessions) |
| `fzf-url` | `prefix + u` opens URLs from the visible pane via fzf |
| `yank` | sane copy/paste helpers |
| `catppuccin` | the status bar (session left, directory right) |

### Status bar

Top bar: session name on the left, current directory (`#{b:pane_current_path}`)
on the right. Zoomed panes show `()` after the window name.

## workmux (git worktrees × tmux)

`install.sh` installs [workmux](https://workmux.dev) — one worktree per
tmux window, made for parallel dev and coding agents:

```bash
workmux add feature-x    # new worktree + tmux window, ready for an agent
workmux                  # dashboard: monitor, review, open
workmux merge feature-x  # merge branch, delete worktree, close window
```

Pairs naturally with sessionx (`prefix + o`) to hop between worktrees.

## lazygit

Terminal UI for git: stage/unstage, commit, branch, rebase, stash — all in
one screen, no mouse needed.

### Install

| Side | How |
|---|---|
| Windows | `winget install -e --id JesseDuffield.lazygit` (already part of `install.ps1` / `zsc setup`) |
| WSL | `install.sh` / `zsc install` downloads the latest GitHub release into `~/.local/bin` |

`zsc doctor` flags a missing `lazygit`; `zsc deploy` pushes the cyberpunk
theme (`lazygit/config.yml`) to `~/.config/lazygit/` (WSL) and
`%LOCALAPPDATA%\lazygit\` (Windows).

### Everyday use

Run `lazygit` in any repo (Neovim users: `<Space>gg` opens it inside the
editor). The essentials:

| Key | Action |
|---|---|
| `1`–`5` | jump to panel: status / files / branches / commits / stash |
| `space` | stage or unstage the selected file/hunk |
| `a` | stage ALL changes |
| `c` | commit (staged changes) |
| `C` | commit using the previous message |
| `p` / `P` | pull / push |
| `b` | branches panel: `space` checkout, `n` new branch, `d` delete |
| `M` / `r` | merge into current / rebase current onto selected |
| `z` | undo (pop stash of the change you just made) |
| `/` | search |
| `?` | full keybinding menu — the cheat sheet, press it early and often |
| `q` | quit |

Files panel flow: `space` to stage what you want → `c` to commit → `P` to
push. That's 90% of daily lazygit.

## Daily workflows

### Edit tmux config

```bash
# 1. edit tmux/tmux.conf in the repo (this repo, not ~/.config/tmux)
# 2. push it:
zsc deploy
# 3. inside tmux: prefix + R     (reload)
#                    prefix + I  (only if you ADDED a new plugin)
```

### Same for .zshrc / nvim / lazygit

```bash
zsc deploy               # then restart the shell / nvim
```

(PowerShell profile note: there is no reload function — run `. $PROFILE`.)

### Pull changes made on another machine

```bash
zsc update               # git pull --ff-only + deploy
```

### Something is broken

```bash
zsc doctor               # prints MISSING / drift lines with the exact fix
```

Typical outputs and fixes:

| Doctor says | Fix |
|---|---|
| `MISSING <tool>` | `zsc install` |
| `MISSING tpm` | `zsc install` (then `prefix + I` inside tmux) |
| `MISSING ~/.config/tmux/tmux.conf` | `zsc deploy` |
| `drift ~/.zshrc` (or tmux/nvim/lazygit) | `zsc deploy` (edits made outside the repo will be overwritten — port them into the repo first) |

## Troubleshooting

- **Plugins not loading / status bar plain**: was TPM ever installed?
  `zsc doctor`, then `prefix + I` inside tmux.
- **Changed tmux.conf but nothing happened**: reload with `prefix + R`, or
  fully restart: `tmux kill-server` (sessions resurrect afterwards).
- **Session didn't come back after reboot**: continuum restores on the first
  tmux server start — just run `tmux` and give it a second.
- **Windows/WSL-specific issues**: see Troubleshooting in the
  [README](../README.md).
