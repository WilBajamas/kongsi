# ADR-011: Package/bundle ID = com.wilbajamas.kongsi

**Status:** Accepted (closed 2026-07-14, previously open in charter)
**Date:** 2026-07-14

## Context

The package/bundle ID is baked into app signing, Firebase project configuration, and Play Store / App Store listings the moment those are set up. Changing it later is a migration (new Firebase project, new store listing, re-signing, users effectively reinstalling rather than updating) rather than a simple edit — the charter explicitly flags this as "irreversible-ish" and requires it be decided before `flutter create`.

## Decision

`com.wilbajamas.kongsi`, using a domain the developer owns/controls (`wilbajamas`), applied consistently across Android `applicationId` and iOS bundle ID.

## Consequences

**Positive**
- Reverse-domain ownership avoids the common beginner mistake of shipping with `com.example.*`, which would need to be migrated before any real store listing or Firebase project could be considered permanent.
- Decided and applied before further Firebase/store configuration work, so nothing downstream needs to be redone.

**Negative / accepted trade-offs**
- Now effectively locked in: any future rebrand or domain change requires a genuine migration (new Firebase project, new signing identity, users reinstalling rather than updating), not a config edit. This is accepted as the correct trade-off, per the charter's own framing — better to pay a small amount of care now than a large migration cost later.

## Alternatives considered

- **`com.example.kongsi` (flutter create default)** — rejected: not owned, not viable for any real store listing, would require exactly the painful migration this ADR exists to avoid.
- **Deferring the decision until closer to launch** — rejected: Firebase project setup, Android signing, and CI configuration all depend on this value being stable from early in Phase 0; deferring would mean redoing that setup later.
