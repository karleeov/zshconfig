# Infrastructure workflow

## Start read-only

Identify the provider, account/subscription, environment, region, inventory source, state backend, and ownership boundary. Distinguish local, staging, and production explicitly. Never let an AI assistant discover the target by trying credentials or broad network scans.

## Change workflow

1. Capture current state, recent changes, health signals, and dependencies.
2. Write the desired change, blast radius, validation method, and rollback.
3. Use formatting, static validation, security scanning, and plan/dry-run output.
4. Review the exact plan and credentials context with the user.
5. Require approval naming the target and action before apply, restart, deletion, firewall change, or state migration.
6. Apply the smallest slice, verify service health and downstream behavior, and record the result.
7. Keep rollback usable; a backup without a restore test is not a rollback plan.

## Knife selection

| Need | Default |
|---|---|
| Containers | Docker Desktop with WSL integration, or the project's existing runtime |
| Kubernetes | `kubectl`, Helm, `k9s`; pin cluster-compatible versions per project |
| IaC | The project's Terraform/OpenTofu toolchain; never mix state writers casually |
| Configuration | Ansible with check/diff mode and inventory scoped to the environment |
| Security | Trivy, Checkov, Gitleaks, and policy checks appropriate to the platform |
| Remote access | Existing SSH/XPipe workflow; NetBird when an overlay network is required |
| Backup | Kopia or the established platform backup system; encrypt and test restores |
| Agent sandboxes | Devcontainers or Daytona after reviewing credentials and network access |

Install cloud CLIs per project with `mise` or devcontainers. Do not install Docker, Kubernetes, Terraform, and every cloud provider globally merely to fill a profile.

## AI assistance boundary

Use kubectl-ai and similar assistants to explain, summarize, and draft. Independently inspect generated commands and plans. AI output is never approval, inventory truth, or proof of successful deployment.
