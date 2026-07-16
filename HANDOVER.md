# Kongsi — Session Handover

> Temporary working doc to hand context to a fresh agent session. Safe to delete once absorbed.
> Last updated: 2026-07-16.

## How to use this file

You (the next agent) are mentoring the developer through building **Kongsi** by hand, following the Phase 0 plan in `kongsi_project_charter.md` §6-A. Read this file, then skim `docs/adr/README.md` and the charter. The working-style rules (mentor mode, token efficiency, plain English, etc.) load automatically from the project's `MEMORY.md` — don't re-derive them, just follow them.

**One-line project summary:** offline-first shared-expense app (Flutter first, native Android later), built deliberately as a learning + senior→lead interview showcase. Full context in `kongsi_project_charter.md` + `kongsi_design_brief.md`.

## Working style (auto-loaded from MEMORY.md — summary only)

- **Mentor, don't implement.** The developer writes the code; you guide, explain trade-offs, ask decision questions. Only write files when they explicitly say so (they'll say for boilerplate).
- **Explain what/why/how** for every new file or config.
- **Plain, simple English.** Headings/structure for longer replies. Keep it token-tight — don't re-summarize settled decisions.
- **PowerShell** syntax for commands you give the developer. Use the **`fvm` prefix** (`fvm flutter`, `fvm dart`) — flag bare `flutter`/`dart`.
- **No CLAUDE.md / .agent files** — this is a by-hand learning project.
- `build_runner` codegen is fine (already the stack: Drift, Retrofit).

## Where we are

**Phase 0 — Foundations. Stage 6 (the spine), mid-way.** Stages 0–5 complete.

### Done

- **Stage 0** — all foundational ADRs closed (`docs/adr/`, 001–018). Key: package id `com.wilbajamas.kongsi`; Flutter **3.44.0** pinned via FVM (bumped from 3.41.4); Dart 3.12.0; **minSdk 26**; **iOS 16**; local DB **Drift**.
- **Stage 1** — FVM pin (`.fvmrc`), `.editorconfig`, dep policy = **caret + manual bumps**, `pubspec` sdk `^3.12.0`.
- **Stage 2** — scaffold audit clean (org/platforms/bundle-id all correct, `--empty` used).
- **Stage 3** — `very_good_analysis` + analyzer strict modes; lint overrides in `analysis_options.yaml` (`public_member_api_docs`, `one_member_abstracts` → false); `docs/definition-of-done.md`; `.github/PULL_REQUEST_TEMPLATE.md`. **Commit conventions deliberately skipped** (developer wants freedom there).
- **Stage 4** — 3 flavors (dev/staging/prod): entry points `lib/main_{dev,staging,prod}.dart`, typed `AppConfig` (`lib/core/config/app_config.dart`, reads `--dart-define-from-file`), Android `productFlavors`, `.vscode/launch.json`. Config JSONs gitignored + `*.example.json` committed. **iOS flavor scheme wiring deferred to Stage 9.**
- **Stage 5** — folder skeleton: `lib/{app,core,platform}` + `lib/features/{auth,groups,expenses,sync,settle}/{data,domain,presentation}` (`.gitkeep`s). **Import-boundary enforcement deferred** (ADR-017 — tooling immature).

### Stage 6 — spine (in progress)

