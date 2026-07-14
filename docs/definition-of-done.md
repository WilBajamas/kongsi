# Definition of Done

A change is done when all of the following hold:

- [ ] `fvm flutter analyze` — clean, no warnings
- [ ] `fvm dart format --set-exit-if-changed .` — no diff
- [ ] Relevant tests added and passing (unit/widget/golden as applicable)
- [ ] No exceptions leak past the data layer (Result/Failure only, per [ADR-009](adr/ADR-009-error-model.md))
- [ ] Offline-affecting changes verified against airplane-mode behavior
- [ ] UI changes manually verified on-device/emulator, light and dark
- [ ] No secrets, keys, or `config/*.json` committed
- [ ] No dangling `TODO` without a linked follow-up
