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
