# Architecture Decision Records — Kongsi

| ADR | Title | Status |
|---|---|---|
| [001](ADR-001-backend-supabase-firebase.md) | Backend = Supabase + Firebase | Accepted |
| [002](ADR-002-state-management.md) | State: Riverpod (DI) + Bloc/Cubit (feature) + Command (writes) | Accepted |
| [003](ADR-003-offline-strategy.md) | Offline = local DB SSOT + outbox/Command + idempotency | Accepted |
| [004](ADR-004-no-certificate-pinning.md) | No certificate pinning; TLS + NSC + Play Integrity | Accepted |
| [005](ADR-005-local-database-drift.md) | Local DB = Drift | Accepted |
| [006](ADR-006-conflict-resolution.md) | Conflict resolution = LWW (v1) | Proposed |
| [007](ADR-007-deep-link-provider.md) | Deep-link/attribution provider | **Open** — Phase 4 spike |
| [008](ADR-008-background-sync.md) | Background sync = WorkManager/BGTaskScheduler, same outbox | Accepted |
| [009](ADR-009-error-model.md) | Error model = Result/Failure, no leaked exceptions | Accepted |
| [010](ADR-010-routing.md) | Routing = go_router, deep-link-ready | Accepted |
| [011](ADR-011-package-id.md) | Package ID = com.wilbajamas.kongsi | Accepted |
| [012](ADR-012-toolchain.md) | Toolchain = FVM-pinned Flutter 3.41.4 | Accepted |
| [013](ADR-013-config.md) | Config = single typed AppConfig | Accepted |
| [014](ADR-014-clock-uuid.md) | Clock + UUID are injected abstractions | Accepted |
| [015](ADR-015-android-sdk-targets.md) | Android minSdk = 26 | Accepted |
| [016](ADR-016-ios-deployment-target.md) | iOS deployment target = iOS 16 | Accepted |

Only **ADR-007** remains genuinely open, deferred to its Phase 4 spike by design.
