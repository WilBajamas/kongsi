# Project Charter — "Kongsi" (shared-expense app)

> **Working codename:** *Kongsi* (Malay/Hokkien: "to share"). Rename freely.
> **Author role:** You are acting as **Tech Lead / System Designer**, not just an implementer.
> **Purpose of this doc:** A portable, self-contained plan you paste into any new AI chat or hand to a coding agent so you never re-explain context. Companion to your `mobile_system_design_mindmap_v3.html`.

---

## 0. How to use this document (read this first in a new chat)

If you're an AI assistant or coding agent picking this up cold:

- This is a **learning + interview-showcase** project. The developer is building the **same app twice** — **Flutter first** (their strength), then **Android native / Jetpack Compose** (their growth area). They have **~5 yrs Flutter, ~3 yrs Android (older stack, weaker on Compose)**.
- **They have no Mac** — iOS cannot be run locally, but iOS **flavor/scheme scaffolding is in scope** and is validated via GitHub Actions macOS runners. Do not skip iOS setup; just don't assume it can be run locally.
- **They are frontend-only, no backend skills.** Backend = **Supabase (primary)** + **Firebase (platform services)**. The only "backend" they write is small declarative SQL (RLS) and one tiny serverless push trigger. Keep it minimal.
- Priorities, in order: **(1) learn end-to-end + tech-lead skills, (2) interview showcase for senior→lead, (3) side income.**
- Known weak spots to actively build up: sessions/tokens, FE security, CI/CD, notifications, Firebase Analytics events, OOP fundamentals, high-level "management" of end-to-end delivery, platform channels, MVI, Command pattern, Riverpod.
- Known strengths to leverage: widgets, **Bloc/Cubit** (still the standard in Malaysia — keep it central), Clean Architecture.
- **Working method:** plan first, implement later. Always propose the design and trade-offs before writing code.
- **Starting the project?** Go straight to **§6-A Project Foundations** — it is the ordered "how to start correctly" spec, with a Definition of Done. Do not begin features until its DoD is met.

### Current status (update this every session)

```
CURRENT PHASE : Phase 0 — Foundations (in progress) — full spec in §6-A
LAST DONE     : Stage 6 (the spine) complete — error model, logger, clock/UUID,
                dio network client, Drift DB, Riverpod composition root, theme
                from design tokens, l10n (en/ms/zh). ADRs 001–019 recorded.
NEXT ACTION   : Stage 7 — routing (deep-link-ready; ADR-010). Then Stage 8 test
                harness → Stage 9 CI skeleton → Stage 10 global error capture →
                walking skeleton.
BLOCKERS      : none
DECISIONS OPEN: ADR-006 (conflict resolution, Proposed), ADR-007 (deep-link
                provider — Phase 4 spike)
AI SECTION    : §17 "AI features (optional)" added — three tiers, Edge-Function
                proxy, plus five unnumbered future AI ADRs (§19); natural-
                language-entry flow left as an explicit future task.
```

---

## 1. Vision & problem

People who share costs (trips, housemates, couples) lose track of who paid for what and who owes whom. Kongsi lets a group log shared expenses, split them fairly, and settle up — **and it must work with no signal** (you add expenses on a trip, in a tunnel, on a plane) and reconcile later.

The "works offline, syncs cleanly, never double-charges" property is the heart of the product *and* the heart of the mobile-system-design story you'll tell in interviews.

## 2. Users & personas

- **Trip groups** — bursty usage, often offline, multi-currency later.
- **Housemates** — recurring monthly expenses, long-lived groups.
- **Couples** — 2 people, simplest split, highest frequency.

Assume a wide device range (old Android included), so battery/memory/app-size discipline matters.

## 3. Scope

### MVP (v1) — must exist
- Email/password + magic-link auth; session with silent token refresh.
- Create group; invite a member via link.
- Add / edit / delete an expense (payer, amount, split equally or by weighted share).
- Group balances ("who owes whom") + simple settle-up (record a payment).
- **Full offline support** for all core reads and writes, with background sync.
- Biometric app-lock.

### v2 — after MVP proves out
- Realtime live updates across devices.
- Deferred deep-linked invites + install attribution.
- Push notifications (expense added, you were paid).
- Receipt photos + on-device OCR of the total.
- Multi-currency with FX snapshot at expense time.

### Non-goals (explicitly out, state this in interviews)
- Building our own backend / auth server.
- Web app, tablet-optimized layout (until adaptive-layout phase).
- Real-money transfers / payment rails (we only *record* settlements).
- Group chat, comments, activity feed (nice-to-have, not core).

## 4. Functional requirements (prioritized)

| # | Requirement | Priority |
|---|---|---|
| F1 | Sign up, log in, log out, silent refresh, logout-everywhere | MVP |
| F2 | Create/rename/leave/delete a group | MVP |
| F3 | Invite a member (link) and join a group | MVP |
| F4 | Add/edit/delete expense with split (equal or weighted) | MVP |
| F5 | Compute per-member balances + simplified settle-up | MVP |
| F6 | Record a settlement (mark debt paid) | MVP |
| F7 | Offline create/edit + auto-sync on reconnect | MVP |
| F8 | Biometric lock on app open | MVP |
| F9 | Realtime updates across devices | v2 |
| F10 | Push notification on relevant group events | v2 |
| F11 | Attach receipt photo; OCR the total | v2 |

## 5. Non-functional requirements (with targets)

