# ADR-007: Deep-link / attribution provider

**Status:** Open — deferred to Phase 4 spike

## Context

Group invites (F3, v2's deferred deep-linking) need a link that works whether or not the recipient has the app installed: if installed, open directly into the invite/join flow; if not, install first, then land on the same flow (deferred deep linking + install attribution). **Firebase Dynamic Links, the obvious default, was discontinued in August 2025**, so the previously "easy" choice no longer exists.

## Decision

**Not yet decided.** This ADR is deliberately left open until Phase 4, when a short, time-boxed spike will evaluate current options against this project's actual needs (self-hosted vs vendor, cost at hobby-project scale, Flutter SDK maturity):

- **Branch** — mature deferred deep-linking + attribution vendor, likely the closest replacement to what Dynamic Links did.
- **AppsFlyer** — similar category, more attribution/marketing-analytics-oriented; possibly heavier than needed here.
- **DIY deferred-link scheme** — roll a minimal version using `go_router`'s typed routes (already deep-link-ready per ADR-010) plus a Supabase-backed short-link table and platform clipboard/install-referrer tricks for deferred attribution. More work, but zero vendor dependency and a stronger "I built this" interview story.

## Consequences

Deferring this decision is itself the decision for now: routing is already built deep-link-ready from Phase 0 (ADR-010), so nothing is blocked by leaving the vendor choice open. The risk of deferring is re-litigating platform SDK integration later rather than now — accepted, because picking wrong now (before the Phase 4 spike has real requirements to test against) is a worse outcome than a short delay.

## Alternatives considered

Deferred to the Phase 4 spike itself — see Decision above for the shortlist to evaluate at that time.
