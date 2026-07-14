# ADR-015: Android minSdkVersion = 26

**Status:** Accepted
**Date:** 2026-07-14

## Context

The charter's NFR calls for "a wide device range (old Android included)," but the actual target audience is 15-45 year olds, and the app will be presented to the public only once stable — not launching to an already-fragmented install base with legacy expectations. Two MVP-required features are directly sensitive to the SDK floor: biometric app-lock (F8, via `androidx.biometric`/`BiometricPrompt`) and notifications (v2, but architecturally connected to background sync work starting Phase 3).

## Decision

**`minSdkVersion 26`** (Android 8.0 Oreo, 2017). `targetSdk`/`compileSdk` track whatever the current Play Store-required level is at build time — a rolling policy, not a fixed number.

## Consequences

**Positive**
- `androidx.biometric`/`BiometricPrompt` is reliably supported from API 23 onward, comfortably covered at 26 — no degraded biometric UX to special-case.
- API 26 is exactly where Android's background-execution-limits era begins (Doze refinements, notification channels becoming mandatory, the behavioral model `WorkManager` was built around). Targeting 26+ means the background-sync design (ADR-008) only ever has to reason about one coherent OS behavior model, not also support pre-Oreo legacy background services as a fallback.
- Notification channels (mandatory at API 26+) are required for the v2 push notifications and the Phase 6 foreground-service progress notification — targeting 26 means building the correct pattern from the start rather than a legacy path that's later deleted.
- Reach cost is negligible for a 2026 launch to a 15-45 audience — this isn't a real trade-off against the "wide range" NFR so much as a sensible floor that excludes only very old, low-relevance devices.

**Negative / accepted trade-offs**
- Excludes devices on Android 6.0-7.1 (2015-2017 era) entirely — accepted given the audience and launch timing.
- Slightly narrower than the charter's original framing of "old Android included" might suggest if read literally — resolved by the actual target-audience conversation (15-45, public launch when stable), which supersedes the more generic framing.

## Alternatives considered

- **minSdk 21 (Lollipop, matches Flutter's historical default floor)** — rejected: predates reliable `BiometricPrompt` support and the entire Doze/background-limits model the sync design assumes; would require legacy-path handling for both.
- **minSdk 23 (Marshmallow)** — considered, valid, biometric-safe, but doesn't get the notification-channel/background-limits alignment that 26 provides; 26 was chosen as the better fit given the background-execution-heavy design (§12).
- **minSdk 30+ (much higher floor)** — rejected: no MVP feature requires it, and it would cut real reach for no corresponding benefit.
