# Tooling and setup

## Organize by layer

1. **Base:** Windows + WSL2, zsh, tmux, LazyVim, `mise`, Git, lazygit, delta, workmux.
2. **Shared workflow:** `chef-knife-roll` plus a small curated skill set in `~/.agents/skills/`.
3. **CLI profiles:** install only development, security, infrastructure, database, work, or design tools needed now.
4. **Project tools:** pin language, framework, cloud, and database versions inside each project.
5. **Services:** run business and data platforms per project with containers, secrets, volumes, backups, and resource limits—not as untracked global installs.
6. **MCP:** prefer read-only, least-privilege credentials and project-scoped servers. Treat every MCP server as code plus a data-access boundary.

## Curated default skills

- Matt Pocock: `grill-me`, `grilling`, `tdd`, `codebase-design`, `diagnosing-bugs`, `handoff`.
- Cloudflare: `security-audit`.
- Trail of Bits: `audit-context-building`, `differential-review`, `fp-check`, `codeql`, `semgrep`, `sarif-parsing`, `supply-chain-risk-auditor`, `cvss-scoring`.
- Impeccable: one design system rather than several overlapping aesthetics packs.
- Local: `chef-knife-roll` for routing and operational guardrails.

Keep Addy Osmani's `agent-skills` as an alternative engineering system. Do not enable it alongside overlapping Matt Pocock workflows unless the user deliberately chooses that duplication.

## Optional drawers from the uploaded list

| Drawer | Candidates |
|---|---|
| Documents/work | Anthropic document skills, MarkItDown, Surya/PaddleOCR, Typst, Pandoc, video-use |
| Diagrams | `diagram-design`, `archify`, `anatomy`, ChartDB, tldraw/Drawnix |
| Frontend | HeroUI, Lucide, Anime.js, Three.js, SeleniumBase/Playwright |
| Data/business | Metabase, Umami, Formbricks, Papermark, Chatwoot, n8n, Outline |
| Infrastructure | Trivy, Kopia, NetBird, XPipe, Daytona, kubectl-ai as assistance—not authority |
| Databases | DBX/DBeaver, ChartDB, sqlc, SQLFluff, pgcli, MCP Toolbox for Databases |
| Research | scientific/academic skills only when a research task requires them |
| Security specialization | language-specific Trail of Bits skills, reverse-engineering skills inside an isolated lab |

Do not globally install every model, robotics, gaming, media, trading, or self-hosted business project in the list. Clone per project when needed.

Exclude license-bypass, subscription-reset, unverified free-account routing, and similar utilities from a professional base. Prefer official accounts and traceable API access. Do not disable antivirus scanning to install security text files.

## Update routine

- Daily: `zsc doctor`; use `zsc skills doctor` after changing skills.
- Before installation: `zsc knife --dry-run <profiles>`.
- Monthly or when needed: `zsc skills check`; review changelogs and diffs before `zsc skills update`.
- After updating: inspect changed hooks/scripts, run health checks, and snapshot the resulting lock/state in version control where practical.
- Keep automatic weekly skill updates off. Treat upstream instructions and hooks as supply-chain input.

## Context budget

More skills mean more discovery metadata and more chances of conflicting instructions. Remove duplicates, audit duplicate skill names, and prefer project-local specialist skills over a global collection of everything.
