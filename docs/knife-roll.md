# Chef's Knife Roll

A curated professional layer over the existing Windows + WSL2 dotfiles. The goal is not to install the entire uploaded catalog; it is to make the right tool available at the right moment with clear ownership, evidence, and risk gates.

## Operating model

| Role | Default harness/tool |
|---|---|
| Visual editing and diff inspection | Cursor |
| Deep implementation, refactoring, debugging | Claude Code |
| Focused terminal automation | Pi + the existing Pi stack |
| Independent review/research/synthesis | Kimi |
| Requirements and decisions | `grill-me` / `grilling` |
| Implementation discipline | `tdd`, `codebase-design`, `diagnosing-bugs` |
| Routing and operational guardrails | `chef-knife-roll` |

Use one task owner and one worktree per writer. Use another agent for independent review or a separate worktree, not concurrent edits to the same checkout.

## What this patch changes

- Replaces 19 broad/overlapping skill-source entries with four curated upstream sources plus the local `chef-knife-roll` skill.
- Adds native Cursor/Kimi discovery through `~/.agents/skills/`; removes the outdated Kimi hazard check.
- Pins the skills CLI to 1.8.1 by default and disables its telemetry in `zsc` commands.
- Makes `zsc update` run an update **check**, not an automatic update. Automatic task creation is disabled; existing tasks can be removed with `zsc skills schedule off`.
- Fixes inline-comment parsing and failure handling in the Windows `winget` installer.
- Adds dry-runnable CLI profiles: development, security, infrastructure, databases, work, and design. Business intentionally has no global package profile.
- Replaces the old active `recon` shell function with a passive-by-default, scope-validated wrapper.
- Installs the configured Go toolchain through `mise` without rewriting its version to `latest` during pentest setup.

This patch does **not** delete previously installed skills or tools. Review and remove old duplicates manually after the new setup is healthy.

## Apply safely

The supplied patch targets repository commit `9595737`.

### 1. Create a branch and apply

From the real `zshconfig` repository:

```bash
git status --short
# Commit or stash your own changes first.
git checkout -b chore/chef-knife-roll
git apply --check /path/to/knife-roll.patch.txt
git apply --stat /path/to/knife-roll.patch.txt
git apply /path/to/knife-roll.patch.txt
git diff --check
```

Review the diff before running any installer. If the check fails, stop; do not force the patch onto a changed base.

### 2. Windows PowerShell

```powershell
./install.ps1
./deploy.ps1
zsc skills schedule off   # harmless if no legacy task exists
zsc skills install
zsc skills doctor
zsc doctor
```

`zsc skills install` installs the curated manifest but does not remove old skills. Use `npx skills list` to review them, then remove unwanted entries by name with the skills CLI. Back up `~/.agents/skills` before a large cleanup.

### 3. WSL Ubuntu

```bash
./deploy.sh
zsc knife --dry-run development databases security
zsc knife development databases security
zsc pentest               # optional: ProjectDiscovery + Caido toolkit
zsc doctor
```

Start smaller if preferred: install `development` first, then add profiles only when a task needs them.

### Rollback

If you have not committed the patch:

```bash
git apply -R /path/to/knife-roll.patch.txt
./deploy.sh                 # restore WSL configs from the previous tree
```

Then run `./deploy.ps1` on Windows. Previously installed packages and third-party skills are not automatically removed. If you committed the branch, switch back to the prior branch and redeploy instead.

## CLI profiles

Every profile uses APT and/or pipx only; no profile executes a remote shell script. pipx packages are installed as isolated user-level applications.

