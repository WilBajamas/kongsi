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
            Bloc->>Outbox: recordFailure(slip.id) · attempts+1, in SQL
            opt slip.attempts + 1 >= 5 (_maxAttempts)
                Bloc->>Outbox: markFailed(slip.id) · dead-letter — leaves getPending forever
            end
            Bloc->>Bloc: addError → net ④ · emit(SyncFailure) · HALT drain
            Note over Bloc: halt, not skip — FIFO is a correctness rule:<br/>later slips may depend on this one
        end
    end

    Bloc->>Bloc: emit(SyncIdle) · queue drained
```

**Reading it**

- **The two failure exits are the retry ceiling's whole design.** Only the slip's
  *own* fault (rejected / undecodable) counts toward the 5-attempt ceiling — if
  offline failures counted, five offline app-launches would dead-letter good data.
- **At-least-once, on purpose (steps 10–11):** delete-after-send means a crash
  between them re-sends once; the server's upsert on `client_id` makes the repeat
  a no-op. Exactly-once would cost far more machinery for the same result.
- **`droppable` (step 2)** exists because two triggers can fire close together
  (launch + reconnect) — the second request is dropped, never queued.
- **Trigger 3 is deferred:** an enqueue-time kick (write while already online →
  drain immediately) lands in Phase 1; backoff waits for a retry timer to exist.

**Seams:** who enqueues the slip (one transaction) → `02-groups-slice` · the outbox
table + `attempts`/`status` columns → `03-database-migrations` · what `send()` does
on the wire (interceptors, TLS) → `05-network-stack` · the reconnect trigger →
`06-connectivity`.
