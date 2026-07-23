# Learning Log

A running journal of the concepts worked through building Kongsi by hand, and
the gaps still open. Decisions live in the ADRs; this is the *why-I-now-
understand-it* companion — raw material for the Phase-0 technical summary and
exam (charter §6-A). Living doc; append as you go.

---

## Concepts worked through

### Dependency injection (Riverpod)

- **The composition-root override pattern** (`throw UnimplementedError()` + `overrideWith…` at bootstrap). A provider that can't build its own value declares itself and forces a value in from the top. Two *different* reasons, same fix:
  - **Timing** — `appConfigProvider`: the value doesn't exist until a flavor's `main` reads the config file at runtime.
  - **Layering** — `commandRegistryProvider`: the value exists (a `const` catalog) but core isn't *allowed* to import the app layer, so bootstrap injects it.
  Throw (not an empty default) so a forgotten override fails **loud and early**, not as a confusing crash later.
- **Providers are lazy.** They build on first read/watch, then cache. "Eager" is something *you* trigger by reading early (bootstrap does, for the seed + sync kick). `overrideWithValue` hands in an already-built value.
- **Riverpod vs `get_it`/`injectable`.** get_it is a service locator (you *pull*; no reactivity; manual dispose). Riverpod is a reactive graph (`watch` rebuilds; `autoDispose`; invalidation). Mapping: `registerLazySingleton` ≈ default provider, `registerFactory` ≈ new-each-read, `registerSingleton` ≈ eager. injectable is just codegen over get_it.

### Sync / offline architecture

- **Sync is a bounded subsystem, not scattered logic.** It's a generic pipe that knows nothing about features — it carries opaque commands. Its seams are interfaces (`CommandSender`, `OutboxRepository`, `CommandRegistry`). *Could* be its own package; shouldn't yet — the interfaces already give the logical boundary without the packaging tax.
- **Where command→row mapping lives.** On the command (`table` + `toRow()`), not a repository — so the drain stays a generic pipe. A remote repository would force a type-dispatch table that couples sync→features.
- **Two serialization shapes, on purpose.** `toJson` = outbox storage (on device); `toRow` = server wire shape. Kept separate so a server column rename can't break slips already queued on a user's disk.
- **The retry ceiling solves two problems:** an infinite retry loop *and* head-of-line blocking (one poison slip freezing a FIFO queue). Only the slip's own fault (4xx / undecodable) counts toward the ceiling; transient/offline failures halt without counting — otherwise being offline would dead-letter good data. Dead-letter (`failed` status) lets the poison slip step aside.
- **At-least-once + idempotency > exactly-once.** Delete-after-send; a crash in between just means one duplicate push, made safe by client-generated ids.
- **`droppable` transformer** — with two triggers (launch + reconnect), it stops overlapping drains racing the same slips.

### Testing

- **Mock vs fake (test-double taxonomy).** A *fake* has real, simplified behaviour (stateful stand-in — e.g. an in-memory outbox). A *mock* has none; you script calls and *verify interactions*. Choose per double: interaction check → mock; stateful behaviour → fake. **mocktail** (no codegen → stays out of the analyzer-clash ledger) over mockito.

### Dependency management — the analyzer ceiling

- **The analyzer version is not a knob you set — it's a ceiling your heaviest code-gen dependency sets.** `analyzer` is never a direct dependency; each generator (`drift_dev`, `json_serializable`, `auto_route_generator`…) pulls it in transitively, and pub resolves the *one* version that satisfies them all. `drift_dev` demands `analyzer ^13`, so **13 is the ceiling** everything else must fit under.
- **You can't "lower the analyzer" to fit more generators.** The only levers are: downgrade `drift_dev` (freezes the app's DB spine on an old version to house a testing/boilerplate convenience — priorities backwards), or a `dependency_overrides` that bypasses the *constraint* but not the *code*, so `build_runner` crashes on analyzer-13 APIs the forced-lower version lacks. Neither is worth it.
- **Re-checked empirically (2026-07-23, `pub add --dry-run`):** `mockito 5.7.0` now resolves clean — the clash cleared, but `mocktail` already covers stub/verify with no codegen, so still not adopted; `freezed` resolves **only** as `4.0.0-dev.3` prerelease (stable still clashes); `riverpod_generator` still fails version solving outright.
- **The real strategy: keep the generator count low.** Every code-gen dep is a hostage to the shared ceiling; choosing no-codegen tools (mocktail, bloc_concurrency, equatable) sidesteps the fights entirely.

### Platform interop (EventChannel)

