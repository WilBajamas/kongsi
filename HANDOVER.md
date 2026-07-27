# Kongsi — Session Handover

> Temporary working doc to hand context to a fresh agent session. Safe to delete once absorbed.
> Last updated: 2026-07-23.

## How to use this file

You (the next agent) are **mentoring** the developer through building **Kongsi** by hand, following the Phase 0 plan in `kongsi_project_charter.md` §6-A. Read this file, then skim `docs/adr/README.md` and the charter. The working-style rules load automatically from the project's `MEMORY.md` — follow them.

**One-line project summary:** offline-first shared-expense app (Flutter first, native Android later), built deliberately as a learning + senior→lead interview showcase. Full context in `kongsi_project_charter.md` + `kongsi_design_brief.md`. The Phase-0 story (what/why/war stories/decisions) is captured in `docs/technical-summary.md`; open gaps in `docs/learning-log.md`.

## Working style (auto-loaded from MEMORY.md + confirmed again this session)

- **Mentor, don't implement — but the balance shifted.** The developer now often delegates writing to the agent after a design walkthrough ("delegating to you"), then reads, questions, and reshapes the result. Still: walk through design decisions *before* code, explain what/why/how, plain simple English.
- **The developer asks deep "is this right?" questions** (e.g. mutable static state of `Bloc.observer`, all-purpose dialogs, Navigator vs auto_route pop). Give honest trade-off debates, not reassurance. They push back and propose alternatives — debate them properly (their record-list registry idea won over the agent's function design).
- **PowerShell** syntax, **`fvm` prefix** for developer-facing commands.
- **Respect their edits** — they rename (e.g. `fake_`→`mock_`, `watch_groups`→`watch_groups_use_case`/`WatchGroupsUseCase`), add their own warning comments, restructure. Never revert.
- **Comment style:** why not what; no ADR refs in code. This session they asked for *teaching-level* comments on the sync machinery specifically — that was an exception, on request.
- **Commits:** brief conventional messages, **NO AI signature/co-author trailer**. Split logical units. Developer sometimes commits themselves mid-flow — check `git log` before assuming.
- **Widget rules (stated explicitly):** lean, dumb widgets reacting to state; split when readability demands; no gratuitous `Builder`s; reuse via composition (slots) not configuration (flags); new widgets only with strict feature ownership.
- **Modern Dart is a standing goal** — charter §7-A has the checklist + mentoring rule: flag Dart 3.x opportunities as code is written; one-line "why over the old way" on first use.
- **No CLAUDE.md / .agent files.**

## Where we are

**Phase 0 — nearly done, three DoD boxes still open** (see "What's next"). The Post-Phase-0 consolidation (charter §6-A) *is* finished: the [technical summary](docs/technical-summary.md) and the seven per-module [flow diagrams](docs/diagrams/) are both done. Walking skeleton end-to-end (local + outbox + Supabase sync, device-verified online *and* offline); dead-letter + failure surfacing (ADR-024); connectivity trigger (native EventChannel, both steps); and **Chunk C done — a signed staging APK auto-distributes to Firebase App Distribution** via Bitrise + fastlane on push to `develop`, device-verified. Onboarding captured (bootstrap scripts + README).

Real Supabase **and Firebase** projects exist; `config/dev.json` filled (gitignored). `groups` table created with **RLS disabled** for the skeleton (re-enabled when auth lands — real policies need `auth.uid()`).

**Branch protection on `main` — DEFERRED (external constraint, not an oversight).** GitHub gates branch-protection/rulesets behind a paid tier for *private* repos, and this repo is Free + private. Revisit on going public or GitHub Pro; meanwhile the PR-into-`main` flow is followed by discipline.

Branch `develop`. Several commits **unpushed** — push `develop` to sync origin (and let CI confirm the iOS Swift stub compiles on the macOS runner). analyze `--fatal-infos` clean, tests **25/25**, format clean. Sandbox: `./.fvm/flutter_sdk/bin/flutter …` (fvm CLI not on sandbox PATH).

## What's next

**Three Phase 0 DoD boxes are still open** (charter §6-A). Everything else on that list is ticked.

1. ~~Verify the four error nets with a deliberate crash.~~ **DONE (2026-07-28)** — device-verified with a throwaway probe page, since removed (see git history if it's ever needed again). Each net now **tags its own name** when it hands off to the logger (`net 1 · FlutterError` … `net 4 · Bloc · <type>`), so a log line says which net caught it — without that they were indistinguishable, and you couldn't tell whether a given net ever fired at all.
2. **`prod` flavor has never been built.** CI builds `dev` only; Bitrise builds `staging`. `main_prod.dart` and `config/prod.json` exist but nothing has compiled that flavor — add it to `ci.yml`.
3. **Clone-from-zero never tested.** The bootstrap scripts exist but have never been run on a clean machine, which is the whole point of them (it's what catches machine-level traps like the native-assets flag).

Then, outside the DoD:

4. **Device-verify the upsert (ADR-024).** `resolution=merge-duplicates` is written but the duplicate-push path has never hit the real backend: send a slip, re-send the same one (comment out the `delete`), confirm it no longer returns 409. Until checked, at-least-once is written but unproven.
   - **The sync-failure UX is a deliberate placeholder** — satisfies "never fail silently" and nothing more. Open questions in the learning log under "Sync-failure UX".
   - Related open threads (base-version tracking, dependent-slip cascade) also in the learning log.
5. **Pending small items:** MVVM-command verdict (seeded in ADR-023, still Open); migrate `groups_page_test.dart` to mocktail + retire hand-rolled `MockGroupsRepository` (keep `_FakeOutbox` as a fake — developer exercise); extension-type ids (`GroupId`/`UserId`, charter §7-A candidate); enqueue-time sync kick + backoff (deferred, Phase 1); `logging_command_sender.dart` deletable if the swap example is no longer wanted; `.gitattributes` to pin `*.sh` to LF; **branch protection — deferred by plan tier (see "Where we are").**

## ADR state (real files in `docs/adr/`, 001–024)

Full index + status in `docs/adr/README.md`. Notable: **010 go_router — Superseded by 020** (auto_route) · 006 LWW *(Proposed — carries a 2026-07-27 addendum: its analysis misses the write-never-arrives loss case)* · 007 deep-link *(Open, Phase 4)* · 017 import-boundary *(Deferred)* · 023 MVVM-command verdict *(Open)* · **024 surface failed syncs** *(Accepted, not built — next task)*.

## Environment gotchas

- **Windows + PowerShell.** FVM SDK cache on `W:\fvm_cache`; sandbox uses `./.fvm/flutter_sdk/bin/flutter …`.
- **`flutter config --enable-native-assets` is set on this machine and in CI** — required by `sqlite3 5.x`. Any fresh machine/CI job needs it or APKs silently miss `libsqlite3.so`. (The bootstrap scripts handle it.)
- **Line endings:** `LF will be replaced by CRLF` warnings — harmless.
- **Benign device log noise:** `IllegalArgumentException ... surface control` from the Android graphics layer during surface rebuilds — not ours, no crash; ignore unless it escalates.
- **Codegen committed** (Drift `.g.dart`, auto_route `.gr.dart`, json_serializable `.g.dart`, l10n `gen/`). Regen: `fvm dart run build_runner build --delete-conflicting-outputs`; l10n: `fvm flutter gen-l10n`; goldens: `fvm flutter test --update-goldens` (then eyeball the png).
- **Goldens:** CI asserts `goldens/ci/` only, with `diffThreshold: 0.001`; platform goldens local-only (gitignored); failure diffs in `test/**/failures/` (gitignored, uploaded as CI artifact on failure).
- **Conventions:** interface+impl in separate files; `abstract interface class` for contracts; `package:` imports in `lib/`; validate with analyze before moving on; l10n keys for every user-visible string (en/ms/zh); run-on-device command: `fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json`.
- **Analyzer-clash ledger** (full version in `docs/technical-summary.md` §15): riverpod_generator OUT (analyzer clash with drift_dev); freezed stable OUT (only 4.0.0-dev resolves); auto_route, alchemist, json_serializable, retrofit_generator, mocktail, bloc_concurrency all fine.
