# Development workflow

## Route the work

- Vague feature or decision: use `grill-me`; record the accepted scope and non-goals.
- Hard bug: use `diagnosing-bugs`; build a fast red-capable reproduction before theorizing.
- Behavior change: agree on public test seams, then use `tdd` in small vertical slices.
- Large change: create a short spec, split into independently verifiable slices, and use one worktree per slice.
- Review: inspect the diff against the originating requirement, coding standards, security boundaries, and actual test evidence.

Do not run two full development methodologies over the same task. Matt Pocock's skills are the default; Addy Osmani's lifecycle pack is an alternative, not another mandatory layer.

## Execute

1. Confirm the base ref, working tree state, and expected deliverable.
2. Create or select an isolated branch/worktree. Use `workmux add <name>` when available.
3. Read project instructions and nearby tests before editing.
4. Make the smallest coherent change; keep generated files and dependency updates separate.
5. Run the narrowest meaningful test first, then the project quality gates.
6. Inspect the final diff for unrelated edits, secrets, migration risk, and missing negative cases.
7. Commit only after verification. Request approval before push, merge, release, or deployment.

## Knife selection

| Need | Default |
|---|---|
| Versions | `mise`, pinned per project where possible |
| Navigation/edit | Cursor or LazyVim; `rg`, `fd`, `fzf`, `zoxide` |
| Git | `git`, `lazygit`, `delta`, `gh` |
| Parallel agents | `tmux` + `workmux`, one worktree per writer |
| Python | `uv` or the project's existing toolchain; `pipx` for global CLIs |
| Pre-commit | `pre-commit`, `shellcheck`, `gitleaks` |
| Browser verification | Playwright or the project's existing browser test stack |
| API work | Hoppscotch or Yaak; OpenAPI contract and contract tests |

Do not replace a project's package manager, formatter, test runner, or release process just because another tool is installed.

## Definition of done

- The requested behavior is implemented and nothing unrelated was changed.
- The exact checks run and their results are reported.
- A regression test exists for a fixed bug when a suitable seam exists.
- Documentation matches visible behavior and operational changes.
- Push, merge, deployment, and other external effects remain explicitly approved.