- **EventChannel streams native→Dart.** A `StreamHandler` (`onListen`/`onCancel`) manages a long-lived subscription. Native callbacks arrive on a **binder thread**, but the `EventSink` must be touched on the **main thread** — hence the main-thread hop.
- **Connectivity ≠ reachability.** "Online" means a network exists, not that the server is reachable — so it's a *hint to try*, never a guarantee.
- **Symmetric contract.** The iOS side is a compiling Swift stub so the channel exists on both platforms and CI's macOS runner catches breakage, even though iOS can't be run yet.

### Versioning (ADR-022)

- **Version name vs build number.** Name (`x.y.z`, semantic, human, hand-bumped at release) vs build number (`versionCode`/`CFBundleVersion`, monotonic integer, machine identity of a binary). Stores reject a non-increasing build number.
- **Build number = git commit count, injected by CI.** Chosen because it's **CI-agnostic** — same commit → same number whether Actions or Bitrise builds. A per-host CI run number would collide across the two-host split (ADR-021).

### CI/CD

- **CI vs CD.** CI answers *"is the code good?"* (Actions: analyze/test/build). CD answers *"get the good build onto a device"* (Bitrise + fastlane → Firebase App Distribution). Different jobs, split by responsibility (ADR-021).
- **FAD is last-mile delivery.** It distributes a built APK; it does **not** need the Firebase SDK in the app. `firebase_core`/`google-services.json` are for *runtime* Firebase (Crashlytics/FCM), added later on demand.
- **Auth vs authz — the setup's sharpest lesson.** "Permission denied" from FAD was a **valid** key (authentication succeeded) for the **wrong service account on the wrong project** (authorization failed). The role needed: `roles/firebaseappdistro.admin`, on the correct project, API enabled.
- **Config-as-code.** `bitrise.yml` stored in the repo (version-controlled, reviewable) rather than clicked into a web UI.

### Reproducibility / onboarding

- **"Clone" is a reproducibility test, not a task.** It asks: can a from-zero checkout run, or is the app held together by undocumented setup on one machine ("works on my machine")? The `--enable-native-assets` flag is a **machine-level** trap; the bootstrap script captures that tribal knowledge.

### Repo hygiene

- **Branch protection is plan-gated.** GitHub rulesets need a paid tier for *private* repos. On a solo repo, requiring PR approvals **deadlocks** you (you can't approve your own PR) — set approvals to 0.
- **Shell scripts must stay LF.** CRLF in a `.sh` shebang breaks the interpreter on macOS/Linux; a `.gitattributes` `*.sh text eol=lf` pins it (not yet added — see gaps).

---

## Open gaps

Threads deliberately left open, or not yet exercised. Revisit before claiming a topic is "done."

### Deferred by design (recorded elsewhere)

- **iOS EventChannel is a stub** — no real `NWPathMonitor` impl; compiles only. (charter §8)
- **No real release signing** — release builds sign with the **debug** key; store release needs a proper signing config + keystore. (`android/app/build.gradle.kts` TODO)
- **RLS disabled** — no hand-written Row-Level-Security policies yet; needs auth (`auth.uid()`). (charter §10)
- **Branch protection deferred** — plan-tier constraint; PR-into-`main` by discipline for now.
- **Backoff deferred** — pairs with a retry timer that doesn't exist; launch/reconnect spacing suffices.
- **Multi-store / Huawei** — Huawei-without-GMS can't receive FCM push; a release-phase concern. (ADR-022)
- **freezed deferred** — stable still clashes with analyzer 13; only `4.0.0-dev.3` prerelease resolves (re-verified 2026-07-23). Tracked trigger: adopt at **4.0 stable** — it removes the hand-written `equatable` + `copyWith` boilerplate.
- **Automated import-boundary enforcement deferred** — (ADR-017).

### Not yet built / exercised

- **Sync has no post-write trigger.** Drains fire only on **app launch** + **connectivity-restored** — so a group/expense created while *already online* sits in the outbox until the next launch or network blip, **not immediately**. Needs an enqueue-time `SyncRequested` kick (cheap; lives in the use-case / presentation command, not the repository — `droppable` already guards overlap). Planned enhancement, **Phase 1**, bundled with the first real write feature (charter §11).
- **Auth** — still `NoAuthTokenProvider`. The hand-built dio 401→refresh→retry interceptor exists but has **never faced a real 401** (charter §10 says build it by hand at least once — half-done).
- **MVVM-command verdict ADR** — the presentation-flavor Command experiment (`lib/app/command/`) has no written conclusion vs an `isSubmitting` field.
- **Extension-type ids** — `GroupId`/`UserId` over raw `String` (charter §7-A candidate), not done.
- **Realtime + Storage** — v2 features, not started.

### Small housekeeping

- **`.gitattributes`** to pin `*.sh` to LF — not added (currently LF by luck of git defaults).
- **`logging_command_sender.dart`** — kept as the swap-seam example; deletable if that stops earning its place.
