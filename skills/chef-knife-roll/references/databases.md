# Database workflow

## Establish the boundary

Identify engine and version, environment, database/schema, ownership, replication topology, migration framework, and backup/restore procedure. Start with a read-only role and explicit timeouts. A read-only connection option is useful but does not replace least-privilege database permissions.

## Query and schema work

1. Inspect the schema and representative cardinality before writing queries.
2. Use bounded queries and `EXPLAIN`/plan analysis appropriate to the engine.
3. Validate results against row counts, invariants, and a second source when stakes are high.
4. Review indexes and rewrites against a realistic plan and data distribution.
5. Keep generated SQL, assumptions, and verification output together.

## Migration workflow

1. Use the project's existing migration tool; do not introduce a second one casually.
2. Write forward and rollback/recovery notes, including locking and data-volume behavior.
3. Test on a restored representative dataset, not only an empty development database.
4. Separate expandable schema changes from destructive or backfill-heavy changes.
5. Require explicit approval naming environment and migration before any production write.
6. Verify application health, constraints, row counts, and rollback/recovery readiness afterward.

## Knife selection

| Need | Default |
|---|---|
| Clients | Native `psql`, MySQL/MariaDB client, `sqlite3`, Redis CLI; DBX or DBeaver for GUI |
| Interactive Postgres | `pgcli` |
| Schema visualization | ChartDB, with generated diagrams checked against the live schema |
| SQL quality | SQLFluff using the project's dialect and rules |
| Go type-safe SQL | `sqlc` when the project already uses it or deliberately adopts it |
| BI | Metabase with a read-only analytics role and controlled sharing |
| Agent access | MCP Toolbox for Databases or the existing MCP server, project-scoped and read-only by default |

Do not give an agent production owner/superuser credentials. Keep MCP write tools disabled unless the exact operation, target, and approval mechanism are explicit.

## Backup and recovery

Define RPO/RTO, encrypt backups, restrict access, monitor backup freshness, and perform periodic restore drills. Record the latest verified restore—not merely the latest successful backup job.
