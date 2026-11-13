# Authorized security workflow

## Authorization gate

Before any active probe or scan, obtain the engagement type, exact targets, exclusions, rate limits, allowed techniques, testing window, and evidence-handling rules. Record them in a scope file. Never infer authorization from a public bug-bounty domain alone.

Scope entries may be exact hosts, wildcard domains, IP addresses, or CIDR ranges. Prefix exclusions with `!`; exclusions always win:

```text
example.com
*.example.com
203.0.113.10
2001:db8::/32
```

Use the bundled validator as a mechanical boundary, not as proof of permission:

```bash
python3 scripts/scope_check.py https://app.example.com/path --scope scope.txt
cat candidates.txt | python3 scripts/scope_check.py --filter --scope scope.txt > in-scope.txt
```

## Choose the least intrusive mode

### Passive recon

Use public sources and local analysis only. Produce candidate assets and mark them unverified until scope is checked. Do not send HTTP requests or vulnerability probes to discovered assets.

### Active web testing

Require explicit authorization, `--active`, and `--scope`. Filter every discovered host before probing. Preserve request logs, timestamps, tool versions, and rate limits. Start manually with Caido or ZAP for nuanced authentication and authorization work; use Nuclei only with appropriate templates and conservative rates.

### Code, dependency, and cloud audit

Map architecture and trust boundaries before hunting. Use Cloudflare's structured audit for substantial repository audits and Trail of Bits skills for focused review and validation. Execute target-controlled code only inside an OS-enforced sandbox; otherwise leave dynamic claims unverified.

Useful deterministic layers:

- Secrets: Gitleaks plus history review.
- Source: Semgrep/CodeQL where appropriate, followed by manual source tracing.
- Dependencies: OSV-Scanner or the ecosystem's native advisory tooling.
- Containers/IaC: Trivy and Checkov, with configuration context.
- AI applications: Promptfoo evaluations and explicit tool/data-boundary tests.

## Validate findings

For every candidate, trace attacker-controlled input to a security-sensitive sink and identify the failing boundary. Try to disprove the finding. Separate:

- **Confirmed:** reproducible or source-proven boundary failure with bounded impact.
- **Needs validation:** exact unresolved fact and the safest next check.
- **Rejected:** disproved candidate and the evidence that disproved it.
- **Hardening:** defense-in-depth improvement without a demonstrated vulnerability.

Do not treat scanner output as a confirmed vulnerability. Do not include evasion, persistence, credential theft, or post-exploitation in the default workflow.

## Report

Include scope and exclusions, tested versions, methods, coverage gaps, evidence, impact, reproduction steps, remediation, and retest result. Use CVSS only when it helps, and justify each metric. Redact secrets and personal data.
