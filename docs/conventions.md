# Kongsi — Coding Conventions

> The rules this codebase actually follows, and why. Decisions with real
> trade-offs live in [`adr/`](adr/); this file is the day-to-day reference.
> When a rule here came from a specific decision, it links to it.
>
> Last updated: 2026-07-28 (Phase 1, chunk 3).

## 1. Layering

```
presentation  →  domain  →  data
```

- **`core/`** holds cross-cutting infrastructure: errors, result types, network,
  database, sync, DI, validation, storage, clock/uuid.
- **`features/<name>/`** splits into `data/`, `domain/`, `presentation/`.
- **`app/`** is the shell: router, theme, global widgets, app-wide cubits.

**`core/` must never import `features/` or `app/`.** When core needs something
the app owns, it takes it as an injected dependency instead — see
`commandRegistryProvider`, which core declares and `bootstrap` fills in.

Presentation talks to `domain` (entities, repository *interfaces*, use cases),
never to `data` directly. A cubit depending on a repository interface is fine —
the interface lives in `domain`.

*Automated enforcement is deferred ([ADR-017](adr/ADR-017-import-boundary-enforcement-deferred.md)); this is discipline for now.*

## 2. Files and naming

- **Contracts and implementations live in separate files.** `abstract interface
  class GroupsRepository` in `domain/repositories/`, `DriftGroupsRepository` in
  `data/repositories/`.