| Profile | Main contents | When to add |
|---|---|---|
| `development` | direnv, make, shellcheck, SQLite, pre-commit, uv | Default developer baseline |
| `security` | DNS utilities, Nmap, whois, Semgrep, Bandit, pip-audit | Authorized testing and defensive review |
| `infrastructure` | Ansible, rsync, jq, ansible-lint, Checkov | IaC/configuration validation |
| `databases` | PostgreSQL/MySQL/Redis/SQLite clients, pgcli, SQLFluff | Database work without installing servers |
| `work` | Pandoc, FFmpeg, ImageMagick, Poppler, Tesseract, MarkItDown, yt-dlp | Documents, OCR, media |
| `design` | FFmpeg, ImageMagick, rsvg-convert, fonts | Local visual/media work |
| `business` | Nothing globally | Deploy selected services per project |
| `all` | All of the above | Preview with `--dry-run`; usually unnecessary |

Commands:

```bash
zsc knife list
zsc knife --dry-run all
zsc knife --yes development databases
```

Project runtimes still belong in `mise`, devcontainers, or the project's existing toolchain. Pin Kubernetes, Helm, Terraform/OpenTofu, cloud CLIs, and database servers per project rather than installing every version globally.

## Scoped recon

Passive public-source discovery only:

```bash
recon example.com
```

Active HTTP/Nuclei work requires written authorization, `--active`, and a scope file:

```bash
cp knife-roll/scope.example.txt ~/scopes/example-program.txt
# Remove the documentation IPs and edit the file to match the engagement exactly.
recon example.com --active --scope ~/scopes/example-program.txt
```

Rules:

- `example.com` allows the exact host.
- `*.example.com` allows subdomains, not the root itself.
- `!status.example.com` excludes a host; exclusions always win.
- IP addresses and CIDR ranges are supported.
- The validator constrains targets; it does not prove authorization.

Read `docs/pentest.md` for the active pipeline and its limits. Scanner output is not a confirmed vulnerability.

## Business and service stack

Do not install every platform from the catalog. Select one tool per operating need:

| Need | Candidate |
|---|---|
| Automation | n8n |
| Knowledge | Outline or the existing wiki |
| Forms | Formbricks |
| Web analytics | Umami |
| BI | Metabase |
| Support | Chatwoot |
| Document sharing | Papermark |
| OCR/documents | Surya/PaddleOCR, MarkItDown, Pandoc, Typst |

Before production use, configure a database and persistent volumes, HTTPS, SSO/MFA where appropriate, least-privilege service accounts, secrets management, backups and a restore drill, monitoring, retention, resource limits, and an upgrade plan. Keep customer-impacting, financial, legal, external-publication, and destructive actions behind human approval.

## Remaining hardening work

The patch reduces risk; it does not make every legacy installer reproducible.

- Existing `install.sh` and `pentest.sh` still contain some upstream downloads and moving versions. Run them as reviewed installation events, not unattended updates.
- Upstream skill repositories are curated but not cryptographically vendored by this patch. The skills CLI is pinned; `zsc skills update` remains a manual operation. Review changed instructions, scripts, and hooks before use.
- Impeccable's manifest entry installs its skill without native hooks. If you want its full native integration, review the current installer/hook behavior and install it deliberately per project.
- Docker Desktop + WSL integration is recommended for container work; the profile does not replace it with an untracked WSL Docker service.
- Consider vendoring critical skill sources and replacing remaining `curl | shell` installers with pinned, checksummed releases in a later hardening pass.

## Maintenance

- Daily: `zsc doctor`; use `workmux` for isolated agent work.
- After setup changes: `zsc skills doctor` and `git diff --check`.
- Monthly or when needed: `zsc skills check`, review upstream changes, then `zsc skills update` manually.
- Keep the global skill store small. Put specialist workflows in the project that needs them.
- Do not add Defender exclusions, license-bypass tools, subscription resets, or unverified account-routing services to the professional base.

Official discovery references: [Cursor Agent Skills](https://cursor.com/docs/skills), [Kimi Code Agent Skills](https://www.kimi.com/code/docs/en/kimi-code-cli/customization/skills.html), [Pi](https://pi.dev/), and the [skills CLI](https://github.com/vercel-labs/skills).
