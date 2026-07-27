# 04 · Sync / outbox drain

**Type:** sequence — the drain is a story: trigger → decode → send → delete, with
two very different failure exits.
**Source:** [technical-summary §5](../technical-summary.md) · [sync_bloc.dart](../../lib/core/sync/sync_bloc.dart)

```mermaid
sequenceDiagram
    autonumber
    participant Trig as triggers · launch (01) / reconnect (06)
    participant Bloc as SyncBloc
    participant Outbox as DriftOutboxRepository
    participant Reg as CommandRegistry
    participant Sender as SupabaseCommandSender
    participant UI as SyncProblemsCubit → banner

    Trig->>Bloc: add(SyncRequested())
    Note over Bloc: droppable(): if a drain is already running,<br/>this event is DROPPED — drains never overlap
    Bloc->>Bloc: emit(SyncInProgress)
    Bloc->>Outbox: getPending()
    Outbox-->>Bloc: slips · status = pending, FIFO by id

    loop each slip, oldest first
        Bloc->>Reg: decode(slip.commandType, slip.payloadJson)
        Reg-->>Bloc: typed Command · the catalog's fromJson
        Bloc->>Sender: send(command)
        Sender->>Sender: POST /rest/v1/{command.table} · body = command.toRow() · HTTP in 05

        alt send succeeded
            Sender-->>Bloc: ok · server upserted on the client-generated id
            Bloc->>Outbox: delete(slip.id)
            Note right of Outbox: delete only AFTER success — a crash in between<br/>= one duplicate push, made safe by the idempotent<br/>upsert · at-least-once, not exactly-once
        else DeliveryFailed · offline, timeout, 5xx, 401, 429
            Sender--)Bloc: throw DeliveryFailed
            Bloc->>Bloc: addError → net ④ · emit(SyncFailure) · HALT drain
            Note over Bloc: not the slip's fault — attempts NOT counted,<br/>whole queue retries on the next trigger
        else CommandRejected · other 4xx — or undecodable slip
            Sender--)Bloc: throw CommandRejected / StateError
            Bloc->>Outbox: recordFailure(slip.id) · attempts+1 · diagnostic only
            Bloc->>Outbox: markFailed(slip.id) · dead-letter on the FIRST rejection
            Note right of Outbox: permanent: the same payload fails identically,<br/>and each retry would cost a whole launch —<br/>so tell the user now (ADR-024)
            Outbox--)UI: watchFailed() emits → SyncProblemsCubit → banner
            Bloc->>Bloc: addError → net ④ · emit(SyncFailure) · HALT drain
            Note over Bloc: halt, not skip — FIFO is a correctness rule:<br/>a manual retry re-queues under the original id,<br/>so it still sorts ahead of the slips behind it
        end
    end

    Bloc->>Bloc: emit(SyncIdle) · queue drained

    Note over UI,Outbox: — recovery: the user acts —
    UI->>Outbox: retry(id) · status → pending, attempts kept
    UI->>Bloc: add(SyncRequested()) · drain again
```

**Reading it**

- **The two failure exits are the whole design.** Only the slip's *own* fault
  (rejected / undecodable) is treated as permanent — if offline counted, a few
  offline launches would dead-letter perfectly good data.
- **A rejection dead-letters immediately and the user is told**
  ([ADR-024](../adr/ADR-024-surface-failed-syncs.md)). There's no retry ceiling:
  the same payload against the same server fails identically, and since the drain
  halts, each extra attempt would cost a whole launch or reconnect.
- **At-least-once, on purpose:** delete-after-send means a crash between them
  re-sends once; the server upserts on the client-generated id, so the repeat is a
  no-op. That upsert needs `Prefer: resolution=merge-duplicates` — **it is not the
  default**, and its absence made duplicates look like rejections for all of Phase 0.
- **`droppable` (step 2)** exists because two triggers can fire close together
  (launch + reconnect) — the second request is dropped, never queued.
- **Trigger 3 is deferred:** an enqueue-time kick (write while already online →
  drain immediately) lands in Phase 1; backoff waits for a retry timer to exist.

**Seams:** who enqueues the slip (one transaction) → `02-groups-slice` · the outbox
table + `attempts`/`status` columns → `03-database-migrations` · what `send()` does
on the wire (interceptors, TLS) → `05-network-stack` · the reconnect trigger →
`06-connectivity`.
