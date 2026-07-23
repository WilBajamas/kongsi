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

**Phase 0 — essentially COMPLETE.** Walking skeleton end-to-end (local + outbox + Supabase sync, device-verified online *and* offline); retry ceiling / dead-letter; connectivity trigger (native EventChannel, both steps); and **Chunk C done — a signed staging APK auto-distributes to Firebase App Distribution** via Bitrise + fastlane on push to `develop`, device-verified. Onboarding captured (bootstrap scripts + README). Remaining: the Post-Phase-0 consolidation (charter §6-A: summary → diagrams → exam) — the **summary is done** (`docs/technical-summary.md`); **diagrams are next**.

Real Supabase **and Firebase** projects exist; `config/dev.json` filled (gitignored). `groups` table created with **RLS disabled** for the skeleton (re-enabled when auth lands — real policies need `auth.uid()`).

**Branch protection on `main` — DEFERRED (external constraint, not an oversight).** GitHub gates branch-protection/rulesets behind a paid tier for *private* repos, and this repo is Free + private. Revisit on going public or GitHub Pro; meanwhile the PR-into-`main` flow is followed by discipline.

Branch `develop`. Some recent **doc commits unpushed** — push `develop` to sync origin (and let CI confirm the iOS Swift stub compiles on the macOS runner). analyze `--fatal-infos` clean, tests **19/19**, format clean. Sandbox: `./.fvm/flutter_sdk/bin/flutter …` (fvm CLI not on sandbox PATH).

## What's next

1. **Post-Phase-0 consolidation (charter §6-A).** Deliverable (a) technical summary is **done**. Next: **(b) per-module flow diagrams** (mermaid in `docs/diagrams/`, never one big piece; sequence diagrams for flows, graphs for structure), then **(c) self-paced, topic-sectioned senior→lead exam** (no time limit, open book).
2. **Push unpushed `develop` commits** so CI runs.
3. **Pending small items:** MVVM-command verdict (seeded in ADR-023, still Open); migrate `groups_page_test.dart` to mocktail + retire hand-rolled `MockGroupsRepository` (keep `_FakeOutbox` as a fake — developer exercise); extension-type ids (`GroupId`/`UserId`, charter §7-A candidate); enqueue-time sync kick + backoff (deferred, Phase 1); `logging_command_sender.dart` deletable if the swap example is no longer wanted; `.gitattributes` to pin `*.sh` to LF; **branch protection — deferred by plan tier (see "Where we are").**

## ADR state (real files in `docs/adr/`, 001–023)

Full index + status in `docs/adr/README.md`. Notable: **010 go_router — Superseded by 020** (auto_route) · 006 LWW *(Proposed)* · 007 deep-link *(Open, Phase 4)* · 017 import-boundary *(Deferred)* · 023 MVVM-command verdict *(Open)*.

## Environment gotchas

- **Windows + PowerShell.** FVM SDK cache on `W:\fvm_cache`; sandbox uses `./.fvm/flutter_sdk/bin/flutter …`.
- **`flutter config --enable-native-assets` is set on this machine and in CI** — required by `sqlite3 5.x`. Any fresh machine/CI job needs it or APKs silently miss `libsqlite3.so`. (The bootstrap scripts handle it.)
- **Line endings:** `LF will be replaced by CRLF` warnings — harmless.
- **Benign device log noise:** `IllegalArgumentException ... surface control` from the Android graphics layer during surface rebuilds — not ours, no crash; ignore unless it escalates.
- **Codegen committed** (Drift `.g.dart`, auto_route `.gr.dart`, json_serializable `.g.dart`, l10n `gen/`). Regen: `fvm dart run build_runner build --delete-conflicting-outputs`; l10n: `fvm flutter gen-l10n`; goldens: `fvm flutter test --update-goldens` (then eyeball the png).
- **Goldens:** CI asserts `goldens/ci/` only, with `diffThreshold: 0.001`; platform goldens local-only (gitignored); failure diffs in `test/**/failures/` (gitignored, uploaded as CI artifact on failure).
- **Conventions:** interface+impl in separate files; `abstract interface class` for contracts; `package:` imports in `lib/`; validate with analyze before moving on; l10n keys for every user-visible string (en/ms/zh); run-on-device command: `fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json`.
- **Analyzer-clash ledger** (full version in `docs/technical-summary.md` §15): riverpod_generator OUT (analyzer clash with drift_dev); freezed stable OUT (only 4.0.0-dev resolves); auto_route, alchemist, json_serializable, retrofit_generator, mocktail, bloc_concurrency all fine.
