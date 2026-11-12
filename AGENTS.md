# AGENTS.md

Guidance for coding agents working in this repo (Claude Code, OpenCode, pi).
The behavioral core adapts
[multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)
(guidelines distilled from Andrej Karpathy's notes on LLM coding pitfalls);
repo-specific rules follow it.

**Tradeoff:** these rules bias toward caution over speed — use judgment on trivial tasks.

## What this repo is

Dotfiles + deploy scripts for Windows (PowerShell 7 + WezTerm) and WSL2 Ubuntu
(zsh). This repo is the **single source of truth**; `deploy.sh` / `deploy.ps1`
push configs into place. Nothing here is executed at runtime except the deploy
scripts, `pentest.sh` and the `zsc` router.

## Behavioral rules

1. **Think before coding.** State assumptions explicitly; if multiple
   interpretations exist, present them — don't pick silently; if a simpler
   approach exists, say so.
2. **Simplicity first.** Minimum change that solves the problem. No features
   beyond what was asked, no speculative abstractions, no error handling for
   impossible scenarios.
3. **Surgical changes.** Touch only what the task requires; match existing
   style even when you'd do it differently; don't "improve" adjacent code;
   every changed line should trace to the request.
4. **Goal-driven execution.** Turn tasks into verifiable goals
   ("fix the bug" → "reproduce, then make the repro pass"); for multi-step
   work, state the plan with a verify check per step and loop until green.

## Repo-specific rules

- **Edit in THIS repo, then re-run the matching deploy script** (`./deploy.sh`
  in WSL, `./deploy.ps1` on Windows). Never patch deployed copies in place —
  the next deploy overwrites them.
- **Deploy scripts stay idempotent** and back up differing targets before
  overwriting (`*.bak` for files, `skills.bak\` for the skills tree).
- **Shell startup must never break:** guard every external invocation
  (`command -v` in zsh/bash, `Get-Command` in PowerShell) so missing binaries
  degrade gracefully.
- **Line endings:** `.gitattributes` forces LF repo-wide (CRLF breaks zsh/lua).
  Don't override it per-file.
- **Packages go in the manifests** (`apt-packages.txt`, `winget-packages.txt`,
  npm script, or `pentest.sh` for security tooling) — not ad-hoc install
  commands. Manifests are hash-guarded: changing one re-triggers a full
  install pass, which is fine (apt/winget skip what's present).
- **Agent skills** live in `skills/<name>/SKILL.md`, vendored from upstream
  (sources + licenses in `skills/README.md`). Deploy copies them to
  `~/.claude/skills` + `~/.pi/agent/skills` (and the `%USERPROFILE%` mirrors on
  Windows). Don't rename vendored skill directories.
- **Theme palette anchors** (prompt/wezterm/lazygit/tmux): green `#00ff9f`,
  purple `#bd00ff`, cyan `#00b8ff`, magenta `#d600ff`, red-pink `#ff008d`,
  amber `#ffd580`. Keep all theme files on the same palette.
- **Pentest tooling:** `pentest.sh` must stay idempotent, refuse root, and
  only target systems you're authorized to test. Tool API keys (e.g. for
  `strix`) live outside this repo — CI runs gitleaks on every push.
- **`zsc doctor` is the contract:** when you add a tool or deployed config,
  keep its tool list / drift checks in sync (both `bin/zsc` and `bin/zsc.ps1`).
