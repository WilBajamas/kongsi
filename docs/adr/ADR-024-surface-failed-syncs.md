# ADR-024: Failed syncs are surfaced to the user, never silently dropped

**Status:** Accepted
**Date:** 2026-07-27

## Context

`SyncBloc` classifies every send failure into one of two kinds ([ADR-003](ADR-003-offline-strategy.md), ADR-009):

- **`DeliveryFailed`** (offline, timeout, 5xx, 401, 429) — not the slip's fault. The
  drain halts *without* counting the attempt, so a slip retries indefinitely across
  launches and reconnects. **This behaviour is correct and unchanged by this ADR.**
- **`CommandRejected`** (other 4xx) or an undecodable payload — the slip's own fault.
  The attempt is counted, and after `_maxAttempts` (5) the slip is marked `failed`
  (dead-lettered) so it stops blocking the strict-FIFO queue. *(This ADR changes the
  threshold to one — see Decision.)*

The dead-letter path was designed to solve head-of-line blocking: one permanently bad
slip must not freeze every good slip behind it. It does solve that. But it created a
worse problem that was never recorded.

**The gap.** `getPending()` filters on `status = pending`, so a dead-lettered slip
leaves the queue — and **nothing else happens**. The local row that the slip was
supposed to sync stays exactly as the user wrote it. The write intent is discarded;
the write is not. `SyncState.SyncFailure` is emitted but no widget listens to it.

The result: the phone and the server permanently disagree, and **nobody is told** —
not the user who made the change, not the developer, not the other people in the
group.

**Concrete two-user failure:**

1. User A creates a group, then edits it. The edit is rejected by the server five
   times and dead-letters.
2. A's local DB still holds the edit, so **A's screen shows it as saved, forever.**
3. User B opens the group, sees the *un-edited* version (the server never got A's
   edit), and edits the same field. B's write syncs fine.
4. Once incoming sync exists, B's value flows down and overwrites A's local row —
   **A watches their own edit disappear from their own screen** with no explanation
   and no way to recover it.

**The root error is a borrowed pattern.** Dead-letter queues come from server-side
messaging (Kafka, RabbitMQ), where parking a bad message is safe *because an ops team
is alerted and works the queue*. The pattern's safety comes from the human attached to
it. On a phone there is no such human, so the same pattern degrades into: silently
delete the user's work and tell no one.

Dead-lettering a **system message** is fine. Dead-lettering **something a person
typed** is not.

## Decision

**A failed sync becomes a visible, actionable state instead of a silent drop — and it
becomes visible on the *first* rejection, not the fifth.**

1. **Dead-letter a permanent failure immediately.** A `CommandRejected` (4xx) or an
   undecodable payload is marked `failed` on its **first** occurrence. The retry
   ceiling is removed from the drain.
2. **Transient failures are untouched.** `DeliveryFailed` (offline, timeout, 5xx, 401,
   429) still halts the drain *without* counting and *without* surfacing anything.
   Being offline is the normal case, not an error to report.
3. **Keep the existing parking mechanics.** The slip is already *parked*, not deleted —
   `markFailed` is an UPDATE setting `status = failed`, and the row keeps its full
   `payloadJson`. Everything needed to recover is already on disk. The queue still
   keeps flowing past it.
4. **Expose failed slips.** Add a read path to `OutboxRepository`
   (`watchFailed()` / `getFailed()`), mirroring `getPending()`.
5. **Show them.** A presentation surface (banner or a dedicated "sync problems" view)
   tells the user plainly that a change could not be saved.
6. **Offer retry.** Reset the slip to `status = pending` and let the normal drain pick
   it up again. Each manual retry gets one fresh attempt, since a permanent failure
   dead-letters on first rejection.
7. **Defer discard.** See below — discarding correctly needs a rollback capability
   that does not exist yet.

## Why the retry ceiling goes

`_maxAttempts = 5` existed as a safety net from before failures were classified: if you
cannot tell "bad data" from "bad network," counting attempts is the only way to stop an
infinite loop. `SendFailure` made that distinction explicit, which makes the counter
redundant for permanent failures.

Retrying a `CommandRejected` is provably useless within a drain cycle: the same payload
against the same server returns the same 4xx. The four extra attempts buy nothing but
delay — and that delay is now *user-visible* latency, because each attempt needs its
own drain (the loop halts on failure), and drains only fire on app launch or reconnect.
Under the old rule the user would not hear about a failed change for **five launches or
reconnects**, potentially days after the action that caused it.

An undecodable slip is permanent for the same reason: a missing catalog entry is a bug,
and no number of retries adds the entry.

The `attempts` column stays, demoted to a **diagnostic counter** — how many times this
slip has been tried across manual retries — rather than a control-flow input.

**Scope boundary:** this ADR fixes *silence*. It does not fix *divergence* — a failed
change still leaves the phone ahead of the server. It converts an invisible,
unrecoverable data-loss event into a visible problem a human can act on.

## Prerequisite: make the idempotent upsert real

**This must land before or with the change above, or the first user-visible warning
will be a false alarm.**

[ADR-003](ADR-003-offline-strategy.md) states that "the server upserts on `client_id`,
so retried or duplicated sends never create duplicate rows." That is the entire basis
of the at-least-once guarantee — but it was never actually configured.

