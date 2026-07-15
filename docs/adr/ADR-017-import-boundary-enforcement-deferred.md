# ADR-017: Automated import-boundary enforcement deferred

**Status:** Deferred
**Date:** 2026-07-15

## Context

Charter §6 requires `domain` import nothing from Flutter, `data`, or any outer layer — a boundary meant to be "enforced, not suggested," since an unenforced architecture rule decays within a few sprints (charter's own words). Two tools were tried to enforce this automatically via `dart analyze`:

- **`import_rules`** — uses Dart's native analyzer-plugins system (added Dart 3.10/Flutter 3.38, genuinely new). Configuration was verified correct against the package's own docs, but `dart analyze` hung indefinitely (4+ minutes on a near-empty project) rather than completing or erroring.
- **`import_lint`** — a different package, but confirmed to use the *same* native analyzer-plugins system underneath. Same category of risk, not a real alternative.
- **`custom_lint`** — a more established, widely-used framework (powers `riverpod_lint`, `freezed`), but ships no ready-made import-boundary rule. Adopting it means hand-writing a lint rule (real Dart code: walk import directives, check against target/disallow patterns) — a legitimate but non-trivial scope addition at a point where no feature code exists yet to protect.

## Decision

Defer automated enforcement. The boundary rule stays documented (charter §6, this ADR) and is enforced manually via code review discipline for now. Revisit once either the native analyzer-plugins ecosystem matures past its current early-stage reliability, or once real feature code exists across multiple features, making a hand-written `custom_lint` rule a clearly justified investment rather than upfront speculative tooling.

## Consequences

**Positive**
- Avoids sinking further time into a bleeding-edge Dart SDK feature that failed to complete a basic `analyze` run on a near-empty project — a strong signal it isn't reliable enough to depend on yet.
- Doesn't block Phase 0 progress on a nice-to-have automation layer.

**Negative / accepted trade-offs**
- Boundary violations (e.g. a stray `import 'package:flutter/material.dart';` inside `domain/`) won't be caught automatically until this is revisited — relies entirely on manual review discipline in the meantime, which is exactly the failure mode this rule was meant to prevent. This is a real, acknowledged risk, not a dismissed one.

## Alternatives considered

See Context above — `import_rules` and `import_lint` (both hit/share the same underlying reliability issue), and `custom_lint` with a hand-written rule (viable, deliberately deferred rather than rejected — reconsider once there's enough real feature code to justify writing and maintaining a custom rule).