- **Startup:** cold start < 2s on mid-tier device.
- **Scrolling:** 60fps on expense lists (paginate; never load a whole group's history at once).
- **Offline:** 100% of core reads and writes available offline; UI reads **only** from the local DB.
- **Consistency:** eventual consistency across devices; **no duplicate expenses** ever (idempotency required).
- **App size:** Android download budget you set now (e.g. < 20 MB base) and defend.
- **Security:** refresh token never in plaintext; ledger DB encrypted; TLS enforced.
- **Reliability:** crash-free sessions > 99.5%.
- **Battery:** sync is coalesced/batched, not chatty; respect Doze.

## 6. High-level architecture (both codebases)

**Clean Architecture, feature-first, 3 layers.**

```
presentation  (widgets/Compose UI + state holders)
      │  depends on
domain        (entities, use-cases, repository interfaces) — pure Dart/Kotlin, no framework
      │  depends on
data          (repository impls, local DB, remote client, mappers, outbox)
```

- **Single Source of Truth = local database.** Remote (Supabase) syncs *into* local; UI never reads remote directly.
- **Repository pattern**: each repo has a local source (DB) and a remote source (Supabase), plus DTO↔domain mappers.
- **Modularization:** start feature-first folders in one package; extract to Melos packages (Flutter) / Gradle modules (Android) only when it earns its keep.
- **Layer boundaries are enforced, not suggested.** `domain` imports nothing from Flutter, `data`, or any package. Enforce with lint/import rules in CI — an architecture nobody enforces decays within three sprints.

---

## 6-A. Project foundations (Phase 0 in detail)

> **This section is the "how to start correctly" spec. Do it before feature #1.**

### The organizing principle

**Set things up in decreasing order of "cost to retrofit."**

Every decision sits somewhere between *irreversible* and *trivially changeable later*. A strict lint rule on day 1 costs nothing; the same rule at 20k lines costs a week of merge conflicts. An error model added late is one of the most painful refactors in existence. Features are cheap to add; foundations are expensive to change. **This single rule generates the entire order below** — when in doubt about sequencing, ask "what would hurt most to change in six months?" and do that first.

### Stage 0 — Decide before you type

Close these ADRs *before* `flutter create`. If you can't state each in one sentence with a reason, you're not ready to code.

- **Package / bundle ID** — `com.<domain-you-own>.kongsi`. **Irreversible-ish**: baked into signing, Firebase, Play/App Store listings. Changing it later is a migration, not an edit.
- **App name / codename.**
- **Flutter + Dart SDK versions** — pinned.
- **Min SDK / target platforms.**
- State mgmt, DI, DB, routing, error model — all locked (see ADRs §19).

### Stage 1 — Reproducible toolchain

- **Pin the Flutter SDK** (FVM or equivalent); commit the version file. "Works on my machine" is the earliest, dumbest source of pain.
- `pubspec.yaml` SDK constraints, `.gitignore`, `.editorconfig`.
- **Dependency policy:** decide pinning strategy (exact vs caret) and who bumps.

### Stage 2 — Create the project correctly

```bash
flutter create --org com.<yourdomain> --project-name kongsi \
  --platforms=android,ios --empty .
```

`--org` is the flag people get wrong and regret. Get it right once.

### Stage 3 — Quality gates (before the code they govern)

Highest-leverage early move — every line written after this is born compliant.

- `analysis_options.yaml` with a **strict** lint set (`very_good_analysis`, or `flutter_lints` + additions).
- Analyzer strict modes: `strict-casts`, `strict-inference`, `strict-raw-types`.
- `dart format --set-exit-if-changed` in CI; format-on-save locally.
- Commit conventions, PR template, and a written **Definition of Done**.

### Stage 4 — Flavors & typed config

Flavors per §14. Then the piece people miss:

- **One typed `AppConfig` object**, built once at startup and injected. **Never scatter `String.fromEnvironment` through feature code** — that's a config leak you'll untangle for months.

### Stage 5 — Architecture skeleton & enforced boundaries

Folder structure (§22) + the import/lint rules that enforce `presentation → domain → data`.

### Stage 6 — The spine (cross-cutting primitives)

Every feature leans on these, so they exist **before feature #1**. Several are load-bearing for correctness elsewhere in this charter.

- **Error model** — a `Result`/`Either` type + a `Failure` taxonomy (network, auth, validation, conflict, unknown). **Rule: exceptions never escape the data layer.** Retrofitting an error model is the single most painful refactor on this list — do it now.
- **Logger abstraction** — never bare `print`. Swappable sink (console in dev, Crashlytics in prod).
- **Network client** — `dio` + interceptor stack: auth (401 → refresh → retry), logging, error→`Failure` mapping, retry/backoff.
- **Local DB (Drift)** — with a **migration strategy from v1**, even when the schema is trivial. The first unplanned migration on real user data is a bad day.
- **Composition root** — one Riverpod provider graph where the object tree is assembled; environment-aware so dev can swap in fakes.
- **Clock + UUID abstractions** — *not optional*. The sync design (§11) depends on `client_id` (UUID) for idempotency and `updated_at` (clock) for last-write-wins. Injecting both makes sync **testable** and deterministic. These are load-bearing; unnamed dependencies here cause silent correctness bugs.
- **Theme from design tokens** — light/dark `ThemeData` generated from `kongsi_design_brief.md` §3 (incl. motion tokens).

### Stage 7 — Routing as a deep-link contract

`go_router` with typed routes, **deep-link-ready from day one**. The route table *is* the deep-link contract that Phase 4's invite flow depends on. Bolting deep links onto an ad-hoc navigation stack later is genuinely miserable — the routes are designed now even though the invite feature ships later.

### Stage 8 — Test harness (empty but real)

Create the folders and write **one of each kind now** — one unit, one widget, one golden — so the harness, fixtures, fakes, and golden tooling exist and run green. A test harness added later is a test harness never added.

### Stage 9 — CI skeleton on a hello-world app

Analyze → format-check → test → build Android → build iOS on a `macos-latest` runner. Branch protection on. Do this **while the app does nothing** — a pipeline that grows with the app stays green; one bolted on at month three is a two-week yak-shave.

### Stage 10 — Global error capture

Wire `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and a guarded zone at startup → routed to the logger (and later Crashlytics). Ten minutes now; without it, crashes go unrecorded until Phase 5.

### The golden move — build a walking skeleton (tracer bullet)

**Do not build the foundation in isolation and then start features.** Once the stages above are in place, build one paper-thin slice that runs **end-to-end through every layer**:

> Launch in `dev` flavor → stub auth → one screen → reads a single row from the **local DB** (repository → use-case → Cubit) → a background sync pushes it to **Supabase** → CI builds it → Firebase App Distribution puts it on your phone.

It does almost nothing. It proves *everything*: DI graph resolves, layers connect, error model flows, config loads per flavor, DB migrates, token refresh fires, CI signs and ships.

Every bug found here costs an hour. The same bug found after ten features costs a week. **Prove the architecture with the thinnest possible feature, then thicken it.**

### Phase 0 — Definition of Done

Phase 0 is complete when **all** of the following are true:

- [ ] A teammate can clone the repo, run **one command**, and get the `dev` flavor running on a device.
- [ ] `dev / staging / prod` all build (Android locally; iOS on CI macOS runner).
- [ ] A push to `main` runs analyze + format-check + tests, builds Android **and** iOS, all green.
- [ ] A staging build lands in **Firebase App Distribution** automatically.
- [ ] The **walking skeleton** runs end-to-end: local DB read → UI → background sync → Supabase.
- [ ] One unit, one widget, and one golden test exist and pass.
- [ ] Global error capture is wired and verified with a deliberate test crash.
- [ ] ADRs 001–010 are written and committed.

Nothing else. Do not start Phase 1 until every box is ticked.

### Anti-patterns — what NOT to do first

Guardrails, given a tempting mind map full of concepts:

- **Don't extract Melos packages yet.** Feature-first folders first; modularize when a real boundary hurts. Premature modularization is a tax with no payer.
- **Don't build the entire design system before a screen exists.** Tokens + ~5 components → one real screen → grow.
- **Don't install every package on the mind map.** Each dependency = app size + init cost + supply-chain liability. Add on demand, justify each.
- **Don't abstract for a second backend you'll never have.** Repository interfaces are sufficient.
- **Don't start the Compose port in parallel.** Flutter proves the domain first (Phase 8).
- **Don't skip the walking skeleton to "save time."** It *is* the time-saver.

---

## 7. State management & patterns (deliberate assignments)

**Flutter build**
- **Riverpod** → dependency injection / provider graph only (repositories, services, DB, clients). This replaces `get_it`. *This is where you learn Riverpod, in a bounded role that doesn't fight Bloc.*
- **Cubit** → simple screen/form state (AddExpense form, Profile, Settings).
- **Bloc** → event-driven flows (`AuthBloc`, `SyncBloc`). Bloc stays central — it's the local hiring standard and your strength.
- **Command pattern** → the offline **outbox**. Every mutation (AddExpense, EditExpense, Settle) is a serializable `Command` persisted to a queue; `SyncBloc` drains it. This gives you offline writes, retries, and a natural undo story in one pattern. *This is your OOP-fundamentals playground.*

**Android native build**
- **MVI** (immutable `UiState` + `Intent`/`Action` + reducer) with Compose — your growth goal.
- **Hilt** for DI, Coroutines/Flow, Room. Same Command/outbox concept in Kotlin.

> Interview line: "I used Riverpod for DI and Bloc/Cubit for feature state — separation of dependency-provision from state-management — and modeled every write as a Command so offline sync, retry, and undo fell out of one abstraction."

## 7-A. Modern Dart usage (deliberate practice, all phases)

Write idiomatic **modern Dart** on purpose — when a Dart 3.x construct fits, prefer it over the pre-3 idiom, and be able to say why. Reference: dart.dev language docs. The checklist (version introduced):

- **Sealed classes + exhaustive switches** (3.0) — error/state/event hierarchies.
- **Switch expressions & patterns** (3.0) — destructuring (`Group(:id)`), guard clauses (`when`), if-case.
- **Records** (3.0) — lightweight multi-value returns and declarative catalogs; prefer named fields.
- **Class modifiers** (3.0) — `abstract interface class` for contracts, `final class` for closed impls.
- **Extension types** (3.3) — zero-cost typed wrappers; candidate: id types (`GroupId` over raw `String`).
- **Digit separators** (3.6), **wildcard variables `_`** (3.7), **null-aware elements** (3.8) — small, use when natural.
- **Dot shorthands** (3.10) — `.running` where the context names the type.
- **Private named parameters** (3.12) — `required this._dep` constructor injection without initializer lists.

Mentoring rule: when reviewing or writing code, call out where a modern construct applies; each first use gets a one-line "why this over the old way."

## 8. Platform interop / method-channel track (learning goal)

Three genuine channel jobs, sequenced from simplest to most advanced. Write the **iOS (Swift) side as stubs** even though you can't run it, so the contract is symmetric; validate compilation on CI macOS runners.

1. **`MethodChannel` (request/response) — biometric app-lock.**
   Dart calls native → Android `BiometricPrompt` (Swift `LAContext` stub for iOS) → returns success/failure. Teaches: platform-specific implementation, typed args, error propagation across the bridge.

2. **`EventChannel` (streaming native→Dart) — connectivity stream.**
   Native `ConnectivityManager` emits network-state changes as a stream Dart listens to. Wire it into `SyncBloc` so "network available" triggers a queue drain. Teaches: long-lived streams, `StreamHandler`, lifecycle/cancellation.

3. **`Pigeon` (type-safe codegen) + on-device OCR.**
   Receipt OCR via ML Kit (Android). First build it with a raw `MethodChannel`, then **refactor to Pigeon** to feel why codegen beats stringly-typed channels. Teaches: the modern preferred interop approach.

- **`BasicMessageChannel`** — mention only (custom codec; rarely needed).
- **Dart FFI (optional stretch):** implement the debt-simplification algorithm in Rust/C and call via FFI — contrived but a real FFI vehicle. Mark optional.

## 9. Data model

Postgres (Supabase) is the source of record; the local DB mirrors a subset.

- **users**(id, display_name, email, avatar_url, created_at)
- **groups**(id, name, created_by → users.id, currency, created_at)
- **group_members**(group_id → groups.id, user_id → users.id, role, joined_at) — *M:N join*
- **expenses**(id, group_id, description, amount, currency, paid_by → users.id, created_by, created_at, updated_at, deleted_at, **client_id**)
- **expense_splits**(id, expense_id → expenses.id, user_id → users.id, share_weight | share_amount)
- **settlements**(id, group_id, from_user, to_user, amount, created_at, **client_id**)
- **invites**(id, group_id, token, expires_at, created_by)
- **outbox** *(local only)*: (id, command_type, payload_json, created_at, attempts, status)

Key rules:
- One group has many members; one member is in many groups (M:N).
- One expense has many splits; each split belongs to exactly one expense.
- **`client_id` (UUID generated on-device) is the idempotency key** — an offline-created row keeps its client_id through sync so re-sending never duplicates it. This is the single most important field for correctness.
- Soft-delete via `deleted_at` so deletes sync like edits.

## 10. Backend & API design

**Supabase (primary)**
- **Auth:** email/password + magic link. You receive an **`access_token` (JWT, ~1h)** and a **`refresh_token`**. The SDK auto-refreshes; you additionally implement an **HTTP interceptor** (on `dio`) that catches `401`, refreshes, retries — *this is the token exercise; build it by hand at least once.*
- **DB / API:** Postgres with auto-generated PostgREST endpoints; also `supabase-flutter` client.
- **Realtime:** subscribe to group row changes → upsert into local DB (v2).
- **Storage:** receipt images (v2).
- **RLS (Row-Level Security):** the only SQL you write. Examples to implement:
  - "a user can `select` expenses only for groups they're a member of"
  - "only the expense `created_by`/`paid_by` can `update`/`delete` it"
  This is your gentle, high-value backend-concept on-ramp (authorization).

**Firebase (platform services only)**
- **FCM** (push), **Crashlytics**, **Analytics** (events), **Remote Config**, **A/B**, **App Distribution**, **Test Lab**.
- **The one serverless glue:** sending a push when someone adds an expense needs a server trigger. Lowest-effort path: **Supabase Database Webhook / Edge Function → FCM HTTP v1**. Flag this as the single spot you touch serverless; it's a good, contained learning slice — don't let it balloon.

**Token mental model (quick ref)**
- *Access token* = short-lived pass, attached to every request, proves identity.
- *Refresh token* = long-lived secret, stored in Keystore/Keychain, mints new access tokens silently.
- *Session* = the lifecycle of that pair (issue at login → silent refresh → revoke at logout / logout-everywhere).

## 11. Offline-first & sync design

- **Reads:** UI reads local DB only. Always instant.
- **Writes (optimistic):** write to local DB **and** enqueue a `Command` in the outbox → return to UI immediately.
- **Sync:** `SyncBloc` drains the outbox when online (triggered by the connectivity `EventChannel`), with **exponential backoff** on failure.
- **Idempotency:** every write carries its `client_id`; server upserts on it → safe retries, no dupes.
- **Conflict resolution:** v1 = **last-write-wins** by `updated_at`. Document the harder cases (two offline edits of the same expense) and how you'd move to field-level merge in v2. *Being able to articulate this trade-off is the interview gold.*
- **Realtime (v2):** incoming changes upsert into local DB; UI reacts via the SSOT.

## 12. Background execution & services

The core guarantee of this app depends on background execution: **an expense or settle-up created offline must eventually reach the server even if the user backgrounds or force-kills the app.** An in-app listener (foreground-only `SyncBloc`) cannot promise that — the OS can kill your process any time. This is the same problem WhatsApp solves for an unsent message, applied to money. So background work is a first-class design concern, not a footnote under Performance.

**Design principle — one outbox, two drainers.** The `SyncBloc` (foreground) and the background worker drain the *same* outbox/Command queue (§11). The mechanism is unified; only the trigger differs (app open + connectivity event vs OS schedule). Don't build a second, parallel sync path.

**The kinds of background execution and how we use each:**

1. **Deferred, guaranteed work (primary).** `WorkManager` (Android) / `BGTaskScheduler` + `BGAppRefreshTask` (iOS), surfaced in Flutter via the `workmanager` plugin. Constraint-based (e.g. *requires network*), survives app-kill and reboot, OS-scheduled. Used to **drain the outbox** and run a **periodic reconcile**. It is *deferrable*, so it cooperates with Doze/App Standby instead of fighting them — the OS decides exactly when, you only declare constraints. This is the workhorse.

2. **Silent / data push → background sync (v2, Phase 5).** An FCM **data message** (not a notification) wakes a headless handler to pull the latest group changes so the user sees fresh data on next open. In Flutter this is `FirebaseMessaging.onBackgroundMessage` with a top-level `@pragma('vm:entry-point')` handler.

3. **Foreground service (Android) with a progress notification.** For guaranteed, *user-visible*, longer-running work that must not be killed — e.g. after a whole offline trip, "Syncing 42 expenses…" with progress, or uploading a batch of receipt images (Phase 6). iOS has no true equivalent; the closest is a finite `beginBackgroundTask` window — **note this asymmetry explicitly** (it's a real cross-platform design constraint worth raising in interviews).

4. **Off-main-thread compute (adjacent, not an OS service).** Dart **background isolates** / `compute()` (Flutter) and coroutine dispatchers (Android) for heavy work like debt-simplification on large groups or image compression. This is *threading*, not an OS background service — same mental bucket for the developer, different mechanism. Keep the distinction clear.

**Design within OS limits (cross-link §5, and Performance in the mind map):** Doze Mode, App Standby buckets, and background-execution limits mean you cannot assume exact timing or unlimited runtime. Rules: prefer deferrable constraint-based work, coalesce/batch rather than sync chattily, back off on failure, and never hold a wakelock you don't need.

**Platform-interop tie-in (learning slice).** Guaranteed background work and foreground services usually need native code. The `workmanager` plugin covers most cases, but a thin native `WorkManager` / `BGTaskScheduler` bridge is another genuine platform-channel exercise — a natural extension of the §8 track.

**iOS-without-a-Mac note:** scaffold the iOS side now — declare `BGTaskScheduler` identifiers in `Info.plist` and write the Swift handler stubs so the contract is symmetric and compiles on CI. You can't test actual scheduling without a device, so mark background behaviour as "validated on Android, iOS deferred" until you have hardware.

## 13. Security plan

- **Token storage:** refresh token in `flutter_secure_storage` (Keystore / Keychain); access token in memory / short-lived.
- **Encrypted ledger DB:** Drift + SQLCipher (or Isar encryption).
- **Biometric app-lock** (ties to MethodChannel #1).
- **Transport:** enforce TLS; Android **Network Security Config** to disallow cleartext. **No certificate pinning** — per 2025 OWASP/Google guidance it creates more outage risk than benefit for apps like this; if you demo pinning at all, do it behind a flavor flag as a *learning* exercise and explain why you'd disable it in prod. Prefer **Play Integrity API** for app/device integrity instead.
- **Privacy:** permission minimization; "delete my account / leave & purge group data" flow (GDPR-style); no amounts/PII in crash logs.

## 14. Environments & flavors (do this in Phase 0)

Three environments: **dev / staging / prod**. Each gets its own Supabase project (or schema) + Firebase app + base config + app-id suffix + app name/icon.

**Flutter**
- Entry points: `main_dev.dart`, `main_staging.dart`, `main_prod.dart`.
- Run with `--flavor dev --dart-define-from-file=config/dev.json` (modern 3.x approach; keeps Supabase URL/anon-key per env out of source).
- `.gitignore` the real config JSONs; commit `*.example.json`.

**Android**
- `productFlavors { dev; staging; prod }` with `applicationIdSuffix` + per-flavor `google-services.json`.

**iOS (scaffold only, no Mac)**
- Create schemes + `.xcconfig` per flavor. You can't run it, but **build it on a GitHub Actions macOS runner** to validate the config compiles. Keep a matching `GoogleService-Info.plist` per flavor.

## 15. CI/CD plan (GitHub Actions + Bitrise)

**Two hosts, split by responsibility (ADR-021).** GitHub Actions is the per-PR **verification gate** — fast, free, hand-written to learn the fundamentals. **Bitrise** is the **release/distribution** pipeline for the Mac-dependent signing + store delivery a no-Mac developer can't do locally, with **fastlane** inside it (`match` for iOS signing, `supply`/`pilot` for store uploads). The Bitrise/fastlane side is built when distribution first has a job (Firebase App Distribution, around the walking skeleton), not before.

Pipeline stages:
1. **Verify — GitHub Actions:** `flutter analyze`, `dart format --set-exit-if-changed`, unit + widget + **golden** tests, and per-flavor build-compile checks (Android on Linux, iOS compile-only on `macos-latest`).
2. **Build & sign — Bitrise:** per-flavor Android App Bundle + iOS archive, signed via **fastlane** + CI secrets.
3. **Distribute — Bitrise:** Firebase App Distribution (staging builds to testers).
4. **Integration:** run `integration_test` on **Firebase Test Lab** device matrix.
5. **Release — Bitrise + fastlane:** staged rollout on Play Console / TestFlight.

## 16. Observability

- **Crashlytics** — sanitized (no amounts, emails, or message content).
- **Analytics event taxonomy (define now):** `sign_up`, `login`, `group_created`, `invite_sent`, `invite_accepted`, `expense_added`, `expense_edited`, `settle_up_completed`, `sync_conflict_resolved`, `offline_write_queued`. Each with typed params. *This is your Firebase-events learning — design the taxonomy like a data schema.*
- **Remote Config** feature flags: `enable_realtime`, `enable_ocr`, `enable_biometric_lock`.
- **A/B test:** onboarding variant (e.g., invite-first vs create-group-first).

## 17. AI features (optional)

**Guiding principle — AI proposes, the user disposes, and the app does the math.** The model may parse, suggest, or phrase — but a **human confirms before anything writes to the ledger**, and every arithmetic operation runs in deterministic Dart, **never inside the LLM**. An expense app that silently saves a hallucinated number is *worse* than one with no AI at all: it launders a guess into a record of who owes whom, which is the one thing this product exists to get right. So AI is strictly an input-assistance and phrasing layer on top of the existing offline ledger — it never *becomes* the ledger.

These features are **optional and additive**. The app is fully functional with every one of them switched off (Remote Config flags, §16), and each tier degrades gracefully to the one below it.

### The three tiers (cost / architecture trade-offs)

- **Tier 1 — on-device, free: receipt OCR.** Already the Phase 6 Pigeon / ML Kit showcase (§8, §18 roadmap) — **cross-reference, not a new build.** Runs locally: no network hop, no per-call cost, no API key. The cheapest possible "AI," and it's already on the plan.
- **Tier 2 — classic ML / heuristics, cheap: auto-categorize + duplicate/anomaly detection.** Guess an expense's category from its description; flag a likely duplicate ("you added 'Grab' twice in three minutes") or an out-of-range amount. **No LLM required** — a lookup table, a small on-device classifier, or plain rules. Costs ~nothing to run and **degrades gracefully**: when it's unsure it simply stays quiet, and the user categorizes by hand exactly as they always could.
- **Tier 3 — LLM-powered: natural-language expense entry (flagship) + trip/group Q&A assistant (stretch).** "I paid 120 for dinner, split between me, Aisha and Jon" → a structured expense *proposal*. "How much does Jon still owe me for the Bali trip?" → an answer *computed from the ledger*. This is the only tier that costs per-call money and needs a server hop, so it sits behind the proxy below.

### The architecture unlock — a serverless proxy

Every LLM call routes through a **Supabase Edge Function proxy** that holds the provider API key **server-side**. **Never ship an API key in the app** — a key baked into a mobile binary is a key that has already leaked, and a leaked LLM key is a stranger spending your money. The app sends the user's text to the Edge Function; the function calls the model, validates the result, and returns it.

This is the **same serverless pattern as the existing Supabase→FCM push trigger** (§10, §12) — a *second instance* of a shape you're already building, not a new category of work. Two Edge Functions, one mental model.

### The two techniques to learn (the real learning arc)

The senior-level lesson here isn't "call an API" — it's *making an unreliable component safe to build on*:

1. **Structured / constrained output.** The model must return **schema-valid JSON** (matching the expense/split domain model, §9), which the app then **validates and rejects if malformed**. You never trust free text into your ledger — you parse it into a typed object and *throw it away* if it doesn't fit the schema or the business rules. This validation gate is what turns a probabilistic model into a dependable input source.
2. **Tool / function calling over local data.** For the Q&A assistant, the model does **not** get the ledger dumped into its prompt. It is given a set of *tools* (typed queries) and **chooses which one to run**; the app executes that query deterministically against the local DB and either hands back the rows or computes the answer itself. The model orchestrates; **Dart owns the data and does the arithmetic.** This keeps private financial data out of the prompt and keeps the numbers correct.

> **RAG / embeddings are deliberately out of scope.** Kongsi's data is small, structured, and per-user — a handful of groups and expense rows behind RLS. Tool-calling over the real tables beats embedding-and-retrieving a corpus you don't have. Don't reach for a vector DB to answer what is really a `WHERE` clause.

### Two caveats (read before starting Tier 3)

- **Model choice and pricing move fast.** Don't hard-code a model now. When you actually reach Tier 3, run a **short spike** to pick the current best-value model (see the model-selection entry in §19) and keep the choice behind config so it stays swappable.
- **Rate-limit at the proxy, early.** The Edge Function must enforce a **per-user rate limit from its first commit**. An LLM endpoint with no cap is an open invitation to run up a bill — by accident (a retry loop) or by abuse. It's cheap to add on day one and a nasty surprise if bolted on later.

### Natural-language expense entry — flow (to be drawn out)

> **Future task — do not design this in full now.** This subsection is a brief for a later session to expand into a proper sequence sketch. It is intentionally left as a placeholder.

The eventual flow must cover the whole path end-to-end and honor the guiding principle at both ends:

1. **User text input** — free-form ("I paid 120 for dinner, split with Aisha and Jon").
2. → **Edge Function proxy** — holds the key, enforces the per-user rate limit.
3. → **LLM with a constrained JSON schema** that matches the expense / split domain model (§9).
4. → **Validation** — parse into a typed domain object; **reject and fall back to the manual add-expense form** if the JSON is malformed or fails business rules.
5. → **Confirmation screen** — the user sees the parsed expense (payer, amount, split) and must **explicitly confirm**. Nothing is written before this.
6. → **into the existing add-expense Command / outbox path** (§7, §11) — the confirmed expense is enqueued as the *same* `AddExpense` Command a hand-typed one would produce. **Reuse the offline-write mechanism; do not build a parallel one.**

Two hard rules the sketch must state explicitly: the flow **ends in user confirmation**, and it **performs no arithmetic in the model** — any totals or split amounts are recomputed in deterministic Dart from the confirmed inputs. Mark clearly as a **future task**.

## 18. Delivery roadmap (each phase ships a slice + teaches specific concepts)

| Phase | Slice | Concepts you learn |
|---|---|---|
| **0. Foundations** | **See §6-A for the full spec.** Toolchain pinning → quality gates → 3 flavors + typed AppConfig → arch skeleton w/ enforced boundaries → spine (error model, logger, dio+interceptors, Drift+migrations, composition root, clock/UUID, theme) → deep-link-ready routing → test harness → CI skeleton → global error capture → **walking skeleton (tracer bullet)** | cost-to-retrofit ordering, flavors, CI/CD, error modeling, DI, testability, **proving architecture end-to-end before features** |
| **1. Auth & session** | Supabase auth, hand-built 401→refresh→retry interceptor, secure token storage, biometric lock (MethodChannel #1), logout-everywhere | **sessions/tokens**, secure storage, **first platform channel** |
| **2. Core ledger (offline)** | Groups, expenses, splits, balances, settle-up; local-first writes via outbox/**Command**; Cubit/Bloc feature state; debt-simplification algo | **offline-first**, SSOT, **Command pattern**, Bloc/Cubit, **OOP** |
| **3. Sync & realtime** | SyncBloc + backoff, idempotency, conflict resolution, Supabase Realtime, connectivity **EventChannel**; **background sync** (WorkManager / BGTaskScheduler drains the same outbox) | **sync/conflict**, **EventChannel**, realtime, **background execution**, Doze-aware scheduling |
| **4. Invites & deep links** | Invite links, deferred deep linking, install attribution | deep-link suite, attribution |
| **5. Notifications & observability** | FCM + Supabase→FCM trigger, **silent/data-push → background sync**, Analytics taxonomy, Crashlytics, Remote Config | **push**, **background wake**, **Firebase events**, observability |
| **6. Media & OCR** | Receipt photos, compression, storage, on-device OCR (MethodChannel→**Pigeon**); **foreground service** for batch image upload | media pipeline, native ML interop, Pigeon, **foreground service** |
| **7. Hardening & Pro** | Encrypted DB, Play Integrity, A/B onboarding, golden tests, Test Lab, staged rollout, Pro paywall (IAP) | security, testing at scale, **monetization** |
| **8. Native port** | Rebuild in Compose + MVI + Hilt + Room | **MVI**, modern Android, cross-stack fluency |
| **9. Stretch (optional)** | Home-screen widget (native + channel), FFI debt-simplification | widgets/wearables, FFI |
| **10. AI features (optional)** | Tiered, all gated behind "AI proposes, user disposes" (§17): Tier 1 receipt OCR (**already Phase 6**) → Tier 2 auto-categorize + duplicate/anomaly detection (classic ML / heuristics) → Tier 3 natural-language expense entry (**flagship**, LLM via Edge Function proxy) → trip/group Q&A assistant (**stretch**, tool-calling over the ledger) | **serverless proxy** (2nd Edge Function), **structured/constrained JSON output**, **tool/function calling**, safe-by-design LLM integration |

> ⚠️ **Phase 4 spike:** Firebase Dynamic Links was discontinued (shut down Aug 2025). Before committing a deep-link/attribution vendor, run a short spike to pick a current option (e.g. Branch, AppsFlyer, or a DIY deferred-link scheme). Verify status when you reach this phase.

## 19. Architecture Decision Records (fill these in as you go)

Keep a `/docs/adr/` folder. One file per decision. Starter list:
- **ADR-001** Backend = Supabase (data/auth/realtime) + Firebase (platform services). *Accepted.*
- **ADR-002** State: Riverpod for DI, Bloc/Cubit for feature state, Command for writes. *Accepted.*
- **ADR-003** Offline strategy = local DB SSOT + outbox/Command queue + idempotency key. *Accepted.*
- **ADR-004** No certificate pinning; enforce TLS + Network Security Config + Play Integrity. *Accepted.*
- **ADR-005** Local DB = ? (Drift vs Isar) — *Open. See note below.*
- **ADR-006** Conflict resolution = last-write-wins (v1), field-merge (v2). *Proposed.*
- **ADR-007** Deep-link/attribution provider. *Open — Phase 4 spike.*
- **ADR-008** Background sync = WorkManager (Android) / BGTaskScheduler (iOS) draining the **same** outbox as the foreground SyncBloc; foreground service for long, visible batch work. *Accepted.*
- **ADR-009** Error model = `Result`/`Either` + `Failure` taxonomy; exceptions never escape the data layer. *Accepted.*
- **ADR-010** Routing = `go_router`, typed routes, deep-link-ready from Phase 0 (route table = deep-link contract). *Accepted.*
- **ADR-011** Package/bundle ID = `com.<domain-you-own>.kongsi` — treat as irreversible. *Open — decide before `flutter create`.*
- **ADR-012** Toolchain = pinned Flutter SDK (FVM) + committed version file + dependency-bump policy. *Proposed.*
- **ADR-013** Config = single typed `AppConfig` built at startup from `--dart-define-from-file`; no `String.fromEnvironment` in feature code. *Accepted.*
- **ADR-014** Clock + UUID are injected abstractions (load-bearing for idempotency + LWW conflict resolution + testable sync). *Accepted.*
- **ADR-015 – 018** *(recorded in `/docs/adr/` ahead of this starter list — see that folder for full text)* — Android `minSdk 26`; iOS deployment target 16; automated import-boundary enforcement deferred; single token-refresh owner (Supabase SDK; the dio interceptor delegates). *Accepted / Deferred.*
- **ADR-019** Localization = gen_l10n (ARB) + intl; strings translated in the presentation layer only (lower layers emit typed errors/keys). *Accepted.*
*Future AI ADRs (from §17 — left unnumbered on purpose so real ADR files can keep taking the next free number; each gets a number when it's actually written):*

- AI features are optional, Remote-Config-gated, and bound by "AI proposes, user disposes": the model parses/suggests/phrases, a human confirms every ledger write, and all arithmetic runs in deterministic Dart. *Accepted (charter-level).*
- All LLM calls route through a Supabase Edge Function proxy that holds the provider API key server-side; no LLM key ever ships in the client, and the proxy enforces a per-user rate limit. *Accepted (charter-level).*
- LLM outputs must be constrained to a JSON schema and validated on-device; malformed or rule-violating responses are rejected and fall back to manual entry. *Accepted (charter-level).*
- The Q&A assistant uses tool/function calling over the local ledger (the model chooses a typed query, the app executes it) rather than dumping ledger data into the prompt; RAG/embeddings are out of scope. *Proposed.*
- LLM model selection is deferred to a short spike at Tier 3 (pricing/quality move fast); the chosen model is config-swappable, never hard-coded. *Open — Tier 3 spike.*

*ADR-005 recommendation:* **Drift** (relational SQL, mirrors your Postgres schema, supports SQLCipher encryption, joins make balance queries clean) over Isar/Hive. Isar is faster to write but the relational ledger benefits from SQL and the Postgres mental model helps in interviews. Your call — record the reasoning either way.

## 20. Risk register / weakness → mitigation map

| Your weak spot | Where it's built up | Mitigation / note |
|---|---|---|
| Sessions/tokens | Phase 1 | Hand-build the refresh interceptor once, don't just use the SDK |
| FE security | Phases 1, 7 | Encrypted DB + biometric + correct TLS stance (no pinning) |
| CI/CD | Phase 0 | Skeleton first, expand each phase |
| Notifications | Phase 5 | FCM + one serverless trigger; keep glue minimal |
| Firebase events | Phase 5 | Treat the event taxonomy as a schema you design |
| OOP fundamentals | Phase 2 | Command pattern + debt-simplification algorithm |
| MVI | Phase 8 | Native/Compose build |
| Riverpod | Phase 0 | DI-only scope, no overlap with Bloc |
| Platform channels | Phases 1, 3, 6 | Method → Event → Pigeon, increasing difficulty |
| Background services / execution | Phases 3, 5, 6 | WorkManager/BGTaskScheduler drains the outbox; foreground service for visible batch work; respect Doze |
| End-to-end "management" | Whole doc + §6-A | This charter + ADRs *is* the practice; §6-A is the "how to start correctly" spec |
| Project bootstrapping / foundations | Phase 0 (§6-A) | Cost-to-retrofit ordering; walking skeleton proves the architecture before features |
| Error modeling / OOP | Phase 0 spine + Phase 2 | Result/Failure taxonomy, then Command pattern |
| No Mac / iOS | Phases 0, CI | Scaffold iOS + build on CI macOS runners |
| AI integration (new learning area) | Phase 10 (optional) | Tiered rollout (on-device → heuristics → LLM); "user confirms + app does the math" safety rule; LLM behind an Edge Function proxy with a per-user rate limit, never a client-side key |

## 21. Glossary

- **Walking skeleton / tracer bullet** — the thinnest possible feature that runs end-to-end through every architectural layer, built to *prove* the foundation before features are added.
- **Cost-to-retrofit ordering** — the Phase 0 principle: set up decisions in decreasing order of how expensive they'd be to change later.
- **Composition root** — the single place where the object graph is assembled (here: the Riverpod provider graph).
- **Result / Failure** — the error model: operations return a Result (success or typed Failure) instead of throwing; exceptions never escape the data layer.
- **SSOT** — single source of truth (here: the local DB).
- **Outbox** — persisted queue of pending write Commands, drained by the sync engine.
- **Idempotency key** — client-generated UUID (`client_id`) ensuring retried writes don't duplicate.
- **Access / refresh token, session** — see §10.
- **RLS** — Row-Level Security; DB-enforced authorization.
- **MVI** — Model-View-Intent; unidirectional state via immutable UiState + Intents + reducer.
- **Command pattern** — encapsulate each action as an object (enables queue, retry, undo).
- **WorkManager / BGTaskScheduler** — OS-scheduled, deferrable, constraint-based background work that survives app-kill and reboot (Android / iOS).
- **Foreground service** — Android background work tied to a persistent notification, for guaranteed, user-visible long-running tasks; no true iOS equivalent.
- **Silent / data push** — an FCM message with no visible notification, used to wake the app and trigger a background sync.
- **Background isolate** — a Dart isolate for off-main-thread compute (`compute()`); threading, *not* an OS background service.
- **AI proposes, user disposes** — the rule governing all AI features: the model may parse, suggest, or phrase, but a human must confirm before anything writes to the ledger, and all arithmetic runs in deterministic Dart, never in the model.
- **Structured / constrained output** — requiring an LLM to return schema-valid JSON (matching a domain model), which the app validates and rejects if malformed, instead of consuming free-form text.
- **Tool / function calling** — giving an LLM a set of typed operations to choose from; the model picks which to invoke and the app executes it deterministically, keeping the underlying data and the arithmetic out of the model.
- **Edge Function proxy** — a Supabase serverless function that holds a provider API key server-side and mediates outbound calls (LLM, and the existing FCM push trigger), so no secret ships in the app; also the place per-user rate limits are enforced.

## 22. Suggested repo structure (Flutter)

```
lib/
  main_dev.dart / main_staging.dart / main_prod.dart
  app/            # app widget, router, theme/design tokens
  core/           # errors, network (dio + interceptors), result types, di (riverpod)
  features/
    auth/         # data/ domain/ presentation(bloc)/
    groups/
    expenses/
    sync/         # outbox, commands, sync_bloc, conflict resolution
    settle/
  platform/       # method/event channels, pigeon-generated, native bridge Dart side
config/           # dev.json, staging.json, prod.json (gitignored) + *.example.json
docs/adr/         # architecture decision records
android/ ios/     # per-flavor config; ios is scaffold-only for now
test/             # unit + widget + golden
integration_test/
.github/workflows/
```

---

### Immediate next step

Begin **Phase 0**. First two decisions/actions:
1. Lock **ADR-005** (local DB — recommend Drift) and record it.
2. Scaffold the repo with all **three flavors** (Flutter entry points + Android productFlavors + iOS scheme stubs) and a **CI skeleton** that runs `analyze` + tests and builds Android + iOS-on-macOS-runner.

Ask the assistant in your next session to help design Phase 0 in detail *before* writing code — same plan-first discipline.
