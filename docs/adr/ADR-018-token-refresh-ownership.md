# ADR-018: Single token-refresh owner — Supabase SDK vs the hand-built dio interceptor

**Status:** Accepted
**Date:** 2026-07-16

## Context

Charter §10 asks for a hand-built dio interceptor that catches `401`, refreshes the token, and retries — explicitly as a learning exercise ("build it by hand at least once"), since sessions/tokens is a named weak spot. But ADR-001 makes Supabase primary, and the `supabase-flutter` SDK **already manages the access/refresh token pair and auto-refreshes internally**.

That creates a real risk, not just a redundancy: Supabase rotates refresh tokens (each successful refresh can invalidate the previous refresh token). If two mechanisms — the SDK and a hand-built dio refresh — each independently hold and rotate the *same* refresh token, one will rotate the token out from under the other, and the loser's next refresh fails. The symptom is spurious, hard-to-reproduce logouts.

## Decision

**There is exactly one token-refresh owner: the Supabase SDK.** The hand-built dio interceptor never independently owns or rotates tokens — it delegates.

Concretely:

- **Supabase data/auth calls** (the majority of the app) go through the Supabase client and rely on its built-in auto-refresh.
- **Direct calls to non-Supabase endpoints** (e.g. the FCM-trigger Edge Function, or any custom API) go through our dio stack, which includes the hand-built `AuthInterceptor`.
- The interceptor gets tokens through an `AuthTokenProvider` abstraction. Its real (Phase 1) implementation delegates to the SDK:
  - `accessToken` → `supabase.auth.currentSession?.accessToken`
  - `refreshToken()` → `supabase.auth.refreshSession()`

So even the dio path defers rotation to the SDK. One owner, two callers.

The learning value is preserved: the interceptor *mechanics* (401 detection, the `QueuedInterceptorsWrapper` + `Completer` concurrency lock so simultaneous 401s trigger only one refresh, retry-once guard) are still hand-built. Only the token rotation itself is delegated.

## Consequences

**Positive**
- Eliminates the double-refresh / token-rotation race that causes spurious logouts.
- Keeps the hand-built interceptor exercise (concurrency, retry, 401 handling) intact — the part that's actually the learning.
- The `AuthTokenProvider` seam means this decision required no change to the interceptor code; it's satisfied entirely by how the Phase 1 implementation is written.

**Negative / accepted trade-offs**
- The interceptor doesn't *fully* hand-roll the refresh HTTP call against Supabase's `/token` endpoint — token rotation is delegated. Fully owning the raw refresh call would only be appropriate against a custom endpoint where we own the whole token lifecycle, not over Supabase's tokens. Accepted: correctness beats a more complete-but-dangerous exercise.

## Phase 1 implementation guardrails (record now, apply later)

- **No proactive expiry check needed for Supabase calls** — the SDK already refreshes proactively. A proactive check would only matter for a custom endpoint where we own tokens; skip it for now (reactive 401-based refresh first).
- **If refresh is ever done via raw dio** (custom endpoint case), use a separate bare `Dio` with no `AuthInterceptor`, so a `401` on the refresh call can't recurse into another refresh.
- **`flutter_secure_storage`** (charter §13) is mainly for backing the SDK's session persistence or for a custom-endpoint token lifecycle — not for independently storing Supabase's refresh token in parallel with the SDK.

## Addendum — 2026-07-28: the split is about refresh, not about HTTP clients

Adding `supabase_flutter` in Phase 1 exposed that the bullet list above describes something the code does not do, and never did.

It says Supabase data calls "go through the Supabase client" and only non-Supabase endpoints go through dio. But `SupabaseCommandSender` — the app's *only* write path — posts to Supabase's own PostgREST endpoint **through dio**. Nobody noticed while `NoAuthTokenProvider` was in place, because with no token the two paths were indistinguishable.

**Clarification: this ADR is about who rotates the refresh token, not about which HTTP client sends bytes.** The decision sentence — *there is exactly one token-refresh owner* — is unchanged and still holds: `SupabaseAuthTokenProvider` asks the SDK for the access token and asks the SDK to refresh it, so rotation stays in one place no matter who makes the request.

**The write path stays on dio, deliberately.** Two reasons:

- The SDK refreshes *proactively*, on a timer before expiry. It does **not** catch a `401` on a request that already failed and retry it. Those solve the problem from opposite ends, so the hand-built interceptor is doing work the SDK does not do — not duplicating it.
- It means the interceptor guards a path the app actually uses, rather than sitting idle until the first non-Supabase endpoint appears (Phase 5's Edge Function). Charter §10 asks for this to be built by hand once; a version that never runs in production would not honour that.

The trade-off accepted: two clients can now reach Supabase, and a future reader could reasonably use either. The rule is that **data writes go through dio; auth goes through the SDK** — and nothing else caches a token.

## Related

- ADR-001 (Supabase primary), charter §10 (token exercise), ADR-009 (errors map to typed `Failure` past the interceptor).
