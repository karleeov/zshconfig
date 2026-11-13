# Business and work workflow

## Start with the operating need

Define the user, business outcome, current process, data handled, volume, service-level need, and measurable success criterion. Choose the smallest system that solves the problem; do not self-host an entire company stack in advance.

## Select one tool per job

| Job | Candidate from the knife roll |
|---|---|
| Automation | n8n; Automatisch only as an evaluated alternative |
| Knowledge/docs | Outline or the existing team wiki; MarkItDown/Pandoc for conversion |
| Meetings | Meetily when local-first transcription is a real requirement |
| Forms/feedback | Formbricks |
| Web/product analytics | Umami for web analytics; Metabase for BI |
| Customer support | Chatwoot |
| Secure document sharing | Papermark |
| Project management | Existing tracker first; Fizzy or Worklenz only when a new system is justified |
| Finance | Actual for personal/small-scope budgeting; use an accountant-approved ledger for company accounting |
| Documents/reports | Typst/Pandoc and the team's Office/PDF workflow |
| OCR/media | Surya or PaddleOCR; FFmpeg and yt-dlp where licensing and terms permit |

Treat these as per-project services, not global CLI packages. Configure a database, object storage where needed, HTTPS, SSO/MFA, backups, monitoring, retention, and upgrade procedures before production use.

## Automation workflow

1. Document the manual process and its owner.
2. Classify data and define retention, access, and approval boundaries.
3. Automate the smallest reversible step with structured logs and idempotency.
4. Keep human approval for payments, legal commitments, external publication, customer-impacting messages, and destructive synchronization.
5. Test failure, replay, duplicate delivery, and credential rotation.
6. Measure time saved, error rate, and business outcome; remove automation that adds more operational cost than value.

## Work output

For meetings and plans, distinguish decisions, action items, owners, deadlines, open questions, and evidence. Do not invent agreement or commitments. For research and business claims, use current authoritative sources and preserve attribution.
