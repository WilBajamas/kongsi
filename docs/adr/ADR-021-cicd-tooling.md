# ADR-021: CI/CD split — GitHub Actions (PR gate) + Bitrise (release) + fastlane

**Status:** Accepted
**Date:** 2026-07-19

## Context

CI/CD is a deliberate learning goal (charter §0). Stage 9 stood up a GitHub Actions skeleton for per-PR verification. But the mobile-specific problems — iOS builds and signing without a Mac, and automated distribution to Firebase App Distribution / the stores — are where a general-purpose CI host is weakest and a mobile-specialized one earns its keep. Running two hosts that do the *same* job is wasteful; the useful split is by responsibility.

## Decision

Two CI/CD hosts, divided by responsibility:

- **GitHub Actions — the per-PR verification gate.** On every push/PR: format, analyze, test, and per-flavor build-compile checks. Fast, free, ubiquitous; the pipeline is hand-written to build the fundamentals.
- **Bitrise — the release/distribution pipeline.** Signed builds, Firebase App Distribution, later TestFlight/Play. Chosen over Codemagic/CircleCI/Appcircle for its mobile-industry standing (strongest interview signal) and its signing/distribution tooling.
- **fastlane — the release-automation layer inside Bitrise** (also runnable locally): `match` for iOS signing, `supply`/`pilot` for store uploads, build-number bumps.

Implementation of the Bitrise + fastlane side is **deferred to the point where distribution first matters** — the Phase-0-DoD "staging build → Firebase App Distribution" step (around the walking skeleton), then extended for store release in Phase 7. The decision is recorded now; the wiring lands when it has a purpose.

## Consequences

**Positive**
- Each host does what it's best at: Actions for fast, free PR gating; Bitrise for the Mac-dependent signing/distribution work a no-Mac developer can't do locally.
- fastlane is the transferable, industry-standard release skill; learning it inside Bitrise covers signing + publishing once.
- Clear interview narrative: separation of verification vs release, on the tools mobile teams actually use.

**Negative / accepted trade-offs**
- Two CI systems to understand and maintain instead of one — accepted because they cover different responsibilities, not the same one.
- Bitrise's free tier is limited and its setup is heavier than Codemagic's Flutter-native flow — accepted for the résumé/skills value.
- fastlane adds a Ruby toolchain (Gemfile/Fastfile) — introduced only when distribution needs it, not in Phase 0.

## Alternatives considered

- **GitHub Actions alone (+ a Firebase action or fastlane for distribution)** — viable and single-tool, but skips the mobile-specialized CI experience that's a stated learning goal, and macOS minutes are limited/pricey on private repos.
- **Codemagic** — best Flutter-native fit and easiest no-Mac iOS + distribution; not chosen because Bitrise carries more mobile-industry recognition for the interview goal.
- **CircleCI / Appcircle** — CircleCI duplicates the general-CI learning Actions already provides; Appcircle has the least recognition. Neither justified.
- **fastlane from the start / everywhere** — rejected as premature; no signing or store presence exists in Phase 0.
