# Kongsi — Phase 0 Technical Summary

This is the plain-English story behind Kongsi's design.

- The **[ADRs](adr/README.md)** record each decision (the formal "we chose X").
- The **[learning log](learning-log.md)** records what I learned along the way.
- **This file** ties them together for interviews: **what** was built, **why**,
  and **what we chose *not* to do**.

It keeps things short and links to the ADRs instead of repeating them, so it
stays correct when an ADR changes. Diagrams are a separate deliverable and will
live under `docs/diagrams/`.

---

## 1. The pitch

> **In one line:** Kongsi is a bill-splitting app that fully works without
> internet — and that one rule shapes almost every design choice here.

**What it is.** Kongsi lets people share costs — split a bill, see who owes whom,
settle up. It's built by hand as a learning project and a senior→lead interview
showcase. Flutter first, native Android later, both using the same design.

**The one rule that matters most: offline-first.** The app works with no network
at all. Every change is saved on the phone first, then synced later when there's a
connection. This single rule is the reason behind most of the hard parts in this
document:

- the **phone's local database is the source of truth**, not the server;
- every change is saved as a **queued command** to sync later;
- syncing aims for **"at least once,"** not "exactly once" (more in §5).

**Phase 0 built a skeleton, not features.** Instead of building screens, Phase 0
built **one thin path, end to end**: create a group → save it locally → queue it →
sync it to the real server → and ship a signed test build automatically.

Why do it this way? Because the parts that are **expensive to change later** are
the wiring, not the screens — how things connect (DI), how sync works, how errors
flow, how the database upgrades, how releases go out. Prove those on one tiny
feature, and every real feature later gets a spine that already works.

---

## 2. Architecture at a glance

> **In one line:** each feature is a vertical slice with the same simple layers;
> two shared systems (DI and sync) cut across all of them.

**The layers.** A feature is a top-to-bottom stack. A request flows down through
the same predictable layers every time:

| Layer | Job | Example |
|---|---|---|
| **Page** | A simple widget that just shows the state | `GroupsPage` |
| **Bloc / Cubit** | Holds the screen's state | `GroupsCubit` |
| **Use case** | One clear action, unaware of storage | `WatchGroupsUseCase` |
| **Repository** | The data contract; hides the database | `GroupsRepository` |
| **Database** | The local source of truth (Drift) | `groups` table |

**Two systems cut across every feature:**

- **Dependency injection (DI)** connects the whole graph — it hands each layer the
  things it needs. **Riverpod does DI only** (repositories, services, database,
  clients) — *not* screen state. This keeps it in a small, clear role that doesn't
  clash with Bloc ([ADR-002](adr/ADR-002-state-management.md)). See §3.
- **Sync** is its **own self-contained system**, not logic sprinkled around. It's a
  plain pipe that knows nothing about features — it just carries sealed commands
  from the queue to the server. Its edges are interfaces (`CommandSender`,
  `OutboxRepository`, `CommandRegistry`). See §5.

**The write path is where offline-first shows up.** Saving a change does **two
things in one transaction**:

1. update the local database, and
2. add a queued command to sync later.

Both happen together or not at all. So the action that updates the screen also
records "this needs to sync" — one can't happen without the other. `SyncBloc`
drains that queue later.

**Three rules keep the layers clean:**

- **Contract and code are separate files** — every contract is an
  `abstract interface class`.
- **The core cannot import the app layer.** When the core needs something the app
  owns (the command catalog), the app hands it *down* at startup (see §3).
- **Text the user sees is translated** in the top layer only
  ([ADR-019](adr/ADR-019-localization.md)).

*(A diagram for each module — startup/DI, sync, the groups slice, network, and the
database — will live in `docs/diagrams/` as the next deliverable.)*

---

## 3. Dependency injection & the composition root

> **In one line:** one place at startup builds the whole object graph; when a
> layer can't build something itself, it says so loudly and lets the top hand it
> down.

**What Riverpod does here.** Riverpod is the tool that *provides* objects — it
gives each part of the app the repositories, services, database, and clients it
needs, all wired in one graph ([ADR-002](adr/ADR-002-state-management.md)). It
does **not** hold screen state; that's Bloc/Cubit's job (§4).

**The override pattern (the important idea).** Some providers can't build their
own value. They declare themselves with a `throw UnimplementedError()` and the
real value is forced in from the top at startup (`overrideWith…`). There are
**two different reasons** to do this, same fix:

| Reason | Example | Why it can't self-build |
|---|---|---|
| **Timing** | `appConfigProvider` | The config file isn't read until a flavor's `main` runs. The value doesn't *exist* yet. |
| **Layering** | `commandRegistryProvider` | The value exists (a `const` list), but the core layer isn't *allowed* to import the app layer, so the app injects it downward. |

**Why `throw`, not a safe default?** So a forgotten wiring fails **loudly and
early** — right at startup — instead of turning into a confusing crash deep in a
feature later.

**Providers are lazy.** A provider builds its value the first time it's read, then
caches it. "Eager" isn't a setting — it's just *you* choosing to read something
early. Startup does exactly that on purpose (to seed data and kick off the first
sync).

**Why Riverpod and not `get_it`?**

- `get_it` is a **service locator** — you *pull* objects out of a global box.
  No reactivity, manual cleanup.
- Riverpod is a **reactive graph** — `watch` rebuilds when things change,
  `autoDispose` cleans up, and you can invalidate to force a refresh.

**Rejected: `riverpod_generator`.** It would generate provider code for us, but
it needs a newer analyzer than `drift_dev` allows — a version clash. Since Drift
is core to the app, the code generator loses. We write providers by hand instead.
(This is one entry in the "analyzer-clash ledger" — see the decisions table in
§15.)

---

## 4. State-management stack

> **In one line:** three tools, three clear jobs — Riverpod provides, Bloc/Cubit
> holds state, Command represents a write.

**One rule: separate "providing things" from "holding state."** Each tool owns one
job, so they never fight ([ADR-002](adr/ADR-002-state-management.md)):

