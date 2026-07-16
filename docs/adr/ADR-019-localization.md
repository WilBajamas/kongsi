# ADR-019: Localization = gen_l10n (ARB) + intl, translated in the presentation layer only

**Status:** Accepted
**Date:** 2026-07-17

## Context

The design brief (§9) makes locale-aware formatting, RTL layouts, and screen-reader labels hard requirements, and the app targets an en/ms/zh audience. Localization infrastructure has to exist before feature #1 so every feature is born localizable rather than retrofitted. Two separable concerns are involved: translating UI strings, and formatting data (currency/number/date) per locale. A related boundary already exists — ADR-009 has lower layers emit typed errors, with presentation translating them — so l10n must not leak below the presentation layer.

## Decision

- **Strings:** Flutter's first-party `gen_l10n` with ARB files (`app_en.arb` is the template). **Formatting:** the `intl` package. No third-party l10n runtime library.
- **Access is via `BuildContext`** (`AppLocalizations.of` / a `context.l10n` extension). Translation happens **only in presentation**. Domain, data, and Bloc/Cubit layers emit typed values (`AppError`, codes/keys, ADR-009); presentation maps them to localized strings at render time.
- **Locale resolution:** follow the device locale, fall back to English.
- **Supported locales (MVP scaffold):** `en` (template), `ms`, `zh` (Simplified). Infrastructure now; translations filled in per-feature later.
- **RTL-ready from day one:** use directional APIs (`EdgeInsetsDirectional`, `TextAlign.start/end`, `AlignmentDirectional`) throughout. Not exercised by the current LTR locales — an RTL locale gets added when RTL is validated (Stage 8 golden).
- **Generated code** outputs to a real directory (`lib/l10n/gen`, `flutter: generate: true`) and is committed, consistent with how other codegen (Drift) is tracked.
- The locale-aware **money/number formatter** (`intl`) is built when the first amount renders (Phase 2), not speculatively now.

## Consequences

**Positive**
- Features are born localizable — the harness exists before feature #1, like the test harness and the rest of the Stage 6 spine.
- l10n stays in presentation: Bloc/domain code is locale-free and easy to test, and a runtime language switch re-translates automatically on rebuild (nothing stale is baked into state).
- First-party tooling with minimal dependencies (`flutter_localizations` from the SDK + `intl`); no extra l10n runtime to own.

**Negative / accepted trade-offs**
- Translating a string requires a `BuildContext` — mild friction, but that requirement is exactly the guardrail that keeps l10n out of the lower layers.
- Non-English ARBs are stubs for now; untranslated keys fall back to English until filled in per feature.
- RTL is *ready* but *unverified* until an RTL locale is added — "supported" here means the code is directional, not that RTL has been exercised.

## Alternatives considered

- **Context-free global translation (e.g. `slang`/`easy_localization`-style accessors)** — rejected: convenient, but it lets l10n leak into domain/data/Bloc, bakes strings into state (stale on a runtime locale change), and introduces a global locale singleton that fights the composition root (ADR-002). The `context` requirement is the boundary we want, not a limitation to design around.
- **A third-party l10n runtime library generally** — rejected: `gen_l10n` + `intl` cover the requirement with no additional runtime dependency.
