# ADR-016: iOS deployment target = iOS 16 (last 2-3 major versions)

**Status:** Accepted
**Date:** 2026-07-14

## Context

The developer has no Mac and cannot run or test iOS locally at all — iOS work is scaffolded and validated for compilation only via GitHub Actions `macos-latest` runners (charter §0, §14, §15). No MVP feature (F1-F8: auth, groups, expenses, offline, biometric) is iOS-version-sensitive; all rely on long-stable APIs. The version choice matters more for real-world testability (borrowed devices, TestFlight testers) than for API access.

## Decision

**iOS 16** deployment target — tracking "last 2-3 major iOS versions" as a rolling policy rather than a fixed number that goes stale.

## Consequences

**Positive**
- Comfortably covers `LAContext` (biometric, MethodChannel #1) and `BGTaskScheduler`/`BGAppRefreshTask` (background sync, ADR-008) — both available well before iOS 16.
- Keeps real-world testing viable: any tester with a reasonably current iPhone (borrowed device or TestFlight) will be in range, without demanding bleeding-edge iOS.
- A rolling "last 2-3 majors" policy avoids the deployment target silently going stale as new iOS versions ship — it's a policy decision, not a one-time number to forget about.

**Negative / accepted trade-offs**
- **Standing caveat, independent of the version chosen:** nothing on iOS can be behaviorally verified without real hardware. CI (`macos-latest`) only proves Swift stubs *compile* — not that biometric prompts or background refresh actually work as intended. This must be tracked as an ongoing risk ("validated on Android, iOS deferred") regardless of deployment target, not resolved by this ADR.
- If Flutter is later bumped toward 3.44+ (ADR-012), Swift Package Manager becomes the default iOS/macOS dependency manager — a separate axis from deployment target that doesn't interact with this decision, but worth tracking together operationally.

## Alternatives considered

- **Latest iOS only (N)** — rejected: unnecessarily narrows the pool of possible testers/borrowed devices for a project that already can't test locally.
- **Very old floor (N-5+)** — rejected: no MVP feature needs it, and it would mean writing around older API shapes for biometric/background APIs that have meaningfully improved in recent versions, for no real benefit given the no-Mac constraint means those old versions can't even be tested against.
