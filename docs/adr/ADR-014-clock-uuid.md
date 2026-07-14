# ADR-014: Clock and UUID are injected abstractions

**Status:** Accepted
**Date:** 2026-07-14

## Context

The entire sync design (ADR-003, ADR-006) depends on two primitives: a client-generated UUID (`client_id`) for idempotency, and a timestamp (`updated_at`) for last-write-wins conflict resolution. If either is called directly from feature code (`DateTime.now()`, `Uuid().v4()` scattered wherever needed) rather than injected, sync logic becomes untestable — tests can't control "what time is it" or "what ID gets generated next" — and subtle correctness bugs (e.g. a test that's flaky depending on real wall-clock time) become likely.

## Decision

Both **Clock** and **UUID generation** are injected abstractions (interfaces with a real implementation and a fake/deterministic test implementation), wired through the composition root (Riverpod, ADR-002) alongside repositories and services.

## Consequences

**Positive**
- Sync logic (idempotency checks, LWW comparisons) becomes fully deterministic and testable: tests inject a fake Clock to simulate specific timestamps and a fake UUID generator to produce predictable IDs, rather than depending on real time or random values.
- Removes an entire class of "unnamed dependency" bugs the charter calls out explicitly: code that silently depends on `DateTime.now()` or a global UUID call is easy to overlook until it causes a flaky test or a subtle production bug (e.g. a race between two devices' clocks).
- Consistent with the rest of the Stage 6 "spine" — cross-cutting primitives that every feature leans on, built once, correctly, before feature #1.

**Negative / accepted trade-offs**
- Every place that needs the current time or a new ID must go through DI rather than calling a static/global function directly — marginally more ceremony for what's normally a one-line call.
- Requires discipline (and ideally a lint rule) to prevent `DateTime.now()`/`Uuid().v4()` from creeping into feature code directly, bypassing the injected abstraction.

## Alternatives considered

- **Direct calls to `DateTime.now()` and a global `Uuid()` instance wherever needed** — rejected: exactly the untestable, unnamed-dependency pattern this ADR exists to prevent, and the charter flags it as a source of "silent correctness bugs" specifically because sync depends on both being reliable and controllable in tests.
