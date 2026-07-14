# ADR-003: Offline strategy = local DB SSOT + outbox/Command queue + idempotency key

**Status:** Accepted
**Date:** 2026-07-14

## Context

The product's core promise is that it works with no signal and reconciles later, without ever double-charging (charter §1, §5, §11). This is the single hardest correctness property in the app and the centerpiece of its interview story. It needs a design that survives app-kill, network flapping, and out-of-order delivery.

## Decision

- **Reads:** the UI reads only from the local database. Never a direct remote read. This makes reads instant and offline-safe by construction.
- **Writes:** every write goes to the local DB immediately (optimistic) **and** enqueues a serializable `Command` (ADR-002) in a local-only `outbox` table. The UI returns instantly; nothing waits on the network.
- **Sync:** `SyncBloc` drains the outbox when connectivity is available (ADR-008), with exponential backoff on failure.
- **Idempotency:** every outbox-originated row carries a client-generated `client_id` (UUID, ADR-014). The server upserts on `client_id`, so retried or duplicated sends never create duplicate rows.
- **Conflict resolution:** last-write-wins by `updated_at` for v1 (ADR-006), with a documented upgrade path to field-level merge.

## Consequences

**Positive**
- Correctness (no duplicate expenses) is enforced structurally via the idempotency key, not by hoping retries don't overlap.
- UI responsiveness is decoupled from network state entirely — the product NFR "100% of core reads and writes available offline" falls out of the design rather than being bolted on.
- One unified mutation path (Command → outbox → drain) means every future write-type (settle, edit, delete) gets offline support, retry, and idempotency for free, rather than being re-solved per feature.
- Directly generates a strong, specific interview narrative: SSOT, optimistic UI, outbox pattern, idempotent upsert.

**Negative / accepted trade-offs**
- Every mutation must be modeled as a serializable Command up front — slightly more ceremony than calling a repository method directly, paid once per mutation type.
- Local DB schema must track sync metadata (`client_id`, `updated_at`, `deleted_at`) on every syncable table, increasing schema surface area.
- Last-write-wins (v1) is a known-lossy conflict strategy for concurrent offline edits to the same row; accepted for v1, with the harder field-merge case explicitly documented rather than solved now (ADR-006).

## Alternatives considered

- **Direct remote reads/writes with local caching only** — rejected: doesn't meet the "100% of core reads/writes offline" NFR; a cache-first-but-remote-capable model still requires network for writes.
- **Server-generated IDs with client-side reconciliation** — rejected: reintroduces the duplicate-write risk this ADR exists to eliminate; client-generated UUIDs make idempotency trivial by comparison.