| Tool | Job | Example |
|---|---|---|
| **Riverpod** | Provide objects (DI, §3) | repositories, DB, clients |
| **Cubit** | Simple screen/form state | a form's fields |
| **Bloc** | Event-driven flows | `SyncBloc` |
| **Command** | Represent one write as an object | `CreateGroupCommand` |

**Two patterns share the name "Command" — on purpose.** This trips people up, so
it's worth stating clearly. Kongsi has **both**, built on different machinery:

- **GoF Command (the outbox one).** A write is turned into a saved, serialisable
  object placed in the outbox queue, then drained to the server later. This is
  the offline-sync workhorse (§5).
- **MVVM Command (the button one).** A small wrapper around a button's lifecycle
  (is it running? can it run?) from the Flutter team's own guidance. It lives in
  the presentation layer and has nothing to do with sync.

Same word, two jobs. Being able to name the difference is a small interview win.

> **Interview line:** "I used Riverpod for DI and Bloc/Cubit for feature state —
> keeping *providing dependencies* separate from *managing state* — and modelled
> every write as a Command, so offline sync, retry, and undo all fall out of one
> idea."

*(Open thread: whether the MVVM Command earns its place over a plain
`isSubmitting` flag is still undecided — the verdict is taken at its second use
site in Phase 2. Written up in [ADR-023](adr/ADR-023-mvvm-command-verdict.md).)*

---

## 5. Offline-first & the sync/outbox subsystem

> **In one line:** every write is saved locally *and* queued, then a generic pipe
> drains that queue to the server — built to send **at least once** and never
> duplicate.

This is the heart of the app. Everything here follows from one promise: **the app
works with no network, and nothing gets lost or double-charged.**

**Sync is its own self-contained subsystem.** It's a plain pipe that carries
sealed commands from the outbox to the server. It knows **nothing** about groups
or expenses — it just moves opaque objects. Its edges are interfaces
(`CommandSender`, `OutboxRepository`, `CommandRegistry`), so it *could* become its
own package one day, but doesn't need to yet — the interfaces already draw the
line ([ADR-003](adr/ADR-003-offline-strategy.md)).

**The write path (recap from §2).** A mutation does two things in **one
transaction**: update the local database *and* enqueue a serialised `Command` in
the outbox. `SyncBloc` drains the queue later. Both happen together or not at all.

### At-least-once, not exactly-once

The queue aims to deliver each command **at least once**, and leans on the
**idempotency key** (`client_id`, a UUID made on the device) to make repeats safe:

- Send the command → on success, delete it from the outbox.
- If the app crashes *after* sending but *before* deleting, the command is sent
  again on next drain — a **duplicate push**.
- That's fine, because the server **upserts on the client-generated id**: the same
  id can't create a second row.

**The upsert has to be asked for, and for a long time it wasn't.** PostgREST only
upserts when the request carries `Prefer: resolution=merge-duplicates`; the sender
was sending `return=minimal` alone, so a duplicate push came back **409** and the
classifier read it as a permanent rejection. The design was right and written down
in three places — but the header that enforced it didn't exist, so the guarantee was
aspirational for the whole of Phase 0. Fixed 2026-07-27 alongside
[ADR-024](adr/ADR-024-surface-failed-syncs.md). **Still unverified on device:** the
crash-between-send-and-delete path has never been run against the real backend.

The lesson generalises: *a guarantee that lives in a design doc but not in a line of
code isn't a guarantee.* For any claim of this shape, ask which code enforces it and
whether that path has ever actually run.

Why not exactly-once? Because true exactly-once delivery is famously hard (and
often impossible) across an unreliable network. "At-least-once + idempotency" gets
the same *result* — no duplicates — with far less machinery.

### Two serialisation shapes, on purpose

A command is written out in **two different shapes**, kept separate deliberately:

| Method | Shape | Lives where |
|---|---|---|
| `toJson()` | outbox storage format | on the device's disk |
| `toRow()` | server wire format (snake_case) | sent to PostgREST |

Why split them? So a **server column rename can't break commands already sitting
in a user's outbox.** The on-disk format and the server schema are allowed to
change independently.

### Where command→row mapping lives

Each command answers two questions about itself — **"which table?"** and **"what
row?"** — through `table` and `toRow()`:

```dart
// create_group_command.dart
String get table => 'groups';
Map<String, dynamic> toRow() => {'id': groupId, 'name': name, /* … */};
```

The sender then uses both in **one generic line**, without knowing what a group
is:

```dart
// supabase_command_sender.dart
await dio.post('/rest/v1/${command.table}', data: command.toRow());
```

So `SupabaseCommandSender` builds `POST /rest/v1/groups` with that row — but only
ever sees "a command has a `table` and a `toRow()`." **Add a new command type and
the sender needs zero changes.**

