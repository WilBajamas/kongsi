# Kongsi — Session Handover

> Working doc that hands context to a fresh agent session. Keep it current; it is
> the first thing the next session reads.
> Last updated: 2026-07-28.

## How to use this file

You (the next agent) are **mentoring** the developer through building **Kongsi** by hand. Read this file, then skim `docs/adr/README.md` and the charter (`kongsi_project_charter.md`). The working-style rules load automatically from the project's `MEMORY.md` — follow them.

**One-line project summary:** offline-first shared-expense app (Flutter first, native Android later), built deliberately as a learning + senior→lead interview showcase. Full context in `kongsi_project_charter.md` + `kongsi_design_brief.md`. The Phase-0 story (what/why/war stories/decisions) is in `docs/technical-summary.md`; per-module flow diagrams in `docs/diagrams/`; open gaps and lessons in `docs/learning-log.md`.

## Working style (auto-loaded from MEMORY.md + confirmed over several sessions)

- **Mentor, don't implement — but the balance shifted.** The developer often delegates writing after a design walkthrough ("delegating to you"), then reads, questions, and reshapes the result. Still: walk through design decisions *before* code, explain what/why/how, plain simple English.
- **The developer asks deep "is this right?" questions** and finds real holes — the biggest correctness bug of Phase 0 (silent sync data loss, ADR-024) came from them interrogating the dead-letter path, not from a crash. **Give honest trade-off debates, not reassurance.** When they push back, debate properly; they are often right, and they will notice hedging.
- **Say when you're wrong, plainly, and say what's unverified.** Several claims in this project were documented in three or four places and never once executed. Do not describe unrun code as working.
- **PowerShell** syntax, **`fvm` prefix** for developer-facing commands.
- **Respect their edits** — they rename, trim comments, restructure. Never revert.
- **Comment style:** why not what; no ADR refs in code. `// !` prefix for genuine traps.
- **Commits:** brief conventional messages, **NO AI signature/co-author trailer**. Split logical units. Developer sometimes commits themselves mid-flow — check `git log` before assuming.
- **Widget rules:** lean, dumb widgets reacting to state; split when readability demands; no gratuitous `Builder`s; reuse via composition (slots) not configuration (flags); new widgets only with strict feature ownership.
- **Modern Dart is a standing goal** — charter §7-A checklist; flag Dart 3.x opportunities as code is written, one-line "why over the old way" on first use.
- **No CLAUDE.md / .agent files.** No exams (dropped 2026-07-27; see charter §6-A).

## Where we are

**Phase 0 is done bar one Definition-of-Done box.** The walking skeleton runs end to end (local write → outbox → Supabase), device-verified online *and* offline. Post-Phase-0 consolidation is complete: `docs/technical-summary.md` and seven per-module diagrams in `docs/diagrams/`.

Built and verified: dead-letter + user-facing failure surfacing (ADR-024) · connectivity `EventChannel` (native → Dart, both steps) · four global error nets (three of them actually fire — see below) · signed staging APK auto-distributing to Firebase App Distribution via Bitrise + fastlane on push to `develop` · CI building all three flavors, prod in release mode.

Real Supabase **and Firebase** projects exist; `config/dev.json` filled (gitignored). `groups` table has **RLS disabled** — real policies need `auth.uid()`, so this is Phase 1 work.

**Branch protection on `main` — DEFERRED (external constraint, not an oversight).** GitHub gates branch-protection/rulesets behind a paid tier for *private* repos, and this repo is Free + private. Revisit on going public or GitHub Pro; PR-into-`main` by discipline meanwhile.

Branch `develop`, pushed. analyze `--fatal-infos` clean, **25/25 tests**, format clean. Sandbox: `./.fvm/flutter_sdk/bin/flutter …` (fvm CLI not on sandbox PATH).

## Phase 0 is closed — the last box was waived

**Clone-from-zero was waived on 2026-07-28, not tested** (charter §6-A carries the waiver and its reasoning). A clean-room run needs a second machine or a VM with USB passthrough, and neither exists here.

Carry this consequence forward: **`tool/bootstrap.ps1` / `bootstrap.sh` have never been executed.** Treat them as unverified, not as a working onboarding path — they are exactly the shape of the three Phase-0 claims that turned out never to have run. The cheap partial guard (CI running the script instead of duplicating its steps) is on the table but not done; it needs FVM on the runner.

## Phase 1 — Auth & session (charter §18)

