# 03 · Database / migrations

**Type:** sequence — Drift's runtime calling *our* migration callbacks (inversion of
control: we never call `onUpgrade` ourselves); the `if (from < N)` guards are the
`opt` blocks.
**Source:** [technical-summary §6](../technical-summary.md) · [app_database.dart](../../lib/core/database/app_database.dart)

```mermaid
sequenceDiagram
    autonumber
    participant App as app (first DB use)
    participant Drift as Drift runtime
    participant MS as MigrationStrategy · app_database.dart
    participant SQL as SQLite file on device

    App->>Drift: first query → open "kongsi" (lazy)
    Drift->>SQL: read stored user_version
    SQL-->>Drift: stored version (none = fresh)

    alt fresh install
        Drift->>MS: onCreate(m)
        MS->>SQL: m.createAll() → AppMeta · Groups · Outbox
    else existing install · from < 3
        Drift->>MS: onUpgrade(m, from, to: 3)
        opt if (from < 2)
            MS->>SQL: m.createTable(groups) · v2 block
        end
        opt if (from < 3)
            MS->>SQL: m.createTable(outbox) · v3 block
        end
    end

    Drift->>SQL: stamp user_version = 3
    Note over MS,SQL: append-only: each version adds a block, old blocks never edited —<br/>the guards make every device run exactly the steps it hasn't seen, in order
```

---

**Tables (the v1→v3 shape)**

| Table | Columns (key) | Added |
|---|---|---|
| `AppMeta` | `key` (PK), `value` | v1 |
| `Groups` → `GroupRow` | `id` (PK), `name`, `currency`, `createdAt` | v2 |
| `Outbox` → `OutboxRow` | `id` (auto PK), `commandType`, `payloadJson`, `createdAt`, `attempts` (def 0), `status` (`pending`/`failed`) | v3 |

**War story — the v2→v3 bug.** An early version bumped `schemaVersion` to 3 but
**forgot the `createTable(outbox)` block.** A device on v2 got *stamped* v3 with no
outbox table; the next "create group" hit the missing table and failed. The save:
that write is **one transaction** (see `02-groups-slice`), so it rolled back whole —
**no orphan group** with a missing slip. Two lessons: migration blocks are
append-only, *and* wrapping the local write + enqueue in one transaction is what kept
data consistent while the schema was wrong.

**Seams:** who writes these tables in one transaction → `02-groups-slice` · how the
outbox rows drain and how `attempts`/`status` drive the retry ceiling → `04-sync-outbox`.
