# ADR-022: App versioning & build-number source

**Status:** Accepted
**Date:** 2026-07-21

## Context

Distribution is about to begin (Firebase App Distribution, then the stores). Every build handed to testers, Crashlytics, or a store is identified by its **build number**, and stores reject any upload whose number isn't strictly higher than the last. A scheme has to exist *before* the first build ships — retrofitting one after builds with colliding numbers are in the wild is a painful cleanup (charter §6-A, "cost to retrofit").

Flutter's `pubspec.yaml` `version: x.y.z+N` already separates the two concerns people conflate:

- **version name** (`x.y.z`) — the human-facing semantic version.
- **build number** (`+N` → Android `versionCode` / iOS `CFBundleVersion`) — a machine-facing monotonic integer that identifies a specific binary.

The open question is only *where the build number comes from*. ADR-021 splits CI/CD across **two** hosts (GitHub Actions + Bitrise), which rules out any per-host counter.

## Decision

- **Version name = semantic, hand-bumped.** `major.minor.patch`, changed deliberately by the developer when cutting a release. Stays `0.x.y` through Phase 0.
- **Build number = `git rev-list --count HEAD`,** injected at build time by CI via `flutter build --build-number=<count> --build-name=<semver>` (these flags override pubspec). The `+N` in `pubspec.yaml` is only a local-dev default and is **never** hand-managed as the source of truth.
- **Multi-store distribution is deferred** to a release phase. One constraint is recorded now because it is architectural, not packaging: newer **Huawei** devices ship **no Google Play Services** (HMS only), so the **FCM push** planned in charter §10 will not reach them without a Huawei Push Kit path or a push abstraction. No store-specific build variants are added now — flavors (dev/staging/prod) are an *environment* axis, not a *store* axis.

## Consequences

**Positive**
- **CI-agnostic:** the same commit yields the same build number whether Actions or Bitrise builds it — directly compatible with the two-host split of ADR-021.
- **Monotonic and deterministic:** the count only grows with history; no shared mutable counter to drift or reset. Well under the `versionCode` ceiling (~2.1e9).
- Build numbers are automatic — no forgotten bump, no store rejection for a reused number, no manual pubspec edits in the release path.
- Clean Crashlytics grouping: distinct binaries carry distinct build numbers.

**Negative / accepted trade-offs**
- **Same commit → same build number.** Rebuilding an identical commit produces an identical number. Accepted: same code *is* the same build; if a rebuild ever needs distinguishing, the CI run id can annotate the version name without changing the scheme.
- Relies on **not rewriting shared history** (rebasing `main`/`develop` would move counts). Already the project's norm.
- The build-number source lives in CI config, not pubspec — one more thing a fresh clone's release path depends on (documented here and in the pipeline).

## Alternatives considered

- **CI run number** (`GITHUB_RUN_NUMBER` / `BITRISE_BUILD_NUMBER`) — simplest, but the two CI hosts keep **separate counters**, so numbers would collide and move backwards depending on who built. Disqualified by ADR-021's split.
- **Timestamp** (e.g. `YYMMDDHHMM`) — monotonic but opaque, large, and carries no link back to a commit. No advantage over the commit count.
- **Hand-managed `+N` in pubspec** — the default, rejected: forgettable, merge-conflict-prone, and the usual cause of "build already exists" upload rejections.
- **Building store-specific variants now** — premature; no public store presence exists in Phase 0.
