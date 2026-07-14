# ADR-008: Background sync = WorkManager / BGTaskScheduler draining the same outbox as foreground SyncBloc

**Status:** Accepted
**Date:** 2026-07-14

## Context

The app's core correctness guarantee — an offline write eventually reaches the server — cannot be provided by a foreground-only listener, because the OS can kill the app process at any time. This is the same class of problem messaging apps solve for an unsent message, applied to shared expense ledgers (charter §12). Background execution must therefore be a first-class design concern, not an afterthought bolted on after MVP.

## Decision

**One outbox, two drainers, same mechanism.** `SyncBloc` (foreground, triggered by app-open + connectivity `EventChannel`) and an OS-scheduled background worker both drain the *same* outbox/Command queue defined in ADR-003. Only the trigger differs:

- **Android:** `WorkManager`, constraint-based (requires network), surfaced via the `workmanager` Flutter plugin. Deferrable — cooperates with Doze/App Standby rather than fighting them.
- **iOS:** `BGTaskScheduler` + `BGAppRefreshTask`. Scaffolded now (identifiers declared in `Info.plist`, Swift handler stubs written) even without a Mac to run it on; validated for compilation only via CI `macos-latest` runner, explicitly marked "validated on Android, iOS deferred" until real hardware is available.
- **Foreground service (Android only):** for guaranteed, user-visible, longer-running batch work (e.g. "Syncing 42 expenses…" after a whole offline trip, or batch receipt upload in Phase 6). iOS has no true equivalent — the asymmetry is called out explicitly rather than papered over.

No second, parallel sync path is built — background and foreground sync are the same drain operation with different triggers.

## Consequences

**Positive**
- Guarantees the "eventually reaches the server, even if force-killed" property that a foreground-only design cannot provide.
- Unifying the drain mechanism means every future mutation type gets background delivery for free — no per-feature background-sync logic to maintain.
- Constraint-based, deferrable scheduling (rather than exact-time or wakelock-heavy approaches) respects Doze/App Standby by construction, directly satisfying the battery NFR (charter §5).
- The iOS asymmetry (no true foreground-service equivalent) is documented as a real, worth-raising cross-platform design constraint rather than silently ignored — genuine interview material.

**Negative / accepted trade-offs**
- iOS background behavior is entirely unverified until real hardware is available — a standing risk that must be tracked, not a one-time caveat.
- WorkManager/BGTaskScheduler give no guarantee of *exact* timing — the OS decides when constraints are satisfied. Acceptable because sync is inherently eventual-consistency, not real-time (ADR-003, ADR-006).

## Alternatives considered

- **Foreground-only sync (SyncBloc listening while app is open)** — rejected outright: cannot survive app-kill, which defeats the product's core reliability promise.
- **A second, independent background-sync implementation separate from the foreground outbox** — rejected: would create two code paths draining state with different semantics, doubling the surface area for sync bugs.
- **Exact-alarm scheduling instead of constraint-based deferrable work** — rejected: fights Doze/App Standby, worse battery behavior, no meaningful benefit for a use case that's tolerant of eventual delivery.
