# ADR-002: State — Riverpod for DI, Bloc/Cubit for feature state, Command for writes

**Status:** Accepted
**Date:** 2026-07-14

## Context

The developer has strong existing Bloc/Cubit experience (their stated strength, and still the hiring standard in their target job market, Malaysia) but wants deliberate, bounded exposure to Riverpod (a named weak spot). Both patterns solve different problems and are often conflated or made to fight each other when misapplied to the same role.

## Decision

Split responsibilities cleanly by concern, not by preference:

- **Riverpod** — dependency injection / composition root only. Provides repositories, services, the DB instance, network clients. Replaces `get_it`. Riverpod is never used to hold UI/feature state.
- **Cubit** — simple, form-like screen state (Add Expense form, Profile, Settings) where a stream of discrete events isn't needed.
- **Bloc** — event-driven flows with more complex state machines (`AuthBloc`, `SyncBloc`).
- **Command pattern** — every mutation (AddExpense, EditExpense, Settle) is a serializable `Command` object persisted to the offline outbox (see ADR-003). `SyncBloc` drains the queue.

## Consequences

**Positive**
- Riverpod is learned in a narrow, well-defined role (DI graph assembly) where it can't collide with Bloc's responsibilities — avoids the common anti-pattern of running two competing state-management philosophies against the same state.
- Bloc/Cubit stays central, preserving the developer's existing strength and market-relevant skill.
- The Command pattern gives a genuine, load-bearing use of an OOP pattern (another stated weak spot) rather than a contrived exercise — it directly produces the offline outbox, retries, and a natural undo story from one abstraction.
- Environment-aware Riverpod composition root makes it straightforward to swap in fakes for `dev`/tests.

**Negative / accepted trade-offs**
- Two state-management libraries in one codebase raises onboarding cost for anyone unfamiliar with the split — mitigated by documenting the boundary clearly (this ADR) and enforcing it by convention/review.
- Command objects add a serialization layer (to JSON, for the outbox) that a simpler direct-repository-call approach wouldn't need.

## Alternatives considered

- **Riverpod for everything (including feature state via `AsyncNotifier`/`StateNotifier`)** — rejected: would abandon the developer's Bloc strength entirely and isn't the local hiring standard.
- **Bloc/Cubit for DI too (via `RepositoryProvider`)** — rejected: doesn't give dedicated, bounded practice with Riverpod, which is an explicit learning goal.
- **`get_it` + injectable for DI** — rejected: doesn't address the Riverpod learning goal; Riverpod's compile-time safety and testability are also a better fit for a project explicitly practicing tech-lead-level DI design.
