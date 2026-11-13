# Agent Skills

Vendored [Agent Skills](https://agentskills.io) (SKILL.md format) — deployed by
`deploy.sh` / `deploy.ps1` into the canonical shared store:

- `~/.agents/skills` / `%USERPROFILE%\.agents\skills` — read natively by pi,
  Kimi CLI and OpenCode; Claude Code + GitHub Copilot CLI reach it through the
  `~/.claude/skills` junction (Windows) / symlink (WSL) that `zsc skills
  install` creates (run it once on a new machine).

One vendored copy serves every harness: the format is the same
[SKILL.md](https://agentskills.io/specification) spec. Backups on redeploy go
to a `skills.bak\` directory *next to* the store (not inside it) so stale
copies never get indexed as duplicate skills.

The same store also holds the bigger packs installed by `zsc skills install`
from `skills-packages.txt` — that manifest deliberately leaves out every source
vendored here, so the two supply paths (pinned `skills/` copies vs CLI-managed
repos) never overwrite each other's copies of the same skill.

This is a **curated subset**, picked for this repo's work (shell configs,
code review, bug-hunt/recon, diagrams). The full catalogs live upstream:

| Vendored skills | Source (commit) | License |
|---|---|---|
| `code-review-and-quality`, `debugging-and-error-recovery`, `git-workflow-and-versioning`, `planning-and-task-breakdown`, `security-and-hardening`, `test-driven-development`, `performance-optimization`, `spec-driven-development` | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) @ `301b02b` | MIT |
| `security-audit` | [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) @ `c1c8a8c` | MIT |
| `api-security`, `attack-chain`, `code-audit`, `js-reverse`, `browser-automation`, `radare2` | [zhaoxuya520/reverse-skill](https://github.com/zhaoxuya520/reverse-skill) @ `cab634b` | MIT |
| `diagram-design` | [cathrynlavery/diagram-design](https://github.com/cathrynlavery/diagram-design) @ `f2496ac` | MIT |
| `brave-search`, `browser-tools`, `youtube-transcript`, `vscode`, `transcribe` | [badlogic/pi-skills](https://github.com/badlogic/pi-skills) @ `90bb51c` | MIT |
| `pdf`, `docx`, `xlsx`, `pptx` | [anthropics/skills](https://github.com/anthropics/skills) @ `2c5958e` | bundled `LICENSE.txt` per skill |

Vendored 2026-11-11 / 2026-11-12.

## Why these

- **debugging-and-error-recovery / code-review-and-quality / git-workflow-and-versioning / planning-and-task-breakdown** — everyday coding-agent discipline (root-cause debugging, review gates, git hygiene, plan-first work).
- **security-audit** — Cloudflare's multi-phase audit skill with machine-readable findings; pairs with the pentest track (`zsc pentest`).
- **reverse-skill picks** (`api-security`, `attack-chain`, `code-audit`, `js-reverse`, `browser-automation`, `radare2`) — web/app pentest + RE slices of a much larger router pack; complements the REA MCP.
- **diagram-design** — publication-grade diagrams (60+ types) as self-contained HTML; vendored *complete* because its SKILL.md references its own `assets/` examples.
- **pi-skills picks** (`brave-search`, `browser-tools`, `youtube-transcript`, `vscode`, `transcribe`) — everyday agent helpers from pi's official collection: web search/extract, Chrome DevTools automation, YouTube transcripts, VS Code diffing, Groq transcription. First-use setup (the agent walks through it): `brave-search` / `browser-tools` / `youtube-transcript` need `npm install` inside the skill dir; `browser-tools` also needs Chrome; `transcribe` needs `curl` + a Groq API key (env var only — never stored in this repo); `vscode` needs VS Code with the `code` CLI on PATH.
- **anthropic document skills** (`pdf`, `docx`, `xlsx`, `pptx`) — reading/editing Office + PDF files with bundled OOXML tooling (that's why they're the biggest dirs); each dir carries its own `LICENSE.txt`. Pairs with OfficeCLI from the winget manifest.

## Updating a vendored skill

```bash
ghq get addyosmani/agent-skills          # or the repo you want
cp -r "$(ghq root)"/github.com/addyosmani/agent-skills/skills/<name> skills/
./deploy.sh                              # push into ~/.agents/skills
```

Then update the commit column above. To add a new upstream skill, copy its
directory here and add a row — do not rename vendored directories (upstream
references them by name).

## Installing heavy skills without vendoring: pi packages

pi can install skills straight from git or npm as managed packages — useful
for big or fast-moving skills that don't belong in a dotfiles repo (e.g.
archify is ~17 MB, mostly example galleries):

```bash
pi install git:github.com/tt-a1i/archify            # user-level (all projects)
pi install git:github.com/addyosmani/agent-skills   # whole 25-skill pack
pi list                                             # show configured packages
pi remove <source>                                  # uninstall
pi update --extensions                              # reconcile installed refs
```

Narrow what loads from a package in `~/.pi/agent/settings.json` (paths are
relative to the package root):

```json
{
  "packages": [
    {
      "source": "git:github.com/addyosmani/agent-skills",
      "skills": ["skills/code-review-and-quality", "skills/debugging-and-error-recovery"]
    }
  ]
}
```

Trade-off: package sources live in `~/.pi/agent/settings.json`, outside this
repo, so they don't follow the "repo is the single source of truth" rule.
Prefer vendoring (above) for anything you want reproduced on every machine by
`deploy`; use `pi install` for heavyweight or experimental things.
