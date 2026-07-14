# ADR-010: Routing = go_router, typed routes, deep-link-ready from Phase 0

**Status:** Accepted
**Date:** 2026-07-14

## Context

The invite flow (F3, Phase 4) depends on deep links, and the route table itself is the contract that flow builds on. Bolting deep-link support onto an ad-hoc navigation stack after the fact is a known-painful retrofit — routes end up ambiguous, path parameters untyped, and link handling scattered. The charter requires routing be designed deep-link-ready in Phase 0 even though the invite feature itself ships much later (Phase 4).

## Decision

Use **`go_router`** with typed routes, designed as a deep-link contract from day one — even though no deep-link feature exists yet in Phase 0.

## Consequences

**Positive**
- `go_router`'s declarative, URL-based routing model maps directly onto deep links — a route defined for in-app navigation is, by construction, already a valid deep-link target.
- Typed route parameters catch invalid navigation calls at compile time rather than via stringly-typed route names/arguments.
- When Phase 4 (invites) and ADR-007 (deep-link/attribution provider) land, they attach to an existing, stable route table instead of requiring a navigation-layer rewrite.
- Matches Flutter's current recommended navigation approach, keeping the codebase aligned with ecosystem conventions (useful for future maintainers and for the interview story).

**Negative / accepted trade-offs**
- Requires thinking through the eventual deep-link route shape (e.g. `/groups/:groupId/invite/:token`) now, before the invite feature exists — some up-front design work that a simpler `Navigator.push`-based approach would defer.
- `go_router`'s declarative model has a steeper initial learning curve than imperative push/pop navigation for simple flows.

## Alternatives considered

- **Imperative `Navigator` push/pop with a custom deep-link parser bolted on later** — rejected: exactly the retrofit pattern this ADR exists to avoid; the charter calls this "genuinely miserable" to add after the fact.
- **`auto_route`** (codegen-based routing) — viable alternative with similar deep-link characteristics; not chosen primarily because `go_router` is the more widely adopted, Flutter-team-maintained option, reducing dependency risk.
