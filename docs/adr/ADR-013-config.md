# ADR-013: Config = single typed AppConfig built at startup from --dart-define-from-file; no String.fromEnvironment in feature code

**Status:** Accepted
**Date:** 2026-07-14

## Context

Three environments (dev/staging/prod) each need their own Supabase project/schema, Firebase app, and base config (charter §14). Scattering `String.fromEnvironment` calls through feature code to read per-environment values is a config leak that becomes progressively harder to untangle as the app grows — every feature that reads config directly becomes another place that has to be found and fixed if the config strategy ever changes.

## Decision

- Build **one typed `AppConfig` object** once at app startup, populated via `--dart-define-from-file=config/<env>.json`.
- Inject `AppConfig` through the composition root (Riverpod, ADR-002) — feature code receives config values through DI, never by reading environment variables directly.
- Real per-environment config JSONs (`config/dev.json`, etc.) are gitignored; only `*.example.json` templates are committed.
- Three entry points (`main_dev.dart`, `main_staging.dart`, `main_prod.dart`) select the flavor and load the corresponding config file.

## Consequences

**Positive**
- Every environment-dependent value (Supabase URL/anon key, Firebase app config, feature flags) has exactly one place it's read from (`AppConfig` construction) and one typed object it flows through afterward — trivially greppable, trivially testable (inject a fake `AppConfig` in tests).
- Secrets (Supabase anon keys, etc.) never land in source control, since real config JSONs are gitignored from the start.
- Avoids the specific failure mode the charter calls out: `String.fromEnvironment` scattered through feature code becoming "a config leak you'll untangle for months."

**Negative / accepted trade-offs**
- Requires slightly more setup ceremony (three entry points, `--dart-define-from-file` wiring, typed config class) than the simpler-looking `String.fromEnvironment` calls it replaces — a one-time cost paid in Phase 0 rather than a recurring one paid throughout the project.
- Anyone bootstrapping the repo locally needs their own `config/dev.json` (from the example template) before the app will run — a documented onboarding step, not a hidden trap, per the Phase 0 Definition of Done ("clone, run one command, get dev flavor running").

## Alternatives considered

- **`String.fromEnvironment` calls scattered through feature code as needed** — rejected: exactly the config-leak anti-pattern this ADR exists to prevent.
- **A single shared config file for all environments (env selected at runtime by a flag)** — rejected: makes it too easy to accidentally point a dev build at prod data, and doesn't cleanly separate per-environment Firebase apps.