- Use `package:` imports inside `lib/`, never relative ones.
- Don't create a file for a single one-line declaration — put it with its closest
  owner. (A one-line enum got its own file once; it didn't survive review.)
- Name a file for what it *is*, not for one of the things it does. A page serving
  both sign-in and sign-up was `sign_in_page.dart` — that was the smell that the
  page should have been two pages.

## 3. State management

| Tool | Role | Lifetime |
|---|---|---|
| **Riverpod** | Dependency injection only — the object graph | App (one instance per container) |
| **Cubit** | Screen and form state | The screen |
| **Bloc** | Event-driven flows (`SyncBloc`) | As scoped |

Riverpod provides *dependencies*; Bloc/Cubit hold *state*. They never overlap
([ADR-002](adr/ADR-002-state-management.md)).

**Screen-scoped cubits are created with `BlocProvider`, not held as fields.**

```dart
BlocProvider(
  create: (_) => SignInCubit(ref.read(authRepositoryProvider)),
  child: Scaffold(...),
)
```

`BlocProvider` closes the cubit for you. A `late final` cubit built in
`initState` is only justified when the cubit's constructor captures something
that doesn't exist until the `State` does — `CreateGroupDialog` is the one real
case, because its action closure captures the dialog's own controllers.

**Never put a screen cubit in a Riverpod provider** — that gives it app lifetime,
so form state would outlive the form.

## 4. Use cases

**A use case exists only when it holds logic.** Composing several repositories,
generating ids or timestamps, enforcing a rule — those earn a use case. Forwarding
one call to a repository does not; the cubit calls the repository interface
directly.

`CreateGroupUseCase` stays (mints the id, stamps the clock, builds the entity).
`WatchGroupsUseCase` was deleted — it was `_repository.watchGroups()` and nothing
else. *(Decided 2026-07-28; charter §7.)*

**The exception: a pass-through is fine when it is genuinely shared.** If several
callers need the same operation, a use case is worth it even with no logic inside
— it gives them one seam to depend on, so logic added later (a permission check, a
cache, an audit line) lands in one place instead of every caller. The test is
*reuse*, not line count.

Judge it on what you can actually see, not on what might happen. "Two screens will
need this" written in a plan counts; "this could be reused someday" does not — that
reasoning justifies every pass-through ever written, which is how the rule got
broken in the first place.

## 5. Errors

**Exceptions never escape the data layer** ([ADR-009](adr/ADR-009-error-model.md)).
Repositories return `Result<T>` — `Success` or `Failure(AppError)`. `AppError` is
sealed: `NetworkError` · `AuthError` · `ValidationError` · `ConflictError` ·
`UnknownError`.

**Cubits classify; widgets render.** A cubit turns `Failure(AppError)` into its
own screen-shaped outcome states, and the widget switches over *those*:

```dart
// cubit — the only place this screen reads AppError
SignInState _classify(AppError error) => switch (error) {
  AuthError() => const SignInRejected(),
  NetworkError() => const SignInUnavailable(),
  _ => SignInFailed(error),
};
```

Name states for **what happened**, not for the message shown (`SignInRejected`,
not `SignInWrongPasswordMessage`) — otherwise l10n coupling just moves into the
cubit.

A widget switching over `AppError` with a `_ =>` default is the tell that it's
handling a vocabulary wider than its screen's reality. The widget's switch should
be exhaustive over its own states with no default.

Keep the original `AppError` on the unexpected state so it can still reach a crash
reporter later.

The sync send path uses its own `SendFailure` pair (`CommandRejected` vs
`DeliveryFailed`) because it answers a different question — "permanent, or worth
retrying?"

## 6. Modern Dart

Prefer Dart 3.x constructs where they fit, and be able to say why (charter §7-A).
In use here: sealed classes with exhaustive switches, switch expressions, pattern
destructuring (`Group(:id)`), `if (x case final y?)`, class modifiers
(`abstract interface class`, `final class`), records.

Not yet adopted: extension types for ids (`GroupId`), freezed (deferred until 4.0
stable — the prerelease is the only version that resolves against analyzer 13).

Each first use of a construct gets a one-line "why this over the old way".

## 7. Widgets

- Lean, dumb widgets reacting to state. Decisions belong in the cubit.
- Split when readability demands it, not preemptively.
- **Reuse via composition (slots), not configuration (flags).** A `mode` enum
  driving two behaviours inside one widget is the anti-pattern — that's two
  widgets wearing a trench coat.
- No gratuitous `Builder`s.
- New shared widgets only with strict ownership. Two flows expected to diverge get
  two independent widgets, even if they look identical today (sign-in and sign-up
  are the worked example — the duplication is accepted so they can grow apart).
- Build components when a screen needs them, not ahead of time (design brief §6).

## 8. Forms and validation

Timing is the same on every form in the app (design brief §7-A):

1. Silent while first typing — no error before the user submits.
2. On submit, every rule runs and failing fields show their message.
3. After that, live — the message re-checks on each keystroke and clears the
   moment the input is valid.

That is `AutovalidateMode.onUserInteractionIfError` on the `Form`. Not
`onUserInteraction` (nags from the first character), not `onUnfocus` (message goes
stale while being fixed).

**Shared rules live in `core/validation/validators.dart` and return `bool`, never
a message** — a translated string would drag l10n into `core`. The page maps the
failure to its own l10n text.

**A form that submitted successfully stays disabled until the screen is gone.**
Treat the success state as busy; re-enabling during navigation flashes the form
back to normal for a frame.

## 9. Localization

- Every user-visible string is an l10n key, in **all three** ARB files
  (`en`, `ms`, `zh`) — `lib/l10n/arb/`.
- **Translate in presentation only** ([ADR-019](adr/ADR-019-localization.md)).
  Nothing below presentation returns display text.
- Server/SDK error text is for logs, never for users.
- Regenerate with `fvm flutter gen-l10n`.

## 10. Comments

- **Short — one or two lines.** If it needs a paragraph, it belongs in an ADR or
  the learning log.
- **Why, not what.**
- No ADR references in code; the docs cross-reference the code, not the reverse.
- `// !` prefix marks a genuine trap — something that will bite someone who
  changes this code without knowing.

## 11. Tests

**Pick the double to fit the job** (charter §7-B):

- **mocktail** for a collaborator you only stub or verify. Chosen over mockito
  because it needs no codegen, keeping it clear of the analyzer-clash ledger.
- **Hand-rolled fake** when the double needs real, evolving behaviour — an
  in-memory queue or DB.

Rule of thumb: verifying an *interaction* → mock; standing in for *stateful
behaviour* → fake.

Other rules:

- Test names read as behaviour: `'a network failure stays distinguishable from a
  bad password'`.
- Prefer testing logic where it lives. A rule reachable only by pumping a widget
  is a rule in the wrong place.
- `test/helpers/pump_app.dart` gives the DI + theme + l10n shell.
- Use `registerFallbackValue` in `setUpAll` for custom types used with `any()`.

**Traps:**

- `pumpEventQueue()` **deadlocks** inside `testWidgets` (fake-async zone). For
  stream → bloc → widget, use `tester.runAsync(...)` then `pump()` — see
  `test/app/sync_problems/sync_problems_banner_test.dart`.
- Goldens: CI asserts `goldens/ci/` only, `diffThreshold: 0.001`. Platform goldens
  are local-only and gitignored.

## 12. Verification

**A guarantee that lives in a design doc but not in a line of code isn't a
guarantee.** Phase 0 had three claims documented in several places that had never
once executed. For any claim of that shape, ask which code enforces it and whether
that path has ever actually run.

So: run the thing. Tests passing is not the same as the feature working. Every
chunk in Phase 1 ended with a device check, and two of them found something the
tests could not have.

Full checklist: [`definition-of-done.md`](definition-of-done.md).

## 13. Codegen

Committed to the repo: Drift `.g.dart`, auto_route `.gr.dart`, json_serializable
`.g.dart`, l10n `gen/`.

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter gen-l10n
fvm flutter test --update-goldens   # then eyeball the png
```

Note: `app_router.gr.dart` is a `part of` `app_router.dart` — other files import
`app_router.dart` to reach the generated route classes, and the part inherits its
imports from the parent file.

## 14. Commits

- Brief conventional messages: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`,
  `ci:`.
- **No AI signature or co-author trailer.**
- Split logical units — a refactor and a feature are two commits.

## 15. Environment

- Windows + **PowerShell**; **`fvm` prefix** on every Flutter/Dart command.
- Run: `fvm flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json`
- `flutter config --enable-native-assets` is required (sqlite3 5.x ships its
  native lib via a build hook). Without it an APK silently lacks `libsqlite3.so`.
- `adb shell run-as` does not work on the dev device (ROM restriction). To inspect
  app-private files, have a dev-flavor build read them and log a verdict instead.
- Widgets built in `MaterialApp.builder` sit **above** the Navigator — no
  `Tooltip`, `SnackBar` or popup menu there, and navigation must go through the
  router's `navigatorKey`.