`SupabaseCommandSender` posts with `Prefer: return=minimal` only. For PostgREST, an
upsert requires **`Prefer: resolution=merge-duplicates`**. Without it, a `POST` whose
primary key already exists returns **409 Conflict**, which the classifier reads as
`CommandRejected`.

So the exact scenario at-least-once exists to make safe currently ends in a rejection:

1. Slip is sent successfully — the row **is** on the server.
2. App is killed before `delete(slip.id)` runs.
3. Next drain re-sends the slip (correct, by design).
4. Server returns **409** — duplicate primary key.
5. Classified as a permanent rejection.
6. **Under this ADR, the user is warned that a change failed — when it succeeded.**

Alarming a user about data that is already safely on the server is worse than the
silence this ADR set out to fix. The fix is one header:

```
Prefer: return=minimal,resolution=merge-duplicates
```

The conflict target is the primary key, which is already the client-generated UUID
(`Group.id`), so no `on_conflict` parameter is needed. *(Note: ADR-003 calls this
`client_id`; the implementation uses the row's own `id` column. Same idea, different
name — worth aligning the wording when this is built.)*

This also means the duplicate case stops being an error at all: the re-send succeeds,
the slip is deleted, and nothing surfaces. **Verify on device** — the crash-between-
send-and-delete path has never been exercised against the real backend.

**Consequence for the classifier:** with a working upsert, 409 becomes rare enough that
leaving it as a permanent rejection is defensible. If it turns out to occur for other
reasons, move it to `DeliveryFailed` alongside 401/429 rather than reinstating a retry
count — naming which codes are transient is an explicit decision; counting attempts is
a guess.

## Why discard is deferred

"Discard" should restore the local row to its last-synced value. That is impossible
today: nothing records what the value was before the edit. There is no shadow copy, no
server `updated_at`, and no version counter — the outbox stores only `commandType` and
`payloadJson`.

Shipping retry-only is honest and complete on its own. Discard arrives with the
base-version work (below).

## Consequences

**Positive**

- The worst property of the current design — losing a user's work with no signal — is
  gone. Whatever else happens, the user is told.
- Recovery costs almost nothing to build: the failed slips and their payloads are
  already persisted; only a read path and a screen are missing.
- The sync pipeline barely changes. The sender, registry, failure classifier and
  triggers are untouched; the drain loop only *loses* code (the ceiling check).
- The user hears about a rejected change on the next drain rather than five drains
  later — minutes instead of potentially days.
- A visible failure state makes stricter queue policies defensible later — blocking on
  a bad slip is only unacceptable while the block is invisible.

**Negative / accepted trade-offs**

- **Divergence still exists.** Until rollback lands, a failed change leaves the local
  DB holding state the server will never have. This is now *disclosed* rather than
  *hidden*, which is an improvement, not a fix.
- **Sync stops being fully invisible.** [ADR-006](ADR-006-conflict-resolution.md)
  rejected manual conflict resolution partly to avoid making sync a user-facing chore.
  This ADR accepts a *narrow* exception: only permanently-rejected writes surface, and
  transient/offline failures stay silent as before. A rare, honest prompt beats silent
  loss.
- **No second chance for a 4xx that was actually transient.** If a status code is
  genuinely retryable, first-strike dead-lettering now bothers the user instead of
  quietly resolving. The retry count was masking that question; removing it forces the
  classifier to answer it explicitly, which is the correct place for the judgement.
  401 and 429 are already treated this way. The known instance — 409 from a duplicate
  send — is handled by the upsert prerequisite above.
- **The dependent-slip cascade remains open.** When a slip dead-letters, slips queued
  behind it that depended on it still send. Phase 0 has one command type and no
  dependencies, so this cannot bite yet; it becomes real in Phase 2. The likely fix is
  per-entity FIFO (ordering within each entity's own chain) which needs an
  `aggregate_id` column on the outbox. Deferred deliberately, not overlooked.

## Alternatives considered

- **Go server-first (no offline writes)** — rejected. It dissolves the problem by
  abandoning the product's core promise (charter §1, ADR-003) and, with it, most of
  what makes this codebase worth discussing. The gap is one bad policy decision, not a
  failure of offline-first.
- **Retry forever, never dead-letter** — rejected for *rejected* writes. A slip the
  server will always refuse cannot be fixed by repetition; only a human can decide
  what to do with it. (This *is* already the behaviour for transient failures, which
  correctly never count toward the ceiling.)
- **Freeze the whole queue on any dead-letter** — rejected for now. It reinstates
  head-of-line blocking, which the dead-letter exists to prevent. Worth revisiting
  once failures are visible, since a *visible* block is far more defensible than an
  invisible one.
- **Roll back the local row on dead-letter (compensating transaction)** — the
  architecturally cleanest answer, and deferred only because it is not currently
  possible: no pre-edit value is stored anywhere. Blocked on the base-version work.
- **Append-only ledger** — a genuine improvement, but it addresses **merge**, not
  **delivery**. It stops incoming changes from destroying local edits; it does nothing
  for a change that never reaches the server. Belongs with the Phase 2 expense model,
  before real money data exists.
