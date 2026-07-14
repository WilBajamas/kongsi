# ADR-001: Backend = Supabase (data/auth/realtime) + Firebase (platform services)

**Status:** Accepted
**Date:** 2026-07-14

## Context

The developer is frontend-only with no backend engineering background. The project needs auth, a Postgres-backed data store, row-level authorization, realtime sync (v2), and file storage (v2) — without taking on the cost of designing, hosting, and operating a custom backend. Separately, the app needs platform services: push delivery, crash reporting, analytics, feature flags, and distribution tooling for testers.

## Decision

Use **Supabase** as the primary backend: Postgres database, auto-generated PostgREST API, built-in auth (email/password + magic link), Row-Level Security for authorization, Realtime (v2), and Storage (v2).

Use **Firebase** strictly for platform services, not as a second backend: FCM (push), Crashlytics, Analytics, Remote Config, A/B testing, App Distribution, Test Lab.

The only backend code written by hand is small declarative SQL (RLS policies) and one small serverless function (Supabase Database Webhook / Edge Function → FCM HTTP v1) to trigger push notifications — see ADR notes in charter §10.

## Consequences

**Positive**
- No custom server to design, deploy, or operate — matches the developer's frontend-only skill profile.
- Postgres + RLS gives a gentle, high-value introduction to backend authorization concepts without requiring general backend engineering.
- Supabase's Postgres foundation pairs naturally with Drift (ADR-005) — both are relational, so the local mirror and the source of record share a mental model.
- Firebase is scoped narrowly to platform services it's genuinely best-in-class at (FCM, Crashlytics, App Distribution), avoiding overlap/conflict with Supabase's own auth and realtime.

**Negative / accepted trade-offs**
- Two vendor dependencies instead of one; if Supabase has an outage, auth/data are unavailable regardless of Firebase's health.
- The FCM trigger requires one serverless function — the one place "backend-shaped" code exists. Explicitly flagged as a contained learning slice, not to be allowed to grow (charter §10).
- Vendor lock-in to Supabase's Postgres/RLS/Auth model; migrating off it later would be a real project, not a config change.

## Alternatives considered

- **Firebase for everything (Firestore + Auth)** — rejected: Firestore's NoSQL model doesn't mirror well to a relational ledger with joins (balances, splits), and RLS-equivalent Firestore security rules are less transferable as an interview story about SQL-based authorization.
- **Custom backend (Node/Go + Postgres)** — rejected: outside scope given no backend skills, and directly contradicts the project's stated non-goal ("Building our own backend / auth server").
