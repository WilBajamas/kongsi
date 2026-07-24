# 01 · Startup / DI + the four error nets

**Type:** sequence — startup *is* an order; the ordering is the content.
**Source:** [technical-summary §3](../technical-summary.md) + §7 (error nets) · [bootstrap.dart](../../lib/bootstrap.dart)

```mermaid
sequenceDiagram
    autonumber
    participant Main as main_dev.dart
    participant Boot as bootstrap()
    participant FW as Flutter framework
    participant Talker as talker · Talker
    participant Cont as ProviderContainer
    participant Sync as SyncBloc

    Main->>Boot: bootstrap(AppConfig.fromEnvironment())
    Boot->>Talker: createLogger()
    Boot->>FW: FlutterError.onError = talker.handle · net ①
    Boot->>FW: PlatformDispatcher.instance.onError = talker.handle · net ②
    Boot->>Boot: runZonedGuarded(...) · net ③ — everything below runs inside
    Boot->>FW: WidgetsFlutterBinding.ensureInitialized()
    Boot->>Cont: ProviderContainer(overrides: [appConfig, talker, commandRegistry])
    Note right of Cont: appConfig — TIMING: value born at runtime<br/>commandRegistry — LAYERING: built from the app catalog core can't import<br/>talker — same instance the nets write to

    opt dev flavor only
        Boot->>Cont: read(appDatabase, clock, uuid)
        Boot->>Boot: await seedDevGroups(...) · writes groups table, see 03
    end

    Boot->>FW: Bloc.observer = AppBlocObserver(talker) · net ④ ⚠ mutable static — set once, here only
    Boot->>FW: runApp(UncontrolledProviderScope(container, MainApp))
    Boot->>Cont: read(syncBlocProvider) — "eager" = just an early read
    Cont-->>Boot: SyncBloc (graph built lazily, now)
    Boot->>Sync: add(SyncRequested()) · first drain, see 04

    Note over FW,Sync: — later, at runtime: all four nets funnel into one logger —
    FW--)Talker: handle(error) · net ① framework build/layout/paint
    FW--)Talker: handle(error) · net ② async with no local handler
    Boot--)Talker: handle(error) · net ③ zone catch-all (last resort)
    Sync--)Talker: handle(error) · net ④ any Bloc/Cubit onError, via AppBlocObserver
```

**Reading it**

- The two `throw UnimplementedError()` providers (`appConfig`, `commandRegistry`) fail
  loud at step 7 if an override is forgotten — timing vs layering, same fix.
- The only load-bearing ordering after the zone: net ④ before the sync kick, because
  `read(syncBlocProvider)` creates the app's **first Bloc**. The kick sits after
  `runApp` by priority (optional background work never delays or prevents the first
  frame), not by necessity.
- All four nets end in one `talker.handle` — one logger, one stream.

**Seams:** the DB the seed writes → `03-database-migrations` · the drain `SyncRequested`
starts → `04-sync-outbox` · the widget tree `runApp` mounts → `02-groups-slice`.
