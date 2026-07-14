# ADR-009: Error model = Result/Either + Failure taxonomy; exceptions never escape the data layer

**Status:** Accepted
**Date:** 2026-07-14

## Context

Error modeling retrofitted after the fact is one of the most painful refactors possible — every call site written before the change assumed the old (usually exception-based, untyped) contract. The charter names this explicitly as a Stage-6 "spine" primitive that must exist before feature #1, precisely because of how expensive it is to add later. Error handling is also a named weak spot to build up.

## Decision

- All data/domain-layer operations return a `Result`/`Either`-style type: success value, or a typed `Failure`.
- `Failure` is a taxonomy, not a single exception type — categories include at minimum: network, auth, validation, conflict, unknown.
- **Rule: exceptions never escape the data layer.** Any exception thrown by a plugin, the DB driver, or the network client is caught at the data-layer boundary and mapped into a typed `Failure`. Presentation and domain code never `try`/`catch` framework exceptions directly.

## Consequences

**Positive**
- Every call site is compile-time forced to handle the possibility of failure, rather than optimistically assuming success and being surprised by an uncaught exception in production.
- The typed `Failure` taxonomy lets UI code (Bloc/Cubit) branch on *kind* of failure (e.g. show "you're offline" for network failures vs. a validation message for validation failures) without string-matching exception messages.
- Sets up the sync design cleanly: a failed outbox drain returns a typed conflict/network `Failure` that `SyncBloc`'s backoff logic can react to directly (ADR-003, ADR-008).
- Built before feature #1, so every feature is "born compliant" rather than retrofitted — avoiding the single most painful refactor named in the charter.

**Negative / accepted trade-offs**
- More ceremony per data-layer function than simply throwing/letting exceptions propagate — every function's return type must be wrapped, and every call site must unwrap/pattern-match.
- Requires discipline to enforce the "exceptions never escape the data layer" rule consistently; without lint/review enforcement this can erode over time (mitigated by the Stage 5 enforced-boundaries lint rules).

## Alternatives considered

- **Bare exceptions with try/catch at the UI layer** — rejected: pushes error-handling responsibility to the least-informed layer (UI), and untyped exceptions can't be exhaustively handled or tested against.
- **Nullable return types (`T?`) instead of Result/Failure** — rejected: collapses all failure modes into a single "null," losing the ability to distinguish network vs validation vs conflict failures, which the sync design needs to react differently to.
