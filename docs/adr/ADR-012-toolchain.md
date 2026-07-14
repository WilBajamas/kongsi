# ADR-012: Toolchain = pinned Flutter SDK (FVM) + committed version file + dependency-bump policy

**Status:** Accepted (closed 2026-07-14, previously proposed in charter)
**Date:** 2026-07-14

## Context

"Works on my machine" is one of the earliest and dumbest sources of team/CI friction — an unpinned SDK means local dev, CI, and any future collaborator can silently drift onto different Flutter/Dart versions, producing inconsistent builds or subtly different behavior.

## Decision

- Pin Flutter **`3.41.4`** / Dart **`3.11.1`** via **FVM**, with the version file committed to the repo.
- A future bump to **Flutter 3.44** is explicitly planned as a deliberate Stage 1 action, not an incidental drift — see notes below.
- Dependency pinning strategy (exact vs caret) and who owns version bumps to be recorded in `pubspec.yaml` conventions as Stage 1 proceeds.

## Consequences

**Positive**
- CI, local dev, and any future collaborator are guaranteed to build against the same SDK version — eliminates an entire class of "why does this fail on your machine" issues before they can occur.
- Deferring the 3.44 bump to a deliberate, named Stage 1 action (rather than adopting it now, mid-Stage-0-decision-making, or drifting into it accidentally) keeps the SDK version change auditable and intentional.

**Negative / accepted trade-offs**
- Pinning means the project doesn't automatically benefit from upstream Flutter fixes/features until someone deliberately bumps the version — an intentional trade-off in favor of reproducibility over always-latest.
- The 3.44 release includes breaking changes (Android Kotlin/AGP requirements, Swift Package Manager as default on iOS/macOS, some widget callback signature changes) that must be handled deliberately when the bump happens — flagged here so Stage 1 doesn't treat it as a trivial version bump.

## Notes on the deferred 3.44 bump

At decision time, Flutter 3.44 was newly released. Its most-touted feature (Widget Previews) is explicitly experimental/preview status, not stable — not something to build a Stage 0 dependency around yet. Because this project is greenfield (zero feature code at decision time), the cost of adopting 3.44 is at its lowest possible point; deferring the actual bump to Stage 1 (rather than deciding never to bump) keeps that option open without blocking Stage 0 closure on it.

## Alternatives considered

- **No pinning (use whatever Flutter version is globally installed)** — rejected: exactly the "works on my machine" failure mode this ADR exists to prevent.
- **Adopt 3.44 immediately instead of deferring** — considered and rejected for *now*: doesn't block Stage 0, and deferring costs nothing since no code exists yet to migrate.