- ✅ **Error model** — `lib/core/error/app_error.dart` (sealed `AppError`: Network/Auth/Validation/Conflict/Unknown, named required `message`, `Object? cause`) + `lib/core/result/result.dart` (sealed `Result` / `Success` / `Failure`). Note the deliberate names: branches = **Success/Failure**, taxonomy = **AppError** (ADR-009 wording "Failure taxonomy" → AppError).
- ✅ **Logger** — Talker (`talker_flutter`), `lib/core/logger/app_logger.dart` (`createLogger()`). Crashlytics `TalkerObserver` deferred until Firebase exists.
- ✅ **Clock + UUID** — `lib/core/system/{clock.dart,uuid_generator.dart}` (abstract + impl; injectable per ADR-014).
- ✅ **Network client** — `lib/core/network/`: `dio_client.dart` (`createDioClient`), `error_mapping_interceptor.dart` + `custom_error_code_mapper.dart` (raw dio error → typed `AppError`; hardcoded messages are **fallback/log defaults only** — presentation translates by error type for l10n), `network_result.dart` (`safeApiCall` → `Result`), `auth_token_provider.dart` (abstract), `auth_interceptor.dart` (hand-built `QueuedInterceptorsWrapper` + `Completer` lock, 401→refresh→retry-once). `talker_dio_logger` wired. See **ADR-018**: single token-refresh owner = Supabase SDK; the dio interceptor delegates via `AuthTokenProvider` (real impl is Phase 1).
- ✅ **Local DB (Drift)** — `lib/core/database/app_database.dart` (+ generated `app_database.g.dart`). Starter `AppMeta` table, `schemaVersion 1`, empty `onUpgrade` slot ready. First `build_runner` run succeeded. **SQLCipher encryption deferred to Phase 7.**
- ⬜ **Composition root (Riverpod DI)** ← NEXT. Ties together `AppConfig` (baseUrl), `Talker`, dio client, `AppDatabase`, clock/UUID, and a real `AuthTokenProvider`. Riverpod is **DI-only** (ADR-002).
- ⬜ **Theme from design tokens** (`kongsi_design_brief.md` §3).
- ⬜ **l10n setup** — added to plan this session (design brief §9 already requires locale-aware formatting + RTL). Needs an ADR + a stage home (suggested: Stage 6, alongside theme). Infra now, translations per-feature later.

## What's next (after Stage 6)

Per charter §6-A: **Stage 7** routing (`go_router`, deep-link-ready) → **Stage 8** test harness (1 unit + 1 widget + 1 golden) → **Stage 9** CI skeleton (+ validate deferred iOS flavors on macOS runner) → **Stage 10** global error capture → **walking skeleton** (tracer bullet, end-to-end) → Phase 0 DoD checklist.

## Open / deferred items to track

- **ADR-007** deep-link provider — Phase 4 spike.
- **ADR-017** import-boundary enforcement — revisit when tooling matures or enough feature code exists to justify a hand-written `custom_lint` rule.
- **iOS flavor scheme/pbxproj wiring** — Stage 9 (validate on macOS CI; no Mac locally).
- **SQLCipher encryption** — Phase 7.
- **Crashlytics `TalkerObserver`** — when Firebase exists.
- **Real Supabase project + real `config/*.json` values** — needed before the walking skeleton can be verified.
- **Real `AuthTokenProvider` impl** (Supabase-SDK-backed) — Phase 1, follow ADR-018 guardrails (no proactive check for Supabase calls; separate bare Dio if ever refreshing via raw dio; secure storage mainly backs SDK session).
- **`.g.dart` commit decision** — recommended **commit** them (fresh clone/CI builds without needing codegen first); developer hasn't confirmed yet.
- **Charter §0 "Current status" block is stale** (still says "Phase 0 not started"). It's the developer's authored doc — suggest they update it; don't edit without asking.
- Developer may later try **Riverpod state-management** on 1–2 isolated features (learning) — would be a small ADR-002 revision; fine if features don't share live state with Bloc-driven screens.

## Environment gotchas

- **Windows + PowerShell.** FVM SDK cache on `W:\fvm_cache`, pub cache relocated off C: (space). The `fvm` CLI had kernel-snapshot trouble earlier — it works now, but if it acts up, the pinned SDK is directly callable at `.fvm\flutter_sdk\bin\`.
- **Agent-side (your Bash tool) can't find `fvm`** — run analysis via `./.fvm/flutter_sdk/bin/flutter analyze` from the repo root. The developer runs things in their own PowerShell with the `fvm` prefix.
- **Conventions to preserve:** interface+impl split each in its own `core/` subfolder; `package:` imports (not relative); lint exceptions go in `analysis_options.yaml`; validate every new file with `flutter analyze` before moving on.
