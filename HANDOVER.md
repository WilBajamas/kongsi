# Kongsi — Session Handover

> Temporary working doc to hand context to a fresh agent session. Safe to delete once absorbed.
> Last updated: 2026-07-21.

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

**Phase 0. Stages 0–10 complete. Walking skeleton now COMPLETE end-to-end — local slice + outbox + real Supabase sync, device-verified (create group → drain → row in Supabase, online *and* offline). Retry ceiling / dead-letter done. Connectivity trigger Step 1 (Dart) done; Step 2 (native EventChannel) is next.**

Real Supabase project exists; `config/dev.json` filled (gitignored). `groups` table created with **RLS disabled** for the skeleton (re-enabled when auth lands — real policies need `auth.uid()`).

Branch `develop`. **5 commits this session, NOT yet pushed** (HEAD is 5 ahead of `origin/develop`) — push to run CI. Branch protection on `main` still not enabled (developer-side GitHub setting). Working tree clean except this file.

Sandbox commands: `./.fvm/flutter_sdk/bin/flutter …` (fvm CLI not on sandbox PATH). Current state: analyze `--fatal-infos` clean, tests **18/18**, format clean.

### Done this session (2026-07-21)

- **Real Supabase sync — walking skeleton closed:** `SupabaseCommandSender` (dio → PostgREST `POST /rest/v1/{table}`, anon key in `apikey` + `Authorization`) replaced the logging stub via the one-line `commandSenderProvider` swap. `Command` gained `table` + `toRow()` (server shape, snake_case) kept **separate** from `toJson()` (outbox storage shape) so on-disk format and server schema evolve apart. Device-verified online *and* offline.
- **Retry ceiling + dead-letter (`core/sync/send_failure.dart`):** `SendFailure` sealed pair — `CommandRejected` (4xx, counts) vs `DeliveryFailed` (offline/timeout/5xx, doesn't). Sender classifies (4xx except 401/429 → rejected). `SyncBloc` counts only the slip's own fault and `markFailed`s after `_maxAttempts = 5`, so a poison slip stops blocking FIFO; offline never dead-letters a good slip. Permanent branch is `on Object` (covers undecodable slips too). New `OutboxRepository.markFailed`. Device-verified with a force-fail CHECK constraint (5 fails → 6th silent).
- **mocktail adopted** (dev dep, no codegen) + **charter §7-B** (mock for stub/verify, hand-rolled fake for stateful behaviour). Reference test `test/features/groups/groups_page_mocktail_reference_test.dart` shows when/thenAnswer/any/registerFallbackValue/verify+captureAny. `_FakeOutbox` deliberately stays a fake.
- **Connectivity trigger — Step 1 (Dart only):** `core/connectivity/` — `ConnectivityMonitor` interface, `ConnectivityStatus` enum, `StubConnectivityMonitor` (emits nothing). `SyncBloc` subscribes → fires `SyncRequested` on online transitions, cancels sub in `close()`; `on<SyncRequested>` now `droppable()` (bloc_concurrency) so launch + reconnect drains can't race. Wired via `connectivityMonitorProvider` (stub). **Behaviour unchanged today** (stub emits nothing) — Step 2 swaps in the native EventChannel.
- **Comment trim** across the sync system (why-only, no paragraphs). `LoggingCommandSender` kept and reframed as the documented example of the `CommandSender` swap seam (see comment on `commandSenderProvider`).
- **Tests: 18** (was 11) — +3 SyncBloc (retry ceiling + connectivity), +1 mocktail reference; round-trip guard still there.

### Foundations already in place (earlier sessions — now in code/ADRs)

Stages 0–10; global error capture (4 nets incl. `Bloc.observer`, `lib/bootstrap.dart`); hand-built `ProviderContainer` + `UncontrolledProviderScope`; local slice `features/groups/` (Drift `groups` v2 → `GroupsRepository` → `WatchGroupsUseCase` → `GroupsCubit` → `GroupsPage`); outbox schema v3 (autoincrement id = FIFO, `OutboxStatus` pending|failed, attempts) + GoF `Command` + immutable `CommandRegistry` (declarative catalog in `lib/app/command_registrations.dart`); `createGroup` = one transaction (group + slip); clock/uuid injected; `CreateGroupDialog` + presentation-flavor MVVM Command (`lib/app/command/`, **verdict ADR still unwritten**); dev seed; CI goldens config (platform goldens off on CI, `CiGoldensConfig(diffThreshold: 0.001)`). freezed deferred; **equatable** used.

## Key decisions / war stories (interview material — keep)

**This session (2026-07-21):**

- **Command→row mapping lives on the command (`table`/`toRow`), not a repository.** A remote repository would need a type-dispatch table coupling sync→features; keeping each command's destination on itself keeps the drain a generic pipe. Repository approach noted as the natural refactor if a command ever needs real remote logic.
- **`toJson` (outbox storage) vs `toRow` (server) kept separate on purpose** — welding them would let a server column rename break slips already queued on a user's disk.
- **Retry ceiling counts only "the slip's own fault" (4xx / undecodable), never transient/offline** — counting offline failures would dead-letter good slips after N offline launches. The real problems it solves: infinite retry loop + head-of-line blocking (one poison slip freezing the FIFO queue).
- **RLS 401 was proof, not failure:** the request reached PostgREST and was rejected only at the RLS gate → whole pipeline correct. RLS disabled for the auth-less skeleton (real policies need `auth.uid()`).
- **droppable transformer** adopted once there were two sync triggers (launch + reconnect), so overlapping drains can't race on the same slips.
- **mocktail over mockito** — no codegen, stays out of the analyzer-clash ledger; mock-vs-fake is a deliberate per-double call (§7-B).

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

1. **Connectivity trigger — Step 2 (native EventChannel):** the real `EventChannelConnectivityMonitor` wrapping `EventChannel('kongsi/connectivity').receiveBroadcastStream()`; Android Kotlin `StreamHandler` on `ConnectivityManager` (register/unregister a network callback); iOS Swift **stub** that compiles on the CI macOS runner. Then swap `connectivityMonitorProvider` (one line) and device-verify: airplane-mode → create → network on → drains **without relaunch**. (Charter §8 exercise 2; Step 1's Dart seam + tests already in place.)
2. **Chunk C:** Firebase project → App Distribution → Bitrise + fastlane (ADR-021). Closes remaining Phase-0 DoD boxes.
3. **Push the 5 unpushed commits** so CI runs (HEAD is 5 ahead of `origin/develop`).
4. **Pending small items:** MVVM-command verdict ADR; migrate `groups_page_test.dart` to mocktail + retire hand-rolled `MockGroupsRepository` (keep `_FakeOutbox` as a fake — developer exercise); extension-types-for-ids (`GroupId`/`UserId`, charter §7-A candidate); backoff (deferred, see war stories); `logging_command_sender.dart` deletable if the swap example is no longer wanted; branch protection on `main`.
5. **End of Phase 0 — consolidation (now specced in charter §6-A "Post-Phase-0 consolidation"):** (a) comprehensive technical summary; (b) per-module flow diagrams (mermaid in `docs/diagrams/`, never one big piece); (c) **one-week senior→lead exam** authored by the mentor — written what/why/how, diagram-from-memory, code katas, closing viva. Each its own session, after DoD is fully ticked.

## ADR state (real files in `docs/adr/`, 001–021)

001 Supabase+Firebase · 002 Riverpod(DI)+Bloc/Cubit+Command · 003 offline SSOT+outbox · 004 no cert pinning · 005 Drift · 006 LWW *(Proposed)* · 007 deep-link *(Open, Phase 4)* · 008 background sync · 009 error model · **010 go_router — Superseded by 020** · 011 package id · 012 toolchain · 013 config · 014 clock/uuid · 015 minSdk 26 · 016 iOS 16 · 017 import-boundary *(Deferred)* · 018 token-refresh ownership · 019 localization · 020 routing=auto_route · 021 CI/CD (Actions+Bitrise+fastlane).

## Environment gotchas

- **Windows + PowerShell.** FVM SDK cache on `W:\fvm_cache`; sandbox uses `./.fvm/flutter_sdk/bin/flutter …`.
- **`flutter config --enable-native-assets` is set on this machine and in CI** — required by `sqlite3 5.x`. Any fresh machine/CI job needs it or APKs silently miss `libsqlite3.so`.
- **Line endings:** `LF will be replaced by CRLF` warnings — harmless.
- **Codegen committed** (Drift `.g.dart`, auto_route `.gr.dart`, json_serializable `.g.dart`, l10n `gen/`). Regen: `fvm dart run build_runner build --delete-conflicting-outputs`; l10n: `fvm flutter gen-l10n`; goldens: `fvm flutter test --update-goldens` (then eyeball the png).
- **Goldens:** CI asserts `goldens/ci/` only, with `diffThreshold: 0.001`; platform goldens local-only (gitignored); failure diffs in `test/**/failures/` (gitignored, uploaded as CI artifact on failure).
- **Conventions:** interface+impl in separate files; `abstract interface class` for contracts; `package:` imports in `lib/`; validate with analyze before moving on; l10n keys for every user-visible string (en/ms/zh); run-on-device command: `fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json`.
- **Analyzer-clash ledger:** riverpod_generator OUT (analyzer ^12 vs drift_dev ^13); freezed stable OUT (see above); auto_route, alchemist, json_serializable, retrofit_generator all fine; **mocktail + bloc_concurrency added, both clean** (no codegen).
