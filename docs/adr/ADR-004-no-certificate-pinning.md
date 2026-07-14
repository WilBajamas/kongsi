# ADR-004: No certificate pinning; enforce TLS + Network Security Config + Play Integrity

**Status:** Accepted
**Date:** 2026-07-14

## Context

Mobile security guidance historically recommended certificate pinning to defend against MITM attacks. Current (2025) OWASP/Google guidance has shifted: pinning creates real operational risk (app-breaking outages on legitimate cert rotation, CA changes, or CDN migration) that, for an app like this, outweighs the marginal security benefit over TLS alone plus platform-level integrity attestation.

## Decision

- Enforce TLS on all network traffic.
- Use Android **Network Security Config** to disallow cleartext traffic entirely.
- Use **Play Integrity API** for app/device integrity attestation instead of pinning.
- **No certificate pinning** in production. If demonstrated at all, it's implemented behind a flavor flag purely as a learning exercise, with an explicit note on why it would be disabled in production.

## Consequences

**Positive**
- Avoids a well-documented failure mode: pinned apps going dark for all users the moment a cert rotates unexpectedly, with no server-side fix available — a self-inflicted outage risk disproportionate to the threat it mitigates for a non-banking app.
- Network Security Config + enforced TLS still closes the most common real-world gap (accidental cleartext, downgrade attacks).
- Play Integrity gives device/app authenticity signal without the fragility of a pinned cert chain.
- Matches current platform vendor guidance rather than a carried-over best practice that's since been revised.

**Negative / accepted trade-offs**
- Marginally weaker defense against a sophisticated, targeted MITM attack with a compromised or coerced CA — accepted as out of this app's realistic threat model (it is not handling real money transfer, per the product's explicit non-goals).
- If pinning is demoed for learning purposes, it must be clearly flagged as non-production to avoid it silently becoming load-bearing.

## Alternatives considered

- **Standard certificate pinning (public key or cert pinning)** — rejected per current guidance and the outage-risk trade-off above.
- **No TLS enforcement / trust default OS behavior only** — rejected: Network Security Config cleartext-blocking is low-cost and closes a real, common gap.