The alternative would be a central `switch (command) { case CreateGroup: … }`
*inside* the sender. That switch would force `core/sync` to import every feature —
sync depending on groups, expenses, settle — and the generic pipe would rot into
something that knows the whole app. Putting the mapping **on the command** flips
it: the feature depends on sync (fine, it's the lower layer), and sync stays blind
to features. *(If a command ever needs real remote logic beyond a row write, a
repository is the natural refactor — noted, not built.)*

The full round trip: enqueue stores `toJson()` → on drain, `CommandRegistry`
rebuilds the typed command from its stored `command_type` + payload → the sender
reads `table` / `toRow()`. Sender and registry are both generic; only the command
knows its own shape.

### Dead-letter, and telling the user

A naive queue has two failure traps:

1. **Infinite retry loop** — a command the server will *always* reject keeps
   retrying forever.
2. **Head-of-line blocking** — because the outbox is strict FIFO, one bad command
   at the front **freezes every good command behind it.**

**The idea that solves both — sort failures by whose fault they are.** They're split
by a sealed pair, `SendFailure`:

| Type | Cause | Permanent? |
|---|---|---|
| **`CommandRejected`** | 4xx — the server refused *this* command (bad data) | **Yes** |
| **`DeliveryFailed`** | offline, timeout, 5xx | **No** — retry forever, uncounted |

A transient failure halts the drain and changes nothing, so a slip survives any
amount of being offline. (401/429 count as transient — auth/rate-limit will pass
later.) A **permanent** failure — a rejection, or a payload that can't even be
decoded — marks the slip `failed` (**dead-letter**) so it steps aside and the queue
keeps flowing.

If that split didn't exist, **a few offline launches would throw away perfectly good
data.** It's the sharpest idea in the subsystem.

**Dead-lettering used to lose data silently, and that was the real bug.** The
original design counted to `_maxAttempts` (5) before dead-lettering, then dropped
the slip from the queue — while **leaving its local row untouched.** The phone kept
showing a change the server would never receive, and nothing told anyone. Worse,
once incoming sync lands, another device's value would overwrite it and the user
would watch their own edit vanish.

The root error was a borrowed pattern: **dead-letter queues are safe on a server
because an ops team is alerted and works the queue.** The safety comes from the
human attached. On a phone there is none, so the same pattern quietly deletes the
user's work. Dead-lettering a *system message* is fine; dead-lettering *something a
person typed* is not.

Fixed by [ADR-024](adr/ADR-024-surface-failed-syncs.md): a rejection dead-letters on
the **first** occurrence and surfaces to the user, who can retry it. The ceiling is
gone — retrying an unchanged payload against an unchanged server fails identically,
and since the drain halts on failure, five attempts would have cost five launches or
reconnects, delaying the news by days. `attempts` survives as a diagnostic count.

*(The UI is deliberately minimal — an app-wide banner that satisfies "never fail
silently" and nothing more. The real UX is unplanned; open questions are in the
[learning log](learning-log.md).)*

### Draining: triggers and racing

**Three triggers** are designed; two are wired today ([ADR-008](adr/ADR-008-background-sync.md), charter §11):

- **App launch** — wired.
- **Connectivity restored** — wired (the native `EventChannel`, §8).
- **Enqueue-time kick** — *planned* (Phase 1). A write made while *already online*
  should sync immediately, not wait for the next launch/reconnect. No new infra —
  just fire `SyncRequested` after a successful enqueue.

With two triggers that can fire close together (launch + reconnect), overlapping
drains could race on the same commands. The `SyncRequested` handler uses the
**`droppable` transformer** (bloc_concurrency): while one drain runs, extra
requests are dropped, so drains never overlap.

**Deferred: exponential backoff.** Retries currently rely on the natural spacing
between launches and reconnects. Real backoff pairs with a **retry timer** that
doesn't exist yet, so it's deferred until there's something to time — noted in the
§15 ledger.

*(A full sync/outbox flow diagram — enqueue → FIFO drain → send → delete /
dead-letter — is the next deliverable under `docs/diagrams/`.)*

---

## 6. Database & migrations

> **In one line:** the local database is Drift (SQL), and it ships with a
> migration plan from **day one** — even when the schema is tiny.

**Why Drift.** The local source of truth is a **Drift** database — relational SQL,
type-safe, code-generated ([ADR-005](adr/ADR-005-local-database-drift.md)). Three
reasons it beats a NoSQL store (Isar/Hive) here:

- The ledger is **relational** (groups → members → expenses → splits); balance
  queries are natural **joins**, awkward in a document store.
- It **mirrors the Postgres schema** on the server, so one mental model spans both
  ends — and that model is easy to explain in an interview.
- It supports **SQLCipher** encryption for the sensitive ledger later (charter §13).

**Migrations exist from v1 — on purpose.** Even with two tables, the database
declares a `schemaVersion` and a migration plan. Retrofitting migrations *after*
real user data exists is one of the worst days in an app's life, so the habit is
built before it's needed (charter §6-A, cost-to-retrofit).

The plan is **append-only**: each new version adds a block; **old blocks are never
edited.**

```dart
int get schemaVersion => 3;

onCreate:  (m) => m.createAll(),          // brand-new install: build everything
onUpgrade: (m, from, to) async {
  if (from < 2) await m.createTable(groups);   // added in v2
  if (from < 3) await m.createTable(outbox);   // added in v3
},
```

A **fresh install** runs `onCreate` (everything at once). An **existing install**
runs only the blocks it hasn't seen yet. The `if (from < N)` guards make each step
run exactly once, in order.

**War story — the v2→v3 bug.** An early version bumped `schemaVersion` to 3 but
**forgot the `createTable(outbox)` block.** A device already on v2 upgraded to v3
— and got *stamped* v3 **without the outbox table**. The next "create group" (which
writes the group **and** an outbox slip in one go, §5) hit the missing table and
failed.

The save was that the write is **one transaction**: the failure rolled the whole
thing back, so there was **no orphan group** with a missing slip. Lesson learned
twice over: migration blocks **accumulate append-only**, and wrapping the local
write + enqueue in a single transaction is what kept the data consistent when the
schema was wrong.

**War story — the `sqlite3` native-assets hunt.** The first real query on a device
crashed: `dlopen libsqlite3.so not found`. Root cause: `sqlite3` 5.x ships its
native library through **Dart build hooks**, and the Flutter version in use had
`--enable-native-assets` **off by default** — so the `.so` never made it into the
APK. (`sqlite3_flutter_libs`, the old fix, is now an obsolete tombstone — the
package's own README says so.) The fix: `flutter config --enable-native-assets`
plus a clean rebuild.

The real lesson is bigger than the flag: it's a **machine-level setting**, invisible
in the repo, so a teammate cloning fresh would hit the same crash. That makes it a
reproducibility trap — and the reason it's now captured in the bootstrap script and
CI (see §13).

*(A database/migrations flow diagram will live in `docs/diagrams/`.)*

---

## 7. Network stack & error model

> **In one line:** one `dio` client with a stack of interceptors, and a rule that
> **exceptions never leak out of the data layer** — callers get a typed result,
> not a surprise throw.

### The network client

All HTTP goes through one configured `dio` client. The server is Supabase's
**PostgREST** — a write is just `POST /rest/v1/{table}` (§5). Around every request
sits a stack of **interceptors**, each with one job:

- **`AuthInterceptor`** — attaches the token, and handles 401 → refresh → retry.
- **`ErrorMappingInterceptor`** — turns a low-level `DioException` into the app's
  own typed error, so features never see raw `dio` types.

**The 401 dance (worth knowing).** `AuthInterceptor` has two clever guards:

- **A refresh lock.** If ten requests 401 at once, only the **first** triggers a
  token refresh; the rest wait on a shared `Completer` and then retry with the new
  token. No refresh stampede. (It extends `QueuedInterceptorsWrapper`, which
  queues the requests while the refresh is in flight.)
- **A retry guard.** The retried request is marked (`extra['retried'] = true`). If
  it 401s *again*, the interceptor gives up instead of looping forever — a second
  401 means the token isn't the problem.

*(Built and unit-tested, but **never faced a real 401** yet — auth isn't wired, so
the token provider is a `NoAuthTokenProvider`. Noted in the §15 ledger.)*

### The error model

Operations return a **`Result<T>`**, not a thrown exception
([ADR-009](adr/ADR-009-error-model.md)):

```dart
sealed class Result<T> {}
class Success<T> extends Result<T> { final T value; }
class Failure<T> extends Result<T> { final AppError error; }  // typed, not raw
```

And `AppError` is a **sealed taxonomy**, so a `switch` over it is exhaustive — the
compiler forces every error kind to be handled:

`NetworkError` · `AuthError` · `ValidationError` · `ConflictError` · `UnknownError`

**The rule: exceptions never escape the data layer.** The data layer catches raw
throws and maps them to a typed `Failure`. This is why it's added *now* and not
later — retrofitting an error model across a grown codebase is one of the most
painful refactors there is (charter §6-A). Being sealed means adding a new error
kind makes the compiler point at every place that must now handle it.

**Two error families, on purpose.** The general read/repository path uses
`Result` / `AppError`. The **sync send** path uses its own `SendFailure` pair
(`CommandRejected` vs `DeliveryFailed`, §5) — because that path needs a different
question answered ("is this permanent, or worth retrying?"), not "which
`AppError` is it?"

### The four global error nets

Some errors escape *everything* — a bug in a build method, an un-awaited async
throw. Startup (`bootstrap.dart`) lays down **four catch-all nets** so nothing
crashes silently and unlogged (charter Stage 10):

| Net | Catches | Fires in practice? |
|---|---|---|
| `FlutterError.onError` | framework errors (build / layout / paint) | ✅ verified |
| `PlatformDispatcher.instance.onError` | async errors with no local handler | ❌ **never fired** |
| `runZonedGuarded` | uncaught zone errors — the last-resort fallback | ✅ verified |
| `Bloc.observer` | errors thrown inside any Bloc/Cubit | ✅ verified |

All four funnel into **one logger**, so every escaped error lands in the same
stream (console in dev, a crash reporter later). Each net **tags itself** on the
way (`net 1 · FlutterError`, `net 3 · zone`, …) — without that they were
indistinguishable, and "which net caught this?" was unanswerable.

**Three of the four are verified; one is dead in this configuration.** Firing a
deliberate error into each net on a device (2026-07-28) showed
`PlatformDispatcher.onError` **never receives anything**. The reason is
structural: `bootstrap` wraps the entire app — binding init, `runApp`, the lot —
in `runZonedGuarded`, so every async error is raised *inside* that zone and the
zone handler claims it first. `PlatformDispatcher.onError` only sees errors that
reach the engine from the **root** zone, which with this startup shape is
essentially nothing.

So the honest count is **three working nets and one backstop that has never
caught anything.** It isn't strictly dead code — an error raised outside the
guarded zone (an engine-side callback, a plugin scheduling work in the root zone)
would still land there — but presenting all four as load-bearing would be
overselling. Worth knowing that the modern Flutter guidance is the *reverse* of
this arrangement: since 3.3, `PlatformDispatcher.onError` is the recommended
catch-all and `runZonedGuarded` is the legacy approach it replaced. Kongsi has
both, and the legacy one is winning.

> **A sharp edge worth calling out:** `Bloc.observer` is **mutable static state** —
> anyone, anywhere could reassign it. It's set **once**, in `bootstrap`, with a
> loud warning comment saying exactly that. A good interview answer isn't "I used
> it" — it's "I used it, and here's why it's dangerous and how I contained it."

### Transport security: TLS, and why no pinning

**TLS is the lock on the connection** (the "s" in `https`). It does two things:
scrambles everything sent to the server so no one on the network can read or
change it, and checks the server really *is* the server. TLS is enforced on every
request.

**Certificates are *not* pinned** ([ADR-004](adr/ADR-004-no-certificate-pinning.md)).
Pinning is a stricter rule — "trust *only* this one exact certificate." It blocks a
rare attack (a tricked certificate authority issuing a fake-but-valid cert), but
certificates **rotate every few months**, and an app that pins an old one **can't
connect at all** once the server renews. That's a self-inflicted outage that needs
an app update to fix — and we don't even control the rotation (Supabase does). For
an app like this the outage risk outweighs the benefit, matching current
OWASP/Google guidance.

**What we use instead — two tools built for the actual jobs:**

- **Network Security Config** — an Android settings file that **bans plain,
  unencrypted (HTTP) traffic**. It's a safety net: a coding mistake can't
  accidentally send data in the clear, because the OS blocks it.
- **Play Integrity API** — a Google check that tells the server whether the **app
  and device are genuine and untampered** (not cracked, not an emulator). This
  answers "is the client trustworthy" *directly* — the very thing people reach for
  pinning to prove indirectly.

TLS keeps the connection private and confirms the server; Play Integrity confirms
the client — different jobs, both wanted.

**The senior point:** knowing *when not* to add a security control is as senior as
knowing how. Pinning here would be fragile security theatre that raises outage risk
for little real gain.

*(A network-stack flow diagram — request → interceptor chain → PostgREST → typed
result — will live in `docs/diagrams/`.)*

---

## 8. Platform interop — the connectivity `EventChannel`

> **In one line:** native code streams "online"/"offline" up to Dart over an
> `EventChannel`, and a returning network kicks the sync drain — no relaunch
> needed.

**Why an `EventChannel` (not a `MethodChannel`).** A `MethodChannel` is
request→response ("call native, get one answer"). Network state isn't a
one-shot question — it's a **stream of changes over time**. That's exactly what an
`EventChannel` is for: native pushes events, Dart listens (charter §8).

### The native side (Android)

A `StreamHandler` manages one long-lived subscription with two callbacks:

- **`onListen`** — Dart started listening → register a
  `NetworkCallback` on the OS `ConnectivityManager`.
- **`onCancel`** — Dart stopped → **unregister** it (no leaked callback).

**The subtle bug this avoids — the thread hop.** The OS delivers network callbacks
on a **binder thread**, but Flutter's `EventSink` may only be touched on the
**main thread**. So the handler hops back before emitting:

```kotlin
override fun onAvailable(network: Network) {
    mainHandler.post { events.success("online") }   // binder thread → main thread
}
```

Touch the sink from the binder thread directly and you get a hard-to-trace crash.

### The Dart side

`EventChannelConnectivityMonitor` wraps the channel and cleans up the raw stream:

```dart
_channel.receiveBroadcastStream()
    .map((e) => e == 'online' ? ConnectivityStatus.online : ConnectivityStatus.offline)
    .distinct();   // collapse repeats, so listeners only see real transitions
```

`SyncBloc` listens and fires `SyncRequested` on each **online** transition — which
is why the outbox drains the moment the network returns (§5). `.distinct()`
matters: without it, duplicate "online" events would trigger redundant drains.

### Two ideas worth stating out loud

- **Connectivity ≠ reachability.** "Online" means *a network exists*, not *the
  server is reachable*. So it's a **hint to try**, never a promise of success — the
  drain still has to handle a send that fails anyway (which the retry logic in §5
  already does).
- **A symmetric contract, even without a Mac.** The iOS side is a **compiling Swift
  stub** — the channel exists on both platforms, so CI's macOS runner catches any
  break, even though the real `NWPathMonitor` implementation is deferred (§15
  ledger). The contract stays honest across platforms from day one.

**War story — `INTERNET` was debug-only.** The Flutter template declares the
`INTERNET` permission only in the **debug** manifest. Dev builds reached Supabase
fine — but a **release or profile build would have shipped with no network
permission at all**, a bug you'd only find in production. Fix: move `INTERNET`
(plus `ACCESS_NETWORK_STATE`, which the connectivity callback needs) into the
**main** manifest so every build type has it.

*(A connectivity/interop flow diagram — native callback → main-thread hop →
EventChannel → SyncBloc — will live in `docs/diagrams/`.)*

---

## 9. Routing

> **In one line:** `auto_route`, chosen so the route table is a **typed deep-link
> contract** from day one — designed now, filled in as features arrive.

Routing is **`auto_route`** ([ADR-020](adr/ADR-020-routing-auto-route.md)), which
**supersedes** the original `go_router` pick ([ADR-010](adr/ADR-010-routing.md)).

**Why the switch — and it happened before any routing code shipped.** Two things
mattered here: **typed routes/arguments** (no stringly-typed navigation) and
**nested routing + guards** (the app has a bottom-tab shell, and Phase 1 adds an
auth/biometric gate). `auto_route` gives both **by default**; `go_router` needs an
opt-in builder for typing and more manual work for nested shells. And crucially,
`auto_route`'s code generator **resolves cleanly against the Drift/analyzer
toolchain** — unlike Riverpod's generator, which clashed and forced hand-written
providers (§3).

**The route table *is* the deep-link contract.** The path shape is designed in
Phase 0 so Phase 4's invite flow attaches to a stable table later. `/` exists
today; `/auth`, `/groups/:id`, and `/invite/:token` are **designed-but-unbuilt**
paths features will fill in.

**Trade-off accepted:** `auto_route` is community-maintained, not Flutter-team —
the exact dependency risk the original `go_router` decision worried about. It was
re-weighed and accepted (mature, widely used, worth the ergonomics).

The meta-point interviewers notice: **a decision reversed cheaply, on purpose.**
ADR-010 was undone *before* routing code existed — early is exactly when
reversing costs nothing (charter §6-A, cost-to-retrofit). A superseded ADR isn't a
mistake; it's the record working as intended.

---

## 10. Testing strategy

> **In one line:** pick the test double to fit the job — a **mock** to check a
> call happened, a **fake** to stand in for real behaviour — and keep goldens
> stable across machines.

### Mock vs fake — pick per double

The core idea (charter §7-B): don't default to one tool for everything. A test
double is either a **mock** or a **fake**, and which one you want depends on what
the test is checking:

| Double | What it is | Use when you're checking… |
|---|---|---|
| **Mock** | No real behaviour; you script returns and **verify calls** | an **interaction** — "was `send()` called once, with this?" |
| **Fake** | A real but simplified implementation (stateful) | **behaviour** — "after enqueue then drain, the queue is empty" |

Concrete example from the sync tests: the outbox is a **fake** (`_FakeOutbox`, an
in-memory queue), because the test cares about *state over time* — enqueue, drain,
what's left. Scripting canned returns for that with a mock would be brittle and
unreadable. But a collaborator you only need to *stub or confirm* is a **mock**.

### mocktail over mockito

The mocking tool is **`mocktail`**, not `mockito`, for one decisive reason: it needs
**no code generation**. `mockito` wants `@GenerateMocks` + `build_runner` +
generated `.mocks.dart` files; `mocktail` is runtime-only and null-safe. That keeps
it **out of the analyzer-clash ledger** (§3 / §15) — no generator, no version
fight with Drift's toolchain.

Two mocktail specifics worth remembering: use `any()` as an argument matcher, and
call `registerFallbackValue(...)` once for any **custom type** you match with
`any()`. A dedicated reference test in the suite demonstrates the full
`when` / `thenAnswer` / `verify` / `captureAny` vocabulary.

### Goldens that don't flake across machines

Golden tests (pixel snapshots of widgets, via `alchemist`) have a classic trap:
**fonts render slightly differently on different OSes**, so a golden captured on
Windows fails on the CI Linux/macOS runner for reasons that aren't real bugs.

The fix is a split:

- **Platform goldens** — run **locally only** (gitignored), for eyeballing real
  rendering.
- **CI goldens** (`goldens/ci/`) — the only ones CI asserts, with a small
  `diffThreshold: 0.001` to absorb sub-pixel noise.

So CI checks a stable subset and never fails on font-rendering differences.

### A real harness from day one

Following charter Stage 8, the test harness was built **before** there was much to
test — one unit, one widget, one golden, all green — so the fixtures, fakes, and
golden tooling actually exist and run. "A test harness added later is a test
harness never added." It has since grown to a full suite (unit + widget + golden),
including a **round-trip guard** that serialises a command and reads it back
(`toJson` → `fromJson`), so a broken command shape fails a test, not a user's
sync.

*(Testing is a practice, not a module — no diagram.)*

---

## 11. Versioning & build numbers

> **In one line:** a human version name you bump by hand, and a machine build
> number derived from the git commit count — so the same commit always produces
> the same number, whichever CI builds it.

**Two numbers people conflate.** Flutter's `version: x.y.z+N` is really two
separate things ([ADR-022](adr/ADR-022-versioning-build-numbers.md)):

| | What it is | How it's set |
|---|---|---|
| **Version name** (`x.y.z`) | human-facing semantic version | hand-bumped at release; stays `0.x.y` in Phase 0 |
| **Build number** (`+N`) | machine identity of one binary (Android `versionCode` / iOS `CFBundleVersion`) | injected by CI |

Stores **reject any upload whose build number isn't strictly higher** than the
last — so the build number has to be monotonic and automatic, or you get "build
already exists" rejections.

**Build number = `git rev-list --count HEAD`.** CI counts the commits and passes
`--build-number=<count> --build-name=<semver>` at build time. The `+N` in
`pubspec.yaml` is only a local-dev default — **never** the source of truth.

**Why the commit count, of all things?** Because it's **CI-agnostic**. The CI/CD
setup runs on **two hosts** (GitHub Actions + Bitrise, §12). A per-host run number
(`GITHUB_RUN_NUMBER`, `BITRISE_BUILD_NUMBER`) would give **different, colliding
numbers** depending on who built — the count is the same on both because it's a
property of the git history, not the machine.

**Rejected alternatives:**

- **CI run number** — collides across the two hosts (the disqualifier above).
- **Timestamp** (`YYMMDDHHMM`) — monotonic but opaque and carries no link back to a
  commit.
- **Hand-managed `+N`** — forgettable and merge-conflict-prone; the usual cause of
  rejected uploads.

**Trade-off accepted:** rebuilding the *same commit* gives the *same* number — fine,
because the same code really is the same build. It relies on not rewriting shared
history (already the project norm). *(Multi-store/Huawei is deferred — a
Huawei-without-Google-Play device can't get FCM push, a release-phase concern; §15
ledger.)*

---

## 12. CI/CD

> **In one line:** two hosts split by job — GitHub Actions asks *"is the code
> good?"*, Bitrise + fastlane *"get the good build onto a tester's phone."*

### CI vs CD — a responsibility split

The pipeline runs on **two hosts on purpose** ([ADR-021](adr/ADR-021-cicd-tooling.md)):

| | Question | Host | Does |
|---|---|---|---|
| **CI** | Is the code good? | **GitHub Actions** | analyze · format-check · test · build-compile, per PR |
| **CD** | Get the good build to a device | **Bitrise + fastlane** | build, sign, upload to testers |

Why two? Actions is **free and hand-written**, the right place to *learn* CI
fundamentals and gate every PR. But release signing and store delivery lean on
**Mac-dependent tooling a no-Mac developer can't run locally** — that's Bitrise's
job. Splitting by responsibility keeps each host doing the thing it's best at.

### The release path (built in "Chunk C")

On push to `develop`: **Bitrise** builds a staging APK → **fastlane** (with the
`firebase_app_distribution` plugin) uploads it to the **Firebase App Distribution**
`internal` tester group → it lands on the phone. Device-verified end to end.

- **Config-as-code:** `bitrise.yml` lives **in the repo** — version-controlled and
  reviewable, not clicked into a web UI.
- **FAD is last-mile delivery only.** It distributes a *built* APK; it does **not**
  need the Firebase SDK inside the app. `firebase_core` / Crashlytics / FCM are
  *runtime* concerns, added later on demand.
- The APK is **debug-signed for now** — a real release signing config + keystore is
  deferred (§15 ledger).

### War story — auth vs authz (the sharpest lesson)

Firebase App Distribution kept returning **"permission denied."** The instinct is
"bad key" — but the key was **valid**. Authentication *succeeded*. The failure was
**authorization**: a valid key for the **wrong service account** on the **wrong
GCloud project**. The system correctly said *"I know who you are, and you're not
allowed to do this."*

The fix: a service account with `roles/firebaseappdistro.admin`, the Firebase App
Distribution API enabled, on the **correct** project. The lesson is the clean
mental split — **authentication** (who are you?) vs **authorization** (what may you
do?) — and recognising which one is failing from the error.

### Three more setup traps (worth naming)

- **Wrong Bitrise product.** Bitrise *Release Management* ≠ Bitrise *CI*; only CI
  builds from source. Picked the wrong one first.
- **SSH vs App-token cloning.** Bitrise clones via a **GitHub App token**, so the
  `activate-ssh-key` step must be `run_if` SSH-present, or it fails outright.
- **Shallow clone broke the build number.** The build number is the commit count
  (§11), so the workflow needs a **full clone** (`clone_depth: -1`) — a shallow
  clone would undercount.

The takeaway across all four: **the hard part of CI/CD isn't the build, it's the
auth/permissions/config plumbing around it.** Good interview material.

*(A CI/CD flow diagram — PR → Actions gate → merge → Bitrise → fastlane → FAD —
will live in `docs/diagrams/`.)*

---

## 13. Reproducibility & onboarding

> **In one line:** a fresh clone should run with **one command** — "works on my
> machine" is a bug, not a state.

**"Clone" is a test, not a chore.** The real question a fresh checkout answers is:
*can a from-zero machine run this, or is the app secretly held together by
undocumented setup on one laptop?* The Phase 0 Definition of Done makes it explicit
— a teammate clones, runs **one command**, and gets the `dev` flavor on a device
(charter §6-A).

**The trap this catches — invisible machine-level setup.** The `sqlite3`
native-assets flag (§6) is the perfect example: `flutter config
--enable-native-assets` is a **global setting on the machine**, not anything in the
repo. It works on the original laptop and silently fails everywhere else — the APK
just quietly misses `libsqlite3.so`. Tribal knowledge like that is exactly what a
reproducibility test surfaces.

**The fix — capture the tribal knowledge in scripts.** Onboarding is a pair of
bootstrap scripts (`tool/bootstrap.ps1` for Windows, `tool/bootstrap.sh` for
Unix) plus a README "Getting started". They script the whole cold-start: install
the pinned Flutter (FVM), set the native-assets flag, `pub get`, and seed
`config/dev.json`. Because the app is **offline-first**, the example config still
runs locally with no real backend — so a new dev sees it *work* immediately.

**A small sharp edge — line endings.** A `.sh` script must stay **LF**. If git
checks it out with Windows **CRLF** line endings, the `#!/bin/…` shebang breaks on
macOS/Linux and the script won't run. A `.gitattributes` rule (`*.sh text
eol=lf`) pins it — noted as housekeeping, not yet added (§15 ledger); it's LF today
by git's defaults.

*(Reproducibility is a property of the whole repo, not a module — no diagram.)*

---

## 14. Modern Dart in practice

> **In one line:** Dart 3.x constructs are used **on purpose**, each because it
> beats the pre-3 way — not for novelty (charter §7-A).

The point isn't "new = good"; it's being able to say *why* each construct earns
its place:

| Construct (since) | Where it's used | Why over the old way |
|---|---|---|
| **Sealed classes** (3.0) | `AppError`, `Result`, `CommandState`, `SyncState`, `SendFailure`, `GroupsState` | a `switch` over them is **exhaustive** — add a case and the compiler points at every place that must handle it. No forgotten branch. |
| **Switch expressions + patterns** (3.0) | `GroupsPage` renders state with `GroupsLoaded(:final groups) when groups.isEmpty => …` | destructures **and** guards in one line; replaces a ladder of `if / is / cast`. |
| **Records** (3.0) | `CommandRegistration = ({String type, CommandFactory fromJson})` — the command catalog | a lightweight, named-field tuple for a declarative list; no throwaway class needed. |
| **Class modifiers** (3.0) | `abstract interface class` for contracts (`CommandSender`, `OutboxRepository`); `final class` for closed leaves (the `AppError`/`CommandState` cases) | says the *intent* in the declaration — "implement this, don't extend it" / "this is a closed leaf" — enforced by the compiler, not a comment. |
| **Wildcard `_`** (3.7) | `create: (_) => …`, `listen((_) => …)` | names an ignored parameter as clearly ignored. |

**The main one still pending: extension types (3.3).** `GroupId` / `UserId` as
**zero-cost typed wrappers** over raw `String`, so you can't accidentally pass a
user id where a group id belongs — with no runtime boxing cost. Not built yet; a
charter §7-A candidate, tracked in §16.

The habit behind all of this: when a modern construct fits, reach for it *and* be
ready to defend it in one sentence. That "why over the old way" is the deliberate
practice — the constructs are just the vehicle.

---

## 15. Decisions ledger

> **In one line:** every "we chose X over Y" and "we deferred Z" in one place —
> the *what we didn't do, and why* that interviewers probe hardest.

### Rejected alternatives (chose X over Y)

| Decision | Chose | Over | Why | § |
|---|---|---|---|---|
| DI tool | Riverpod | `get_it` / `injectable` | reactive graph (watch/dispose/invalidate) vs a manual service locator | 3 |
| Provider codegen | hand-written | `riverpod_generator` | its analyzer version clashes with `drift_dev` (see ledger below) | 3 |
| Delivery guarantee | at-least-once + idempotency | exactly-once | same result (no dupes), far less machinery, works on an unreliable network | 5 |
| Command→row mapping | on the command (`table`/`toRow`) | a central `switch` / remote repository | keeps sync from importing every feature | 5 |
| Local DB | Drift (SQL) | Isar / Hive | relational ledger → joins; mirrors Postgres; SQLCipher-ready | 6 |
| Mocking tool | `mocktail` | `mockito` | no codegen → stays out of the analyzer-clash ledger | 10 |
| Routing | `auto_route` | `go_router` | typed routes + nested/guards by default; generator fits the toolchain | 9 |
| Cert trust | TLS + NSC + Play Integrity | certificate pinning | pinning's outage risk outweighs its benefit here | 7 |
| Build number | git commit count | CI run number / timestamp / hand-managed `+N` | CI-agnostic across the two-host split | 11 |
| Conflict resolution (v1) | last-write-wins | field-level merge / reject-and-prompt | proportionate to MVP; the trade-off is documented, not hidden | ADR-006 |

### Deferred / not-yet-built (chosen, not skipped)

| Item | Status | Why | § |
|---|---|---|---|
| Sync-failure UX | placeholder | ADR-024 is built, but the banner is the bare minimum that satisfies "never fail silently"; the real UX is undesigned | 5 |
| Base-version tracking | pending | nothing records a row's pre-edit value, so a failed change can't be rolled back *in principle*; also what LWW needs to detect a stale write | 5 |
| Dependent-slip cascade | open | after a dead-letter, slips behind it still send against a server missing their parent; harmless until Phase 2 adds dependent commands | 5 |
| Exponential backoff | deferred | needs a retry timer that doesn't exist yet; launch/reconnect spacing suffices | 5 |
| Enqueue-time sync kick | planned (Phase 1) | no new infra — just fire `SyncRequested` after a successful enqueue | 5 |
| Real 401 handling | built, untested live | interceptor exists but auth isn't wired (`NoAuthTokenProvider`) | 7 |
| MVVM `CommandCubit` verdict | open (ADR-023) | judged at its 2nd use site (Phase 2 add-expense) | 4 |
| Extension-type ids (`GroupId`/`UserId`) | pending | a §7-A candidate; not built | 14 |
| Real release signing | deferred | staging APK is debug-signed for now | 12 |
| iOS connectivity impl | stub only | Swift stub compiles; real `NWPathMonitor` deferred (no Mac) | 8 |
| `freezed` | deferred | stable still clashes; only `4.0.0-dev.3` prerelease resolves — waiting for 4.0 stable, `equatable` used meanwhile (see analyzer-clash ledger) | 15 |
| Import-boundary enforcement | deferred | tooling maturity (ADR-017) | — |
| RLS policies | disabled | real policies need `auth.uid()` — waits for auth | — |
| Branch protection | deferred | GitHub gates it behind a paid tier for private repos; PR discipline for now | — |
| Multi-store / Huawei push | deferred | release-phase concern (HMS ≠ GMS for FCM) | 11 |
| `.gitattributes` `*.sh eol=lf` | housekeeping | LF today by git default; pin it before it bites | 13 |

### The analyzer-clash ledger

A running record of **which code-generating dependencies coexist** with the
project's toolchain — because Drift's `analyzer` version is the constraint
everything else has to fit around. This is why some tools were rejected above.

| Dependency | Status | Reason |
|---|---|---|
| `drift_dev` | **in** (the anchor) | needs `analyzer ^13` — sets the ceiling for everyone else |
| `auto_route_generator` | in | resolves cleanly against that ceiling |
| `json_serializable` | in | clean |
| `retrofit_generator` | in | clean |
| `alchemist` (goldens) | in | clean |
| `mocktail`, `bloc_concurrency` | in | **no codegen** — can't clash by construction |
| `riverpod_generator` | **out** | no version supports `analyzer ^13` (latest wants `^12`) — hard conflict with `drift_dev` |
| `freezed` (stable) | **out** | stable still needs an older analyzer; **only `4.0.0-dev.3` (prerelease) resolves** |
| `mockito` | *would resolve* (`5.7.0`), **not adopted** | the clash cleared, but `mocktail` already covers stub/verify **without codegen** — no reason to add it |

**Re-verified 2026-07-23** by `pub add --dry-run` against live pub.dev (this repo,
`analyzer 13.0.0`, `drift_dev 2.34.4`, `build_runner 2.15.1`): `mockito` now
resolves stable; `freezed` resolves **only** as the `4.0.0-dev.3` prerelease;
`riverpod_generator` still fails version solving outright.

**Why not just downgrade the analyzer?** You can't — it isn't a direct dependency;
`drift_dev` pulls it in and sets the ceiling. Forcing it lower means either
downgrading `drift_dev` (freezing the app's **database spine** on an old version to
house a testing/boilerplate convenience — priorities backwards) or a
`dependency_overrides` that bypasses the *constraint* but not the *code*, so
`build_runner` crashes on analyzer-13 APIs it no longer has. Neither is worth it.

The takeaway: **one code-gen dependency's version can veto another,** and the
heaviest generator (`drift_dev`) owns the ceiling. Knowing which tools clash — and
deliberately choosing no-codegen tools (`mocktail`, `bloc_concurrency`) to sidestep
the whole problem — is a real senior-level dependency-management call.

*(Tracked trigger: revisit `freezed` when **4.0 stable** ships — it would remove the
hand-written `equatable` + `copyWith` boilerplate, and it already resolves against
the current toolchain in prerelease.)*

---

## 16. Open threads

> **In one line:** Phase 0 ended with a working spine and some **deliberately open
> threads** — being honest about what isn't proven yet is part of the point.

§15 lists the *decisions* (chosen or deferred). This is the shorter, honest list of
what's **not yet built or exercised** — the things I can't fully defend from
experience yet. The living source is the [learning log](learning-log.md); the ones
that matter most for an interview:

- **Auth has never faced a real 401.** The hand-built refresh-and-retry interceptor
  (§7) is written and unit-tested, but with no auth wired it has never handled a
  *real* expired token. Phase 1 is where it earns its keep — until then it's a
  design I can explain but haven't watched fire in anger.
- **Conflict resolution is designed, not stressed.** Last-write-wins (ADR-006) is
  chosen and its data-loss case documented, but no two-devices-edit-offline
  scenario has actually been run. Being able to *articulate* the trade-off is the
  interview value; proving it end to end is future work.
- **Sync used to lose writes silently — found by reasoning, not by a crash.** A
  dead-lettered slip was dropped while its local row stayed put, so phone and server
  diverged permanently with no signal to anyone. Fixed
  ([ADR-024](adr/ADR-024-surface-failed-syncs.md)), but three things it exposed are
  still open: **nothing stores a row's pre-edit value**, so a failed change can't be
  rolled back *in principle*, only surfaced; **the failure UI is a placeholder**; and
  after a dead-letter, slips queued behind it still send against a server missing
  their parent (harmless until Phase 2 adds dependent commands). Two ideas worth
  keeping from it: dead-letter queues are safe on a server *because an ops team is
  alerted* — borrow the pattern to a phone and you drop the human but keep the
  deletion; and **delivery and merge are separate problems**, so no merge strategy
  (LWW, field merge, CRDT) can rescue a write that never arrived.
- **Realtime and Storage are untouched** — both v2 (live updates, receipt images).
  The offline SSOT is built to receive them (incoming changes just upsert into the
  local DB), but nothing streams yet.
- **Extension-type ids are still pending** (§14) — the small typed-`GroupId`
  refactor that would stop id mix-ups at compile time.

Progress worth noting since the log was last written: the **MVVM Command verdict**
is no longer just an open question — its argument is now captured in
[ADR-023](adr/ADR-023-mvvm-command-verdict.md) (still Open, but seeded).

None of these are oversights. They're threads left open **on purpose**, tracked in
the open source of record, to be pulled in the phase that gives each one a real
reason to exist.

---

*This summary is the narrative spine for the Phase 0 flow diagrams, which live under
[`docs/diagrams/`](diagrams/) — one per module, referenced from the sections above.*
