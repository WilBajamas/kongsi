# 01 · Architecture & layering

**Study spine:** [technical-summary §2](../technical-summary.md) (architecture at a
glance) + §4 (state-management stack) · [diagram 02-groups-slice](../diagrams/02-groups-slice.md).

The theme: a feature is a vertical slice of the same predictable layers, and two
shared systems (DI, sync) cut across all of them. This section is about *why the
layers are drawn where they are*, and what each boundary buys.

---

## What (recall anchors)

1. Name the five layers of a feature slice, top to bottom, and the **one job** of each.
A: Presentation: Widget (The UI - it displays and consumes actions as events to the Cubit / Bloc), Cubit / BloC (state holders - holds the state of the widget) | Domain: Entities (core business objects that defines the rules of the app), Use Cases (a business action - each usecase is a unique business action that can be performed by the user), Repository Interfaces (defines the contract of the operations that the feature needs) | Data: Repository Impl (concrete implementations - implements the repository interfaces defined in the domain layer), Models (data layer models that have been translated from external sources to dart readable data objects) | Database: Drift (the SSoT of the app's data)

2. Two systems cut across every slice. Name them and give each one's single
   responsibility in a sentence.
A1: Riverpod as Dependency Injection: To provide dependencies app-wide with lazy-loading and automatic cleanup.
A2: Syncing Outbox: It's its own individual system to that drains all the commands in the outbox and sync them to the backend (supabase) - currently during app startup or reconnectivity.

3. State the three rules that keep the layers clean (the file/import/translation rules).
A1: Domain layers should not have external dependencies - pure dart business logic and entities.
A2: Every contract is a abstract class/interface defined by the layer above it - this way layers depend on abstraction and not concrete implementations - DIP.
A3: Only the presentation layer should be aware of the translation strings - because of BuildContext dependency.
A4: The `core` layer cannot import `app` layers - `app`'s responsibility is towards Flutter's own implementation details, while `core`'s reponsibility is pure business logic.

## Why (the meat)

1. **The transactional write.** `createGroup` does two writes in one Drift
   transaction. What are the two writes, and give the **concrete failure** you'd see
   if they weren't atomic — not "data could be inconsistent," but the exact bad state
   and the user-visible symptom.
A1: Adds a new group to the `groups` table, would return a duplicate group id if a row with a duplicate id already exists. (this is highly unlikely since we use UUIDs generated using crypto's randomBytes) 
A2: Adds a new entry to the `outbox` table to sync to the backend (supabase).
The concrete failure is that the app only "syncs" the groups only during startup and reconnection, not immediately after writing to the table - in `DriftGroupsRepository`, there's only insert functions to the drift tables but the draining outbox functionalities are only living within `sync` as of now. On the user side, it looks fine, but silently on the backend, there would be a gap

2. **Dependency direction.** The rule is "core cannot import the app layer," yet
   `DriftGroupsRepository` (a feature) freely imports `outbox_table` and
   `CreateGroupCommand` (core sync). Explain why that's *not* a violation, and what
   the rule is actually protecting against. What concretely rots if you break it?
A: `core` cannot import the `app` layer but the reverse is not true - it is like the `domain` layer where it is the lowest level implementation of the app and its own independent system. This rule prevents the `core` to be tightly coupled with any "features" and to be modular. Violating this rule would mean that `core` would be entangled with "features" - which would make `core` less reusable and harder to maintain.
Currently the `CommandRegistry` is dumb, it does not know what kinds of commands it is being fed. If `core` were to "know" about features, then it would know about all the features in the future and violates SOC, we would need a big "what-if" or switch statements and map each individual feature's behaviour, that's where maintainability and scalability rots.

3. **Thin use-cases.** `WatchGroupsUseCase.call()` is one line — it just forwards to
   the repo. That looks like ceremony. Defend keeping the layer, *or* concede it.
   Either way, name the condition under which your answer flips.
A: Honestly having a passthrough use case layer is debatable as it currently doesn't add much value and with extra code. But with a use case, it is very reusable among the presentation layer, and it's considered to be a foundation of future improvements or additions. Having to write one small file an exchange for huge futarability is a good tradeoff in my opinion. Therefore the presentation layer is unaware of the "how" the action is being done behind the scenes, it is just focused on the "what" - which is to present the data to the user.

4. **Entity vs row.** The repo maps `GroupRow` → `Group` before returning
   (`_toEntity`). Why not just return the Drift row and save the mapping? What leak
   does the boundary stop, and who would feel it?
A: The damage would be dealt to all the layers above the data layer - the domain and presentation layer. Returning `GroupRow` directly would drag `package:drift` upwards with it, meaning the domain and even the widgets would have to know the database's row shape - a persistence detail leaking into layers that shouldn't even know a database exists. So if the db schema changes (a column rename or a type change), the break would ripple all the way up into the UI. `_toEntity` is the wall that stops that - it keeps the schema's blast radius inside the data layer.

5. **Two "Command"s.** The slice contains a `CommandCubit` (in the dialog) and a
   `CreateGroupCommand` (in the repo). Which layer and which machinery is each, and
   why doesn't sharing the word actually confuse anyone building the app? If forced to
   rename one, which and to what?
A: `CommandCubit` is being used as part of the presentation layer, it is meant to be reused as a generic state holder for the presentation layer's actions for component's states. `CreateGroupCommand` is a data holder meant to be passed as "information" for table inserts. Both have totally different responsibilities. `CreateGroupCommand` is from the original GoF Command Pattern whereas `CommandCubit` is another design pattern meant for the view layer. If forced to rename one, I would rename `CreateGroupCommand` because it acts more of a data holder instead of a behaviours.

6. **Translation placement.** Only presentation translates (l10n). Why is putting a
   user-facing string in the entity or the `AppError` a mistake? What does the
   presentation-only rule keep true about the layers beneath it?
A: Because of the dependence of `BuildContext` for l10n, the best place to use them are widgets (presentation). The reason why putting them in the domain or any other layers is a mistake is because of stale rebuilds, and l10n can change at runtime - user changes language, the UI needs to update to reflect the change. This rule keeps the domain and other layers ignorant of the UI's needs and vice versa.

## How (kata — file placement)

You're adding an **Expenses** feature: a screen that lists a group's expenses and a
dialog to add one. Without writing full implementations:

1. List every file you'd create and the **layer** each sits in (use the groups slice
   as the template).
A: Page (screen and widgets), Cubits / BloCs as stateholders and a create expense dialog that takes in the `CommandCubit`, domain use cases, repository interfaces and entities, data layer's repositories implementations, then finally a new command `CreateExpenseCommand`.

2. Name the **contracts** (`abstract interface class`) and where each lives.
A: Domain repository `abstract interface class ExpensesRepository`.

3. Say exactly where the **write transaction** goes, and which shared systems the
   feature reuses **unchanged** (no edits to core).
A: The writes should be in the concrete repository, that reuses `AppDatabase` (provided by DI - riverpod).

4. State which single file the new command must also be registered in, and why that
   file lives in the app layer rather than core.
A: The `CreateExpenseCommand` must be registered in `CommandRegistry` for the syncing process, living in the `app` layer. It lives in the app layer because it is a "feature" specific command, not a core infrastructure concern.

*(No code needed — this tests whether the layering is load-bearing in your head. If
you want the code-kata version, do the real end-to-end add in §03's kata.)*

## Diagram-from-memory

Reproduce [diagram 02](../diagrams/02-groups-slice.md) from memory: the **read path**
(subscribe) and the **write path** (create), showing which layer each call crosses and
where the **reactive loop** closes itself. Then diff against the file — the thing to
check you got right is *why* the list updates after a write with no manual refresh.

## Viva (defend these live)

1. "This is Clean Architecture cosplay — five layers and a use-case-per-action for a
   two-table app. That's over-engineering you'll pay for in every feature. Justify the
   layer count for *Phase 0 specifically*, or admit it's premature."
A: Phase 0 is a setup phase for identifying and setting up the foundation and rules of the app. Because who knows how big features will be in the future for the app nor do I know if there will be other developers working on this project in the long run. So each layer has its own unique responsibilities and roles, and also their capabilities to be scalable, reused and modular.

2. "You claim sync is a decoupled subsystem that 'knows nothing about features.' But
   the feature imports the outbox table and builds a sync Command inline. From where I sit, groups and sync are entangled. Convince me the direction of the arrow matters."
A: The `sync` subsystem may be depended for others, but not the other way around. The feature (most likely `DriftGroupsRepository`) depends on the `core`, not the other way around. So the dependency pipeline is "one-way" and not entangled.
   
3. "Your use-cases are one-line forwarders. Name the bug they've prevented so far.
   You can't — so they're speculative structure. Defend speculative structure to a
   lead who has to ship."
A: So far they haven't prevented any bugs but as mentioned before usecases are there to show a "direction" or "guidelines" actions for the app, they're what triggers the business logic, without usecases future developers would have a relatively harder time understanding the flow of the app and how each actions are being executed. They're also a good place to inject business logic in the future if needed.

4. "Make this same app pure-online, no offline. How many of these layers survive, and
   which boundary was really about offline-first all along?"
A: The database will be taken out because there is no use storing data anymore, since all actions / commands are to go through API calls, the database will not be the SSoT anymore, rather the dio-client would be. The entire `sync` subsystem would be reduced to just "fetching" from APIs only, and not much "syncing" will be involved. I would say the database layer is the heart of offline-first integration of the app.

## Rubric — a lead-level answer covers

- **Layers + cross-cutting split** named correctly, each with a genuine single
  responsibility (not "handles logic").
- **Atomicity** explained as "UI state and sync intent can't diverge," with the
  concrete rollback story (group row without its outbox slip → a create that never
  syncs, or vice versa) — ties back to the v2→v3 war story.
- **Dependency direction** stated as *feature → core allowed, core → feature
  forbidden*; can explain the blast radius of breaking it (a central
  `switch`/registry in sync forces sync to import every feature → the generic pipe
  rots into something that knows the whole app).
- **Thin use-cases** defended with a *real* reason (keeps Bloc storage-unaware; a
  stable seam for tests and for logic that arrives later) **and** an honest concession
  (it's ceremony today; the bet is cost-to-add-later). A lead names the flip condition.
- **Entity/row** and **translation** boundaries both explained as leak-prevention —
  the data layer's shape and the backend's language never reach the widgets.
- **Two Commands** placed in the right layers (MVVM/presentation vs GoF/domain+sync)
  with the different machinery named.
- Throughout: reaches for **rejected alternatives and trade-offs**, not just "this is
  the clean way."
