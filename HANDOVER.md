# Kongsi — Session Handover

> Temporary working doc to hand context to a fresh agent session. Safe to delete once absorbed.
> Last updated: 2026-07-20.

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

**Phase 0. Stages 0–10 complete. Walking skeleton: local slice + outbox/sync-stub DONE and device-verified. Blocked on the developer creating the real Supabase project.**

Branch `develop`, pushed, **CI fully green** (3 jobs). Branch protection on `main` still not enabled (developer-side GitHub setting). Working tree clean except this file.

Sandbox commands: `./.fvm/flutter_sdk/bin/flutter …` (fvm CLI not on sandbox PATH). Current state: analyze `--fatal-infos` clean, tests 11/11, format clean.

### Done since last handover (this session)

- **Stage 10 — global error capture:** `lib/bootstrap.dart` — one Talker; nets: `FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`, plus **`Bloc.observer = AppBlocObserver(talker)`** (net 4, `lib/app/app_bloc_observer.dart`). Three `main_*.dart` are one-liners calling `bootstrap(config)`. Verified with deliberate sync+async test crashes on device (buttons since removed). DoD box ticked.
- **Bootstrap owns a hand-built `ProviderContainer`** + `UncontrolledProviderScope` — startup code (seed, sync kick) reads the same graph as widgets. Overrides: appConfig, talker, commandRegistry.
- **Walking-skeleton local slice (`features/groups/`):** Drift `groups` table (schema v2) → `Group` entity (equatable) → `GroupsRepository` (abstract interface) → `DriftGroupsRepository` → `WatchGroupsUseCase` (stream) → `GroupsCubit` (subscribes; `await cancel()` in `close`) → `GroupsPage` (`@RoutePage`, switch expression + guard patterns, FAB). `features/home` deleted; route `/`→`GroupsRoute`. Dev-only seed (`features/groups/data/dev_seed.dart`) plants "Demo Group" if table empty.
- **Outbox + Command (GoF) write path:** `outbox` table schema v3 (autoincrement int id = FIFO, `textEnum<OutboxStatus>` pending|failed, attempts default 0). `Command` contract (`core/sync/command.dart`), `CreateGroupCommand` (json_serializable, in `features/groups/domain/commands/`). `createGroup` = **one transaction**: group insert + slip insert. `CreateGroupUseCase` mints id (uuid) + createdAt (clock).
- **Sync drain stub (`core/sync/`):** `SyncBloc` (first real Bloc; `on<SyncRequested>` → getPending → registry.decode → sender.send → delete; on failure: addError + recordFailure(+1 attempts in SQL) + **halt** to preserve FIFO). `CommandSender` interface + `LoggingCommandSender` stub. `CommandRegistry` **immutable**, built from declarative const catalog of named records in `lib/app/command_registrations.dart` (app layer sees features; core can't); provider throws unless overridden at bootstrap. One `SyncRequested` kick per launch, after `runApp`.
- **Create-group UI:** `CreateGroupDialog` (ConsumerStatefulWidget) + **presentation-flavor Command** (`lib/app/command/command.dart`) — MVVM command *pattern* implemented as a tiny `Cubit<CommandState>` (Idle/Running/Failure): double-tap guard, spinner-in-button, `on Exception` only (Errors propagate to nets), `addError` → observer → Talker. This was an explicit experiment; **verdict ADR still unwritten** (vs `isSubmitting` field in Cubit).
- **Tests:** 11 — round-trip serialization test (`test/core/sync/command_round_trip_test.dart`, guards payload compatibility), dialog-flow widget test, spinner/loaded/empty page tests, golden. `MockGroupsRepository` records `created` calls.
- **CI fixes learned the hard way:** platform goldens disabled on CI (`PlatformGoldensConfig(enabled: !isCI)` via `CI` env var); `CiGoldensConfig(diffThreshold: 0.001)` for cross-OS anti-aliasing (22px/0.01% Linux-vs-Windows edge noise); golden failure diffs uploaded as CI artifact on failure; `test/**/failures/` gitignored.
- **Charter §7-A added:** modern Dart checklist (versions 3.0–3.12) + mentoring rule.

## Key decisions / war stories this session (interview material — keep)

- **freezed evaluated and deferred:** every stable 3.x clashes (needs analyzer <11 / source_gen ^2; drift_dev needs analyzer ^13, retrofit_generator source_gen ^4). Only `4.0.0-dev` resolves — won't build foundations on a prerelease. Revisit at 4.0 stable. **equatable** added instead; hand-write `copyWith` where needed.
- **sqlite3 native-assets hunt:** first real DB query on device threw `dlopen libsqlite3.so not found`. Root cause: `sqlite3 5.x` ships its native lib via **Dart build hooks**, and Flutter 3.44 has `enable-native-assets` **off by default**; `sqlite3_flutter_libs` is an obsolete tombstone (developer caught this in its README). Fix: `flutter config --enable-native-assets` + clean rebuild (verified `libsqlite3.so` in APK) + the same config step added to all three CI jobs. **Machine-level flag = teammate/DoD trap — must be documented in README/setup eventually.**
- **First real migration bug:** v2→v3 upgrade forgot `createTable(outbox)`; device DB got stamped v3 without the table. Transaction rolled back correctly (no orphan group). Fix + wipe. Lesson: migration blocks accumulate append-only.
- **Command-pattern disambiguation:** GoF (serialized outbox commands) vs MVVM (button lifecycle wrapper, Flutter docs' version) — both now exist, deliberately, implemented on different machinery. Interview line material.
- **Registry = data over behavior:** developer's proposal (const list of named records) beat imperative `register()` calls; registry made immutable-at-construction; core provider throws, bootstrap overrides (appConfig pattern).
- **At-least-once + idempotency** chosen over exactly-once: delete-after-send; crash between = duplicate push made safe by client-generated ids.
- Failed slips currently stay `pending` and retry forever — **retry ceiling → `failed` status is a known TODO** (dead-letter problem), with backoff.
- Benign device log noise: `IllegalArgumentException ... surface control` from Android graphics layer during surface rebuilds — not ours, no crash, ignore unless it escalates.

## What's next

1. **Developer-side (blocking):** create real Supabase project — `groups` table per charter §9 (permissive/no RLS for now; RLS is its own later lesson) — and fill real `config/dev.json` (gitignored; examples committed).
2. **`SupabaseCommandSender`** — real sender impl; swap one provider line (`commandSenderProvider`). Then the money demo: create group in airplane mode → restore → relaunch → row appears in Supabase dashboard.
3. **Chunk C:** Firebase project → App Distribution → Bitrise + fastlane (ADR-021). Closes remaining Phase-0 DoD boxes.
4. **Pending small items:** MVVM-command verdict ADR; retry ceiling + backoff; connectivity-triggered `SyncRequested` (charter §8 EventChannel exercise, can wait); extension-types-for-ids design session (GroupId/UserId — flagged modern-Dart candidate); freezed note in a decision log; branch protection on `main`.
5. **End of Phase 0:** developer wants a **comprehensive technical summary of all of Phase 0** (what/why/decisions, interview-oriented) — agreed to write it in one dedicated session *after* DoD is fully ticked, sourced from ADRs + git log + the war stories above.

## ADR state (real files in `docs/adr/`, 001–021)

001 Supabase+Firebase · 002 Riverpod(DI)+Bloc/Cubit+Command · 003 offline SSOT+outbox · 004 no cert pinning · 005 Drift · 006 LWW *(Proposed)* · 007 deep-link *(Open, Phase 4)* · 008 background sync · 009 error model · **010 go_router — Superseded by 020** · 011 package id · 012 toolchain · 013 config · 014 clock/uuid · 015 minSdk 26 · 016 iOS 16 · 017 import-boundary *(Deferred)* · 018 token-refresh ownership · 019 localization · 020 routing=auto_route · 021 CI/CD (Actions+Bitrise+fastlane).

## Environment gotchas

- **Windows + PowerShell.** FVM SDK cache on `W:\fvm_cache`; sandbox uses `./.fvm/flutter_sdk/bin/flutter …`.
- **`flutter config --enable-native-assets` is set on this machine and in CI** — required by `sqlite3 5.x`. Any fresh machine/CI job needs it or APKs silently miss `libsqlite3.so`.
- **Line endings:** `LF will be replaced by CRLF` warnings — harmless.
- **Codegen committed** (Drift `.g.dart`, auto_route `.gr.dart`, json_serializable `.g.dart`, l10n `gen/`). Regen: `fvm dart run build_runner build --delete-conflicting-outputs`; l10n: `fvm flutter gen-l10n`; goldens: `fvm flutter test --update-goldens` (then eyeball the png).
- **Goldens:** CI asserts `goldens/ci/` only, with `diffThreshold: 0.001`; platform goldens local-only (gitignored); failure diffs in `test/**/failures/` (gitignored, uploaded as CI artifact on failure).
- **Conventions:** interface+impl in separate files; `abstract interface class` for contracts; `package:` imports in `lib/`; validate with analyze before moving on; l10n keys for every user-visible string (en/ms/zh); run-on-device command: `fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json`.
- **Analyzer-clash ledger:** riverpod_generator OUT (analyzer ^12 vs drift_dev ^13); freezed stable OUT (see above); auto_route, alchemist, json_serializable, retrofit_generator all fine.