Scope: Supabase auth · the hand-built 401→refresh→retry interceptor facing a **real** 401 · secure token storage · biometric app-lock (**MethodChannel #1**, charter §8) · logout-everywhere.

Phase 1 also unblocks or settles several things left open on purpose:

- **`AuthInterceptor` has never seen a real 401.** It is written and unit-tested, with a refresh lock and a retry guard, but `NoAuthTokenProvider` means it has never fired in anger. Charter §20 says hand-build it once rather than lean on the SDK — that's done; this is where it earns its keep. See ADR-018 for who owns refresh.
- **RLS policies** can finally be written (they need `auth.uid()`).
- **Enqueue-time sync kick** — a write made while already online currently waits for the next launch or reconnect. Cheap to add (fire `SyncRequested` after a successful enqueue; `droppable` already guards overlap), bundled with the first real write feature.
- **MVVM `CommandCubit` verdict** (ADR-023) is judged at its *second* use site — Phase 2, not here, but keep it in mind.

## Also outstanding (not Phase 0 blockers)

1. **Device-verify the ADR-024 upsert.** `Prefer: resolution=merge-duplicates` is written but the duplicate-push path has never hit the real backend: send a slip, re-send the same one (comment out the `delete`), confirm it no longer returns 409. Until checked, at-least-once is written but unproven.
2. **`SyncProblemsBanner` is an explicit stopgap** — it satisfies ADR-024's "never fail silently" and nothing more, and is meant to be **replaced, not grown**. Its own doc comment says so; open questions in the learning log under "Sync-failure UX". The deepest one: the banner can't name *which* change failed, because outbox slips carry an opaque payload and can't describe themselves — fixing that is a core-sync change, not a UI one.
3. **Error net 2 never fires.** `PlatformDispatcher.onError` receives nothing, because `bootstrap` wraps the whole app in `runZonedGuarded` and the zone handler claims everything first. Left as-is deliberately; note that since Flutter 3.3 net 2 is the *recommended* catch-all and the zone is the legacy approach, so this setup has the legacy net doing the work. Changing it needs its own measurement, not an assumption.
4. **Kotlin Gradle Plugin deprecation.** Every Android build warns it "will cause build failures in future versions of Flutter" — [migration guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers). Harmless today, a dated fuse that will go off on some future Flutter bump.
5. **Deeper sync threads, all recorded in the learning log:** no base-version tracking (so a failed change can't be rolled back *in principle*, and ADR-006's LWW can't detect a stale write) · dependent-slip cascade after a dead-letter (harmless until Phase 2 adds dependent commands) · exponential backoff (needs a retry timer that doesn't exist).
6. **Small items:** migrate `groups_page_test.dart` to mocktail + retire the hand-rolled `MockGroupsRepository` (keep `_FakeOutbox` as a fake — developer exercise) · extension-type ids (`GroupId`/`UserId`, charter §7-A candidate) · `logging_command_sender.dart` deletable if the swap-seam example stops earning its place · `.gitattributes` to pin `*.sh` to LF.

## ADR state (real files in `docs/adr/`, 001–024)

Full index + status in `docs/adr/README.md`. Notable: **010 go_router — Superseded by 020** (auto_route) · **006 LWW** *(Proposed — carries a 2026-07-27 addendum: its analysis misses the write-never-arrives loss case, and base-version tracking is its likely successor)* · **007** deep-link *(Open, Phase 4)* · **017** import-boundary *(Deferred)* · **018** token-refresh ownership *(relevant to Phase 1)* · **023** MVVM-command verdict *(Open — verdict at 2nd use site, Phase 2)* · **024** surface failed syncs *(Accepted and built)*.

## A pattern worth carrying forward

Three separate times in Phase 0, something was documented in several places and had **never been executed**: the PostgREST upsert header (so at-least-once was aspirational for the whole phase), the four error nets (one of which turned out to be dead), and the idempotency guarantee that depended on the header. Each was found by *deliberately running the thing*, not by review.

The rule that came out of it: **a guarantee that lives in a design doc but not in a line of code isn't a guarantee.** For any claim of that shape, ask which code enforces it and whether that path has ever actually run.

## Environment gotchas

- **Windows + PowerShell.** FVM SDK cache on `W:\fvm_cache`; sandbox uses `./.fvm/flutter_sdk/bin/flutter …`.
- **`flutter config --enable-native-assets` is set on this machine and in CI** — required by `sqlite3 5.x`. Any fresh machine/CI job needs it or APKs silently miss `libsqlite3.so`. (The bootstrap scripts handle it.)
- **Line endings:** `LF will be replaced by CRLF` warnings — harmless.
- **Benign device log noise:** `IllegalArgumentException ... surface control` from the Android graphics layer during surface rebuilds — not ours, no crash; ignore unless it escalates.
- **Codegen committed** (Drift `.g.dart`, auto_route `.gr.dart`, json_serializable `.g.dart`, l10n `gen/`). Regen: `fvm dart run build_runner build --delete-conflicting-outputs`; l10n: `fvm flutter gen-l10n`; goldens: `fvm flutter test --update-goldens` (then eyeball the png).
- **Goldens:** CI asserts `goldens/ci/` only, with `diffThreshold: 0.001`; platform goldens local-only (gitignored); failure diffs in `test/**/failures/` (gitignored, uploaded as CI artifact on failure).
- **Widgets built in `MaterialApp.builder` sit ABOVE the Navigator** — no `Tooltip`, `SnackBar`, or popup menu there (they look up an `Overlay` and throw at build time), and navigation must go through the router's `navigatorKey`. `SyncProblemsBanner` lives there; both constraints are commented in place.
- **Widget tests:** `pumpEventQueue()` **deadlocks** inside `testWidgets` (fake-async zone). For stream → bloc → widget, use `tester.runAsync(...)` then `pump()` — see `test/app/sync_problems/sync_problems_banner_test.dart`.
- **Conventions:** interface+impl in separate files; `abstract interface class` for contracts; `package:` imports in `lib/`; validate with analyze before moving on; l10n keys for every user-visible string (en/ms/zh); run-on-device: `fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json`.
- **Analyzer-clash ledger** (full version in `docs/technical-summary.md` §15): riverpod_generator OUT (analyzer clash with drift_dev); freezed stable OUT (only 4.0.0-dev resolves); auto_route, alchemist, json_serializable, retrofit_generator, mocktail, bloc_concurrency all fine.
