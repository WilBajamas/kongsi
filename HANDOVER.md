# Kongsi — Session Handover

> Temporary working doc to hand context to a fresh agent session. Safe to delete once absorbed.
> Last updated: 2026-07-22.

## How to use this file

You (the next agent) are **mentoring** the developer through building **Kongsi** by hand, following the Phase 0 plan in `kongsi_project_charter.md` §6-A. Read this file, then skim `docs/adr/README.md` and the charter. The working-style rules load automatically from the project's `MEMORY.md` — follow them.

**One-line project summary:** offline-first shared-expense app (Flutter first, native Android later), built deliberately as a learning + senior→lead interview showcase. Full context in `kongsi_project_charter.md` + `kongsi_design_brief.md`.

## Working style (auto-loaded from MEMORY.md + confirmed again this session)

- **Mentor, don't implement — but the balance shifted.** The developer now often delegates writing to the agent after a design walkthrough ("delegating to you"), then reads, questions, and reshapes the result. Still: walk through design decisions *before* code, explain what/why/how, plain simple English.
- **The developer asks deep "is this right?" questions** (e.g. mutable static state of `Bloc.observer`, all-purpose dialogs, Navigator vs auto_route pop). Give honest trade-off debates, not reassurance. They push back and propose alternatives — debate them properly (their record-list registry idea won over the agent's function design).
- **PowerShell** syntax, **`fvm` prefix** for developer-facing commands.
- **Respect their edits** — they rename (e.g. `fake_`→`mock_`, `watch_groups`→`watch_groups_use_case`/`WatchGroupsUseCase`), add their own warning comments, restructure. Never revert.
- **Comment style:** why not what; no ADR refs in code. This session they asked for *teaching-level* comments on the sync machinery specifically — that was an exception, on request.
- **Commits:** brief conventional messages, **NO AI signature/co-author trailer**. Split logical units. Developer sometimes commits themselves mid-flow — check `git log` before assuming.
- **Widget rules (stated explicitly):** lean, dumb widgets reacting to state; split when readability demands; no gratuitous `Builder`s; reuse via composition (slots) not configuration (flags); new widgets only with strict feature ownership.
- **Modern Dart is a standing goal** — charter §7-A (added this session) has the checklist + mentoring rule: flag Dart 3.x opportunities as code is written; one-line "why over the old way" on first use.
- **No CLAUDE.md / .agent files.**

## Where we are

**Phase 0 — essentially COMPLETE.** Walking skeleton end-to-end (local + outbox + Supabase sync, device-verified online *and* offline); retry ceiling / dead-letter; connectivity trigger (native EventChannel, both steps); and **Chunk C done — a signed staging APK auto-distributes to Firebase App Distribution** via Bitrise + fastlane on push to `develop`, device-verified. Onboarding captured (bootstrap scripts + README). Remaining: the Post-Phase-0 consolidation (charter §6-A: summary → diagrams → exam).

Real Supabase **and Firebase** projects exist; `config/dev.json` filled (gitignored). `groups` table created with **RLS disabled** for the skeleton (re-enabled when auth lands — real policies need `auth.uid()`).

**Branch protection on `main` — DEFERRED (external constraint, not an oversight).** GitHub gates branch-protection/rulesets behind a paid tier for *private* repos, and this repo is Free + private. Revisit on going public or GitHub Pro; meanwhile the PR-into-`main` flow is followed by discipline. The control was chosen; the platform tier gated it — documented rather than skipped.

Branch `develop`. A few recent **doc commits unpushed** — push `develop` to sync origin (and let CI confirm the iOS Swift stub compiles on the macOS runner). Working tree clean except this file. analyze `--fatal-infos` clean, tests **19/19**, format clean. Sandbox: `./.fvm/flutter_sdk/bin/flutter …` (fvm CLI not on sandbox PATH).

### Done this session (2026-07-21 → 22)

- **Real Supabase sync — walking skeleton closed:** `SupabaseCommandSender` (dio → PostgREST `POST /rest/v1/{table}`, anon key in `apikey` + `Authorization`) replaced the logging stub via the one-line `commandSenderProvider` swap. `Command` gained `table` + `toRow()` (server shape, snake_case) kept **separate** from `toJson()` (outbox storage shape) so on-disk format and server schema evolve apart. Device-verified online *and* offline.
- **Retry ceiling + dead-letter (`core/sync/send_failure.dart`):** `SendFailure` sealed pair — `CommandRejected` (4xx, counts) vs `DeliveryFailed` (offline/timeout/5xx, doesn't). Sender classifies (4xx except 401/429 → rejected). `SyncBloc` counts only the slip's own fault and `markFailed`s after `_maxAttempts = 5`, so a poison slip stops blocking FIFO; offline never dead-letters a good slip. Permanent branch is `on Object` (covers undecodable slips too). New `OutboxRepository.markFailed`. Device-verified with a force-fail CHECK constraint (5 fails → 6th silent).
- **mocktail adopted** (dev dep, no codegen) + **charter §7-B** (mock for stub/verify, hand-rolled fake for stateful behaviour). Reference test `test/features/groups/groups_page_mocktail_reference_test.dart` shows when/thenAnswer/any/registerFallbackValue/verify+captureAny. `_FakeOutbox` deliberately stays a fake.
- **Connectivity trigger — DONE (both steps):** `core/connectivity/` — `ConnectivityMonitor` interface + `ConnectivityStatus` enum + `EventChannelConnectivityMonitor` (wraps `EventChannel('kongsi/connectivity')`, `.distinct()`). Native `StreamHandler` on Android `ConnectivityManager` (`registerDefaultNetworkCallback`, posts to main thread, unregisters on cancel — `ConnectivityStreamHandler.kt` + `MainActivity.kt`); iOS Swift **stub** in `AppDelegate.swift` (compiles, emits nothing — real `NWPathMonitor` impl deferred). `SyncBloc` fires `SyncRequested` on online transitions; `on<SyncRequested>` uses `droppable()` (bloc_concurrency) so launch + reconnect drains can't race. **Manifest fix:** `INTERNET` (was **debug-only**!) + `ACCESS_NETWORK_STATE` added to `src/main`. Device-verified: airplane off → drains without relaunch. Dart wrapper unit-tested via mock stream handler. `StubConnectivityMonitor` deleted after the swap.
- **Comment trim** across the sync system (why-only, no paragraphs). `LoggingCommandSender` kept and reframed as the documented example of the `CommandSender` swap seam (see comment on `commandSenderProvider`).
- **Chunk C — CI release to Firebase App Distribution (DoD box ticked):** **Bitrise** (the *Bitrise CI* product, not Release Management) builds a signed staging APK on push to `develop`; **fastlane** (`android/fastlane/`, `firebase_app_distribution` plugin) uploads it to the `internal` group. `bitrise.yml` is repo-stored (config-as-code); secrets (`STAGING_CONFIG_B64`, `FIREBASE_SERVICE_ACCOUNT_B64`, `FIREBASE_STAGING_APP_ID`) injected as env vars, base64 files decoded in-workflow; full clone (`clone_depth: -1`) so the build number is right. Device-verified: build lands in FAD + on phone.
- **ADR-022 (versioning & build numbers):** semantic version name hand-bumped; build number = `git rev-list --count HEAD` injected by CI (CI-agnostic — survives the ADR-021 two-host split); Huawei/GMS→FCM noted as a release-phase constraint; multi-store deferred.
- **Onboarding (soft DoD item 1):** `tool/bootstrap.ps1` + `tool/bootstrap.sh` (cross-platform, `.sh` exec bit set in git) + README "Getting started" — captures FVM install, the native-assets flag, `pub get`, and the `config/dev.json` seed. Offline-first means the example config still runs locally.
- **Tests: 19** (was 11) — +3 SyncBloc (retry ceiling + connectivity), +1 mocktail reference, +1 connectivity wrapper; round-trip guard still there.

### Foundations already in place (earlier sessions — now in code/ADRs)

Stages 0–10; global error capture (4 nets incl. `Bloc.observer`, `lib/bootstrap.dart`); hand-built `ProviderContainer` + `UncontrolledProviderScope`; local slice `features/groups/` (Drift `groups` v2 → `GroupsRepository` → `WatchGroupsUseCase` → `GroupsCubit` → `GroupsPage`); outbox schema v3 (autoincrement id = FIFO, `OutboxStatus` pending|failed, attempts) + GoF `Command` + immutable `CommandRegistry` (declarative catalog in `lib/app/command_registrations.dart`); `createGroup` = one transaction (group + slip); clock/uuid injected; `CreateGroupDialog` + presentation-flavor MVVM Command (`lib/app/command/`, **verdict ADR still unwritten**); dev seed; CI goldens config (platform goldens off on CI, `CiGoldensConfig(diffThreshold: 0.001)`). freezed deferred; **equatable** used.

## Key decisions / war stories (interview material — keep)

**This session (2026-07-21 → 22):**

- **Command→row mapping lives on the command (`table`/`toRow`), not a repository.** A remote repository would need a type-dispatch table coupling sync→features; keeping each command's destination on itself keeps the drain a generic pipe. Repository approach noted as the natural refactor if a command ever needs real remote logic.
- **`toJson` (outbox storage) vs `toRow` (server) kept separate on purpose** — welding them would let a server column rename break slips already queued on a user's disk.
- **Retry ceiling counts only "the slip's own fault" (4xx / undecodable), never transient/offline** — counting offline failures would dead-letter good slips after N offline launches. The real problems it solves: infinite retry loop + head-of-line blocking (one poison slip freezing the FIFO queue).
- **RLS 401 was proof, not failure:** the request reached PostgREST and was rejected only at the RLS gate → whole pipeline correct. RLS disabled for the auth-less skeleton (real policies need `auth.uid()`).
- **droppable transformer** adopted once there were two sync triggers (launch + reconnect), so overlapping drains can't race on the same slips.
- **mocktail over mockito** — no codegen, stays out of the analyzer-clash ledger; mock-vs-fake is a deliberate per-double call (§7-B).
- **`INTERNET` was declared only in the *debug* manifest** (Flutter template default) — dev builds reached Supabase, but a release/profile build would have shipped with no network permission. Moved to `src/main` with `ACCESS_NETWORK_STATE`. Also: native EventChannel callbacks arrive on a binder thread → must hop to the main thread before touching the `EventSink`.
- **CI/CD auth is where the setup pain lives (Bitrise + FAD):** four separate traps — picked the wrong Bitrise *product* (Release Management ≠ Bitrise CI, only CI builds from source); Bitrise clones via the **GitHub App token**, so `activate-ssh-key` must be `run_if` SSH-present or it fails; and FAD "permission denied" was a **valid key for the wrong service account on the wrong GCloud project** — auth succeeded, *authorization* didn't. Fix: SA with `roles/firebaseappdistro.admin` + Firebase App Distribution API enabled, on the **correct** project. Interview gold on auth-vs-authz.

**Earlier sessions:**

- **freezed evaluated and deferred:** every stable 3.x clashes (needs analyzer <11 / source_gen ^2; drift_dev needs analyzer ^13, retrofit_generator source_gen ^4). Only `4.0.0-dev` resolves — won't build foundations on a prerelease. Revisit at 4.0 stable. **equatable** added instead; hand-write `copyWith` where needed.
- **sqlite3 native-assets hunt:** first real DB query on device threw `dlopen libsqlite3.so not found`. Root cause: `sqlite3 5.x` ships its native lib via **Dart build hooks**, and Flutter 3.44 has `enable-native-assets` **off by default**; `sqlite3_flutter_libs` is an obsolete tombstone (developer caught this in its README). Fix: `flutter config --enable-native-assets` + clean rebuild (verified `libsqlite3.so` in APK) + the same config step added to all three CI jobs. **Machine-level flag = teammate/DoD trap — must be documented in README/setup eventually.**
- **First real migration bug:** v2→v3 upgrade forgot `createTable(outbox)`; device DB got stamped v3 without the table. Transaction rolled back correctly (no orphan group). Fix + wipe. Lesson: migration blocks accumulate append-only.
- **Command-pattern disambiguation:** GoF (serialized outbox commands) vs MVVM (button lifecycle wrapper, Flutter docs' version) — both now exist, deliberately, implemented on different machinery. Interview line material.
- **Registry = data over behavior:** developer's proposal (const list of named records) beat imperative `register()` calls; registry made immutable-at-construction; core provider throws, bootstrap overrides (appConfig pattern).
- **At-least-once + idempotency** chosen over exactly-once: delete-after-send; crash between = duplicate push made safe by client-generated ids.
- **Retry ceiling → `failed` DONE this session** (was the known dead-letter TODO). Backoff still deferred — it pairs with a retry timer we don't have yet; launch/reconnect spacing suffices for now.
- Benign device log noise: `IllegalArgumentException ... surface control` from Android graphics layer during surface rebuilds — not ours, no crash, ignore unless it escalates.

## What's next

1. **Post-Phase-0 consolidation (charter §6-A) — the main event now that Phase 0 is essentially done.** Three deliverables, each its own session: (a) comprehensive technical summary; (b) per-module flow diagrams (mermaid in `docs/diagrams/`, never one big piece); (c) **self-paced senior→lead exam** — organized by topic section (no time limit), each with written what/why/how + diagram-from-memory + code katas + a short viva, **open book**.
2. **Push the 1 unpushed commit.**
3. **Pending small items:** MVVM-command verdict ADR; migrate `groups_page_test.dart` to mocktail + retire hand-rolled `MockGroupsRepository` (keep `_FakeOutbox` as a fake — developer exercise); extension-types-for-ids (`GroupId`/`UserId`, charter §7-A candidate); backoff (deferred, see war stories); `logging_command_sender.dart` deletable if the swap example is no longer wanted; `.gitattributes` to pin `*.sh` to LF (optional hardening); **branch protection — deferred by plan tier (see "Where we are").**

## ADR state (real files in `docs/adr/`, 001–022)

001 Supabase+Firebase · 002 Riverpod(DI)+Bloc/Cubit+Command · 003 offline SSOT+outbox · 004 no cert pinning · 005 Drift · 006 LWW *(Proposed)* · 007 deep-link *(Open, Phase 4)* · 008 background sync · 009 error model · **010 go_router — Superseded by 020** · 011 package id · 012 toolchain · 013 config · 014 clock/uuid · 015 minSdk 26 · 016 iOS 16 · 017 import-boundary *(Deferred)* · 018 token-refresh ownership · 019 localization · 020 routing=auto_route · 021 CI/CD (Actions+Bitrise+fastlane) · 022 versioning/build-numbers (git commit count, CI-injected).

## Environment gotchas

- **Windows + PowerShell.** FVM SDK cache on `W:\fvm_cache`; sandbox uses `./.fvm/flutter_sdk/bin/flutter …`.
- **`flutter config --enable-native-assets` is set on this machine and in CI** — required by `sqlite3 5.x`. Any fresh machine/CI job needs it or APKs silently miss `libsqlite3.so`.
- **Line endings:** `LF will be replaced by CRLF` warnings — harmless.
- **Codegen committed** (Drift `.g.dart`, auto_route `.gr.dart`, json_serializable `.g.dart`, l10n `gen/`). Regen: `fvm dart run build_runner build --delete-conflicting-outputs`; l10n: `fvm flutter gen-l10n`; goldens: `fvm flutter test --update-goldens` (then eyeball the png).
- **Goldens:** CI asserts `goldens/ci/` only, with `diffThreshold: 0.001`; platform goldens local-only (gitignored); failure diffs in `test/**/failures/` (gitignored, uploaded as CI artifact on failure).
- **Conventions:** interface+impl in separate files; `abstract interface class` for contracts; `package:` imports in `lib/`; validate with analyze before moving on; l10n keys for every user-visible string (en/ms/zh); run-on-device command: `fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json`.
- **Analyzer-clash ledger:** riverpod_generator OUT (analyzer ^12 vs drift_dev ^13); freezed stable OUT (see above); auto_route, alchemist, json_serializable, retrofit_generator all fine; **mocktail + bloc_concurrency added, both clean** (no codegen).
