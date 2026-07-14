# ADR-005: Local database = Drift

**Status:** Accepted (closed 2026-07-14, previously open in charter)
**Date:** 2026-07-14

## Context

The local database is the single source of truth for the entire app (ADR-003) — every read goes through it, and it must support relational joins for balance computation (expenses → splits → members), a migration story from day one, and encryption at rest (charter §13). The two realistic Flutter options were Drift (SQL/relational, on top of `sqlite3`) and Isar (NoSQL-ish, object-oriented, higher raw write throughput).

## Decision

Use **Drift**.

## Consequences

**Positive**
- Directly mirrors the Postgres/Supabase schema (ADR-001) — the same relational mental model applies on both client and server, which reduces cognitive overhead when reasoning about sync and is a stronger, more transferable interview story ("I designed a relational offline ledger with SQL joins for balance computation") than a NoSQL local cache would be.
- SQL joins make the balance/settle-up queries (who owes whom, simplified debts) natural to express and reason about, versus denormalizing or computing joins in application code.
- Supports SQLCipher for encryption at rest, satisfying the security plan (charter §13) without a second database technology.
- Has a first-class, type-safe migration story — directly supports the Stage-6 requirement to have a migration strategy "even when the schema is trivial," since the first unplanned migration on real data is explicitly called out as a risk to avoid.

**Negative / accepted trade-offs**
- Raw write throughput is generally lower than Isar for very high-frequency object writes — not a real constraint here, since expense-logging frequency is human-paced, not sensor/stream-paced.
- SQL/relational modeling has more up-front schema ceremony (migrations, typed queries) than Isar's more direct object storage — accepted as the cost of the relational benefits above.

## Alternatives considered

- **Isar** — faster to write against, less relational ceremony, but the ledger's core value (balances via joins) fits SQL better, and the charter explicitly favors the Postgres-mirroring mental model for the interview narrative it produces. Rejected.
- **Hive** — simpler key-value store; insufficient for relational balance queries without significant application-level join logic. Rejected.
- **sqflite (raw SQL, no codegen)** — lacks Drift's type-safety and migration tooling; would mean hand-rolling what Drift provides. Rejected.
