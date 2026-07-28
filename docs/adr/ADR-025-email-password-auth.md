# ADR-025: Auth is email + password; magic link is out of the MVP

**Status:** Accepted
**Date:** 2026-07-28

## Context

The design brief (§5, screen 2) specified passwordless sign-in: an email field, a
"Continue" button, and "Email me a link instead" — no password field anywhere.
Charter §3 and §10 listed "email/password + magic link" together.

Building it exposed the dependency. A magic link only works if the app can receive
the link the user taps in their email, which means app links / universal links,
the callback handling, and a redirect URL configured per flavor. That is the
Phase 4 deep-link suite, which also carries its own spike (Firebase Dynamic Links
shut down in Aug 2025, so the vendor question is open).

Phase 1 is the auth and session phase. Pulling the deep-link stack forward to
satisfy the sign-in screen would have made it the deep-link phase as well, and
would have pushed the actual learning goal — the hand-built 401 → refresh → retry
path — to the end of a much longer phase.

## Decision

**Email + password is the MVP's authentication, permanently. Magic link is
dropped from the MVP**, not deferred within it.

- Design brief §5 screen 2 is rewritten around email + password.
- Screen 3 ("Magic link sent") is deleted from the MVP screen list.
- Charter §3 and §10 drop the magic-link mention.

## Consequences

**Positive**

- Phase 1 stays about sessions and tokens.
- Sign-in works with no email round trip, which also makes it far easier to test
  by hand and on a device.
- One less vendor-shaped question in the MVP.

**Negative / accepted trade-offs**

- **The deep-link dependency is moved, not removed.** "Forgot password" needs an
  emailed reset link — the same mechanism magic link needed. The difference is
  that it is a *recovery* path rather than the only way in, so the app is usable
  without it. Password reset joins Phase 4. Until then, a locked-out user needs a
  password reset triggered from the Supabase dashboard.
- **We now store passwords' worth of risk** in the sense that users pick and reuse
  passwords, which passwordless auth avoids by design. Supabase handles hashing
  and storage; the app never sees a password beyond the sign-in call.
- Email confirmation is off on the dev project for the same reason (it needs the
  same link handling). Turning it on is Phase 4 work, and it must be on before any
  real release — an unconfirmed-email signup path is an abuse vector.

## Related

- ADR-001 (Supabase primary — its mention of magic link describes a Supabase
  capability, not a commitment here), ADR-007 (deep-link provider, still open,
  Phase 4 spike), charter §18 Phase 4.
