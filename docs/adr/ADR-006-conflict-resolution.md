# ADR-006: Conflict resolution = last-write-wins (v1), field-level merge (v2, documented not built)

**Status:** Proposed
**Date:** 2026-07-14

## Context

Two devices can edit the same expense while both offline, then reconnect in either order. Something must decide which edit "wins" when they conflict. A fully correct, general-purpose merge (e.g. per-field CRDT-style resolution) is a substantial design and engineering effort disproportionate to an MVP.

## Decision

**v1:** last-write-wins (LWW) by `updated_at` (server-side comparison at upsert time, using the injected Clock abstraction, ADR-014). Whichever write has the later timestamp overwrites the row entirely.

**v2 (documented, not built):** the harder case — two offline edits to *different fields* of the same expense — should ideally merge at the field level rather than one edit clobbering the other. This is explicitly deferred, not solved, in v1.

## Consequences

**Positive**
- LWW is simple to implement, reason about, and test — a single timestamp comparison at write time.
- It's honestly documented as a known limitation rather than silently accepted, which is itself the valuable part of this ADR: being able to articulate the trade-off (charter explicitly calls this out as "interview gold") demonstrates awareness of a real distributed-systems problem without over-building for it.
- Matches the MVP's actual concurrency profile: conflicting edits require two people editing the *same expense* while *both offline* in the *same window* — plausible but rare for the target group sizes (2-8 people).

**Negative / accepted trade-offs**
- A genuine data-loss case exists: if User A changes the amount and User B changes the description on the same expense while both offline, LWW discards one of the two edits entirely, even though a field-merge could have preserved both.
- Clock skew between devices could, in principle, make an actually-earlier edit appear later if a device's clock is wrong — mitigated by using server-received order / server-assigned `updated_at` rather than trusting client clocks for the authoritative comparison.

## Alternatives considered

- **Field-level merge in v1** — rejected for MVP: meaningfully more complex (needs per-field change tracking, a merge policy per field type, and conflict UI for genuinely unmergeable cases), disproportionate to MVP scope and timeline.
- **Reject conflicting writes and force manual resolution** — rejected: contradicts the product's "seamless offline reconciliation" promise; would surface sync as a user-facing chore rather than an invisible background process.

---

## Addendum — 2026-07-27: this analysis is incomplete

The trade-off recorded above covers **one** data-loss case: two edits that *both reach
the server*, where LWW discards the earlier one. A second case was missed entirely.

**LWW only decides between writes that arrive.** It has no way to express a write that
never arrives and never will — which is exactly what a dead-lettered outbox slip
produces ([ADR-024](ADR-024-surface-failed-syncs.md)). In that case the outcome is not
"last write wins" but "the only write that managed to arrive wins," which is arbitrary
rather than a rule.

Worked example: User A edits an expense and the slip is permanently rejected; User B
later edits the same expense and syncs successfully. B's edit is *earlier in intent*
but wins by default, because A's never existed as far as the server is concerned. No
timestamp comparison ever happens — the conflict is invisible to LWW.

Two consequences for this ADR:

- The "negative / accepted trade-offs" list above understates the risk. Delivery
  failure is a distinct loss mode from concurrency, with a different fix.
- The v2 upgrade path (field-level merge) does **not** address it either. Merge
  strategies operate on writes that both arrived; this is a delivery problem.

The real fix is **base-version tracking** — each row carrying the server version it was
edited from, so a stale write is detected and rejected rather than silently resolved by
timestamp. That supersedes the mechanism LWW is built on, and is the likely successor
to this ADR. Not scheduled yet; recorded here so the gap is not rediscovered from
scratch.

Status stays **Proposed** — this addendum is a reason it should not be promoted to
Accepted as written.
