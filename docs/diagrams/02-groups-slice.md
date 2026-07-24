# 02 · Groups feature slice

**Type:** sequence — one vertical slice told as a story: the read path subscribes,
a write goes down the layers, and the reactive loop closes itself.
**Source:** [technical-summary §2](../technical-summary.md) + §4

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Page as GroupsPage
    participant Cubit as GroupsCubit
    participant Dialog as CreateGroupDialog
    participant CC as CommandCubit
    participant UC as CreateGroupUseCase
    participant Repo as DriftGroupsRepository
    participant DB as AppDatabase (Drift)

    Note over Page,DB: — setup: the read path subscribes —
    Page->>Cubit: BlocProvider create → GroupsCubit(watchGroupsUseCase)
    Cubit->>Repo: _watchGroups() → watchGroups()
    Repo->>DB: select(groups).watch()
    DB--)Cubit: stream emits rows → emit(GroupsLoaded)

    Note over User,DB: — write path: user creates a group —
    User->>Page: tap FAB
    Page->>Dialog: showDialog(CreateGroupDialog)
    User->>Dialog: tap Create
    Dialog->>CC: _submit.execute()
    activate CC
    CC->>CC: emit(CommandRunning) · button disables
    CC->>UC: call(name, currency)
    activate UC
    UC->>UC: Group(id: _uuid.generate(), createdAt: _clock.now())
    UC->>Repo: createGroup(group)
    activate Repo
    Repo->>DB: transaction { insert groups row · insert outbox slip }
    Note right of DB: ONE transaction: row + CreateGroupCommand.toJson()<br/>both or neither · drain lives in 04-sync-outbox
    DB-->>Repo: ok
    deactivate Repo
    UC-->>CC: Future completes
    deactivate UC
    CC->>CC: emit(CommandIdle)
    deactivate CC
    Dialog->>Dialog: pop() (kept open on CommandFailure)

    Note over Cubit,DB: — the reactive loop closes itself —
    DB--)Cubit: watched stream re-emits (the insert triggered it)
    Cubit->>Page: emit(GroupsLoaded) → BlocBuilder rebuilds, new group visible
```

**Reading it**

- **The read path never refreshes manually.** Drift's `watch()` re-emits on any
  write, so steps 18–19 happen *because of* step 13 — no "reload" call exists.
- **Two "Command"s, on purpose.** `CommandCubit` (MVVM) only guards the button
  lifecycle (Running → disabled). The thing serialised into the outbox is the *GoF*
  `CreateGroupCommand` — different object, different layer, drained in `04`.
- **The write is offline-first's signature move:** group row + outbox slip in one
  transaction — the screen update and the sync intent can never diverge.

**Seams:** DI wiring → `01-startup-di` · the transaction + outbox table →
`03-database-migrations` · what drains the queued command → `04-sync-outbox`.
