---
name: chef-knife-roll
description: Route professional development, authorized pentesting, design, business, work, infrastructure, and database tasks through a curated cross-agent toolbelt. Use when choosing between Pi, Claude Code, Kimi, or Cursor; planning or executing technical work; auditing or applying the zshconfig knife-roll; running scoped recon; reviewing production or database risk; or deciding which tools and skills should be installed.
---

# Chef Knife Roll

Use a small set of sharp tools deliberately. Do not install or invoke every available tool by default.

## 1. Set the task contract

Establish the outcome, deliverable, target environment, risk level, and proof required. Ask only for missing information that changes the next action.

Classify the task, then read only the relevant reference:

| Task | Read |
|---|---|
| Feature, bug, refactor, review, test, release | [references/development.md](references/development.md) |
| Authorized recon, web testing, code/cloud security audit | [references/security.md](references/security.md) |
| UI, UX, visual system, diagram, media | [references/design.md](references/design.md) |
| Linux, Docker, Kubernetes, IaC, network, backup, deployment | [references/infrastructure.md](references/infrastructure.md) |
| SQL, schema, query, migration, backup, database MCP | [references/databases.md](references/databases.md) |
| Operations, automation, analytics, documentation, meetings, business systems | [references/business-work.md](references/business-work.md) |
| Tool selection, overlap, installation, or setup maintenance | [references/tooling.md](references/tooling.md) |

Read a second reference only when the task genuinely crosses domains.

## 2. Choose one task owner

| Harness | Default role in this setup |
|---|---|
| Cursor | Visual IDE work, code navigation, interactive edits, diff inspection |
| Claude Code | Deep implementation, refactoring, debugging, structured review |
| Pi | Focused terminal tasks, repeatable automation, custom workflows |
| Kimi | Independent review, research, synthesis, or user-selected implementation |

Use one owner for each task. Add a second agent for an independent review or a separate worktree, not for concurrent writes to the same checkout. Use `workmux` for agent isolation when available.

Respect the user's explicit harness choice. Do not claim that one harness is always best.

## 3. Apply the domain workflow

Follow the selected reference and keep the work evidence-led. Prefer the smallest change and smallest toolset that can prove the result.

For setup work:

1. Run `zsc doctor` and `zsc skills doctor` when available.
2. Preview with `zsc knife --dry-run <profiles>`.
3. Install only the required profiles with `zsc knife <profiles>`.
4. Deploy the shared skill with `zsc deploy`.
5. Re-run health checks and report remaining manual steps.

For third-party tools or skills, inspect the source and installation behavior first. Pin the installer where practical. Do not enable automatic updates, hooks, background services, telemetry, or Defender exclusions without explicit approval.

## 4. Enforce risk gates

- Require authorization and a written scope before active security testing. A scope file constrains targets; it does not prove authorization.
- Keep recon passive by default. Require both `--active` and `--scope` for the bundled active pipeline.
- Treat target-controlled builds, tests, browsers, fixtures, and repositories as untrusted. Use an OS-enforced sandbox with restricted networking, environment, writes, and resources.
- Start infrastructure and database work read-only. Require explicit approval for the exact target and write action.
- Never print, commit, or exfiltrate secrets. Redact captured output.
- Do not weaken production security controls to make a tool work.

## 5. Verify and hand off

Prove the outcome with the appropriate evidence: tests, rendered inspection, scanner output plus manual validation, plan output, query results, restore test, or deployment health check. Distinguish verified findings from hypotheses.

Finish with four short parts when useful:

1. **Outcome:** what changed or was learned.
2. **Evidence:** commands, checks, artifacts, or observations.
3. **Risk:** unresolved issues, scope limits, or side effects.
4. **Next action:** the single most useful follow-up.

For scoped target validation, use `python3 scripts/scope_check.py TARGET --scope FILE` or filter candidate hosts with `--filter`. Test the script against a local fixture before relying on a modified copy.
