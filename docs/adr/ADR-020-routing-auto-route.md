# ADR-020: Routing = auto_route (supersedes ADR-010)

**Status:** Accepted
**Date:** 2026-07-17
**Supersedes:** ADR-010

## Context

ADR-010 chose `go_router` for deep-link-ready routing and explicitly considered `auto_route`, rejecting it mainly on dependency risk (community package vs Flutter-team-maintained). Revisiting before any routing code shipped: the priorities that matter most here are compile-time-typed routes/arguments and ergonomic nested routing + guards (the app has a bottom-tab shell, §4, and a Phase 1 auth/biometric gate). With `go_router`, typing is opt-in codegen (`go_router_builder`) and nested shells/guards are more manual; `auto_route` provides all of these by default. The dependency-risk concern was re-weighed, and — critically — `auto_route_generator` was verified to resolve cleanly against the project's Drift/`analyzer` toolchain (unlike Riverpod's generator, which clashed and forced hand-written providers). The deep-link-contract intent of ADR-010 carries over unchanged, since `auto_route` is path-based.

## Decision

- Use **`auto_route`** (+ `auto_route_generator`) for app routing; this **supersedes ADR-010**.
- Routes are declared in an `@AutoRouterConfig` `RootStackRouter` (`lib/app/router/app_router.dart`) and the router is provided through DI (`appRouterProvider`, in the **app** layer — `core` must not depend on `app`).
- The route table **is** the deep-link contract. Path table designed now, implemented incrementally: `/` (home) exists; `/auth`, `/groups/:id`, `/invite/:token` are designed-but-unbuilt paths that features (and Phase 4 invites) will fill in.
- The auth/biometric gate is an `AutoRouteGuard`, added in Phase 1.
- Generated `*.gr.dart` is committed, consistent with the project's other codegen (Drift, l10n).

## Consequences

**Positive**
- Routes and their arguments are **compile-time typed by default** — no stringly-typed route names/arguments, and no separate opt-in builder to keep the typing.
- Nested routing (`AutoTabsRouter`) and route guards are first-class, matching the bottom-tab IA and the Phase 1 auth gate without manual shell plumbing.
- Deep-link-contract intent from ADR-010 is preserved; the path shape is designed in Phase 0 so Phase 4 attaches to a stable table.
- Codegen verified compatible with the Drift/`analyzer` toolchain, so this doesn't reintroduce the conflict that blocked Riverpod codegen.

**Negative / accepted trade-offs**
- `auto_route` is community-maintained, not Flutter-team — the dependency risk ADR-010 originally weighed. Accepted: the package is mature and widely adopted, and the typing/nesting ergonomics are worth it.
- Routing now depends on a `build_runner` codegen step (routes must be generated before they compile) — already part of this project's stack.
- A slightly heavier abstraction than `go_router`'s plain declarative table.

## Alternatives considered

- **`go_router` (ADR-010's choice)** — still viable; reversed because typed routes require the opt-in `go_router_builder` and nested shells/guards are more manual than `auto_route`'s defaults.
- **`go_router` + `go_router_builder`** — recovers typing but still lacks `auto_route`'s ergonomic nested routing/guards; not chosen.
