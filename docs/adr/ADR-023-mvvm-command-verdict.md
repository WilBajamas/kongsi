# ADR-023: Presentation-layer `CommandCubit` vs a plain submit flag — verdict deferred

**Status:** Open — verdict deferred to the second use site (Phase 2, add-expense)
**Date:** 2026-07-22

## Context

Two unrelated patterns share the name "Command" in this codebase (see
[ADR-002](ADR-002-state-management.md)):

- **GoF Command** — the serialisable outbox write, drained by `SyncBloc`
  ([ADR-003](ADR-003-offline-strategy.md)). Not in question here.
- **MVVM Command** — a small presentation-layer wrapper around a button's async
  lifecycle (idle → running → failure), from the Flutter team's own architecture
  guidance. This ADR is about *that* one.

The MVVM Command is implemented as `CommandCubit` (`lib/app/command/cubits/`): a
**generic** cubit wrapping any `Future<void> Function()` so a submit button can
disable itself while running, block double-taps, and show a failure — without a
bespoke cubit per button.

Its only current use site is `CreateGroupDialog`. Reviewing that dialog raised
three honest objections:

1. **Why no dedicated `CreateGroupCubit`?** Because `CommandCubit` *is* the
   experiment being run instead of one — a reusable wrapper vs a per-feature
   cubit. Writing `CreateGroupCubit` would abandon the pattern before testing it.
2. **The `late final _submit` + `initState`** is a smell. It exists because the
   action closure captures dialog-local `TextEditingController`s and `ref`, none
   of which exist until the `State` does — so the cubit can't be a field
   initializer. The `late` is the *cost of the generic closure design*, not a
   free choice.
3. **"Provide the cubit from `groups_page.dart` instead"** doesn't work cleanly:
   `showDialog` pushes the dialog on a **new route**, so a `BlocProvider` created
   in the page isn't in the dialog's tree — it needs an explicit
   `BlocProvider.value` bridge. And the inputs live *in* the dialog, so lifting
   the cubit up forces `execute(name, currency)`, which strips the genericity
   that was the whole point. Keeping submission inside the dialog is deliberate
   encapsulation: the list is the page's concern, the submit is the dialog's.

The real question underneath all three: **is a generic `CommandCubit` worth its
ceremony, or would a plain `bool _isSubmitting` + `setState` be simpler and
enough?** One use site can't answer that — a reuse abstraction is only justified
by reuse.

## Options on the table

| Option | `late`? | Trade-off |
|---|---|---|
| **A. Current** — generic `CommandCubit`, closure captures controllers | Yes | Max reuse; `late final` + manual create/close/`BlocBuilder(bloc:)` |
| **B. Provide from `groups_page`** | No | Needs `BlocProvider.value` across the dialog route + `execute(params)`; leaks the dialog's internals upward |
| **C. Dedicated `CreateGroupCubit`** | No | Conventional and explicit; abandons the MVVM-Command experiment |
| **D. Plain `bool _isSubmitting` + `setState`** | No | Simplest; no cubit — the baseline the wrapper must beat |

## Deciding criterion (why this is Open, not Accepted)

The verdict is taken at the **second adoption** — the add-expense submit button in
Phase 2 (charter §18). By then there are two real use sites, and the question
answers itself:

- If `CommandCubit` drops into the second button cleanly and removes duplicated
  running/failure boilerplate → **A wins**, and this becomes Accepted: a small
  reusable pattern that earns its keep.
- If the second site fights the generic closure the same way the first did (more
  `late`, more bridging) → **D wins**, `CommandCubit` is deleted, and each button
  keeps a local `isSubmitting` flag.

Provisional lean: **A for now**, because deleting the experiment before its second
use site would be judging reuse from a sample of one.

## Evidence — 2026-07-28, Phase 1 chunk 3 (sign-in form)

The sign-in form looked like a textbook second use site: an async submit, a
button to disable, a failure to show. `CommandCubit` could not take it.

`CommandCubit.execute` reports failure by **catching an exception**
(`lib/app/command/cubits/command_cubit.dart:17`). That works for
`CreateGroupUseCase` only because `DriftGroupsRepository` lets Drift exceptions
escape the data layer — which [ADR-009](ADR-009-error-model.md) actually forbids,
noted separately. `AuthRepository.signIn` follows ADR-009 properly and returns a
typed `Result`, never throwing. Wrapped in `CommandCubit`, a rejected password
would complete normally and be reported as a **success**.

So the sign-in form got a small dedicated `SignInCubit` with a sealed state.

**What this is evidence of, and what it is not.** It is not the verdict — this is
not the like-for-like comparison the criterion above asks for, since the mismatch
is about the error channel, not about reuse ceremony. It does sharpen the
boundary: `CommandCubit` fits fire-and-forget actions that signal failure by
throwing, and stops fitting the moment an action returns a typed result the
caller must read. Given ADR-009 says the typed result is the house style, the
population of actions `CommandCubit` can serve is smaller than it looked when the
wrapper was written.

That is a point for **D** without settling it. The verdict still belongs at
Phase 2's add-expense, which goes through a use case of the same shape as
create-group.

## Consequences

- Until the verdict, `CommandCubit` stays as the single documented MVVM-Command
  example; the `late final` in `CreateGroupDialog` is accepted as the known cost.
- Whichever way it resolves, the *reasoning* is the deliverable — being able to
  say why a reusable wrapper did or didn't beat a one-line flag is the
  interview-relevant part, not the code itself.

## Alternatives considered

Covered inline in **Options** above (A–D). This ADR intentionally records no
final choice; it is the written seed for the verdict, sourced from the design
discussion on 2026-07-22.
