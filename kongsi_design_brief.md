# Kongsi — Design Brief & Handover (MVP)

> **For:** Claude Design (or any designer/agent). This is a self-contained brief to generate and iterate the MVP UI.
> **Companion docs:** `kongsi_project_charter.md` (engineering plan), `mobile_system_design_mindmap_v3.html`.
> **Scope of this handover:** MVP screens only. v2 (receipts/OCR, activity feed, realtime presence) is out of scope here.

---

## 0. How to use this file

Produce the MVP screen set below as high-fidelity mobile mockups, in **both light and dark**, at a mobile frame (~390–402px wide). Build the **component library first**, then assemble screens from it. Follow the tokens in §3 exactly; treat hex values as the intended palette, not placeholders. Keep motion minimal and purposeful. You may take **one small, justified aesthetic risk** within the "clean & premium" direction — but spend boldness only on the signature element (§2), and keep everything else quiet.

Tokens must be exportable to both **Flutter `ThemeData`** and **Jetpack Compose `MaterialTheme`** — this design ships to two codebases from one system.

---

## 1. Product & audience

**Kongsi** (Malay/Hokkien: "to share") lets small groups — trip-mates, housemates, couples — log shared expenses, split them fairly, and settle up. It works **offline** and reconciles later. It is *money among friends*, not enterprise accounting.

**Primary job of the app:** answer "who owes whom, right now?" instantly, and make logging an expense take 2–3 taps.

**Tone:** trustworthy, calm, precise. Premium and restrained — closer to Apple Wallet / Apple Card and iOS grouped-settings than to a colourful consumer app. Directional references (for feel, not to copy): Apple Card's transaction clarity, iOS Settings' grouped lists, Monzo/Revolut's fintech legibility — filtered through Apple restraint.

## 2. Design principles & the signature

1. **Clarity over flash.** Numbers are unambiguous. Who owes whom is never hedged.
2. **Offline-honest.** Sync state is always shown truthfully. Pending/failed are calm, expected states — not alarming errors.
3. **Speed to log.** Adding an expense is the hero action: fast, optimistic, instant.
4. **Glanceable balances.** The owe/owed answer is readable in under a second.
5. **One payoff moment.** Settling up gets a small, satisfying confirmation.

**Signature element (spend boldness here, nowhere else):** the **money treatment** — all amounts in tabular numerals, and the balance headline using a deliberate direction system (sign + label + icon + hue). Plus the **settle-up confirmation** as the single delightful beat. Everything surrounding it stays disciplined and quiet.

## 3. Design tokens

### Colour — light

| Token | Hex | Use |
|---|---|---|
| `bg` | `#F6F6F4` | app background (warm-neutral paper, not stark white) |
| `surface` | `#FFFFFF` | cards, sheets |
| `surface-2` | `#EFEFEC` | grouped list background, insets |
| `ink` | `#17171A` | primary text |
| `slate` | `#6C6C72` | secondary text |
| `muted` | `#9A9AA0` | tertiary text, placeholders |
| `hairline` | `rgba(0,0,0,0.08)` | separators, borders |
| `accent` (Kongsi Blue) | `#1B5FE0` | primary actions, links, selection |
| `accent-press` | `#1547B0` | pressed/active |
| `credit` | `#1E8E5A` | "you're owed" / positive |
| `debit` | `#C4443A` | "you owe" / negative |

### Colour — dark

| Token | Hex |
|---|---|
| `bg` | `#0C0C0D` |
| `surface` | `#17171A` |
| `surface-2` | `#202024` |
| `ink` | `#F4F4F3` |
| `slate` | `#9C9CA2` |
| `hairline` | `rgba(255,255,255,0.10)` |
| `accent` | `#5A8CFF` |
| `credit` | `#34C77B` |
| `debit` | `#E5675C` |

> **Money direction must never rely on colour alone.** Always combine hue with a sign (`+`/`−`), a text label ("you owe" / "you're owed"), and a small directional icon. This is an accessibility hard requirement.

### Typography

- **Primary face:** **Geist** (SF-adjacent, premium, free). Alternates if unavailable: Hanken Grotesk, Manrope.
- **Numerals:** Geist with **tabular figures** (`font-feature-settings: "tnum"`) for every monetary value — amounts must align in columns and never shift width.
- **Monospace (metadata only):** Geist Mono for small IDs/dates if desired.

Type scale (tune to taste, keep the hierarchy):

| Role | Size / weight | Notes |
|---|---|---|
| Balance hero | 40–44 / 600, tight tracking | tabular numerals |
| Title L | 28 / 600 | screen titles |
| Title | 22 / 600 | section headers |
| Headline | 17 / 600 | list-row primary |
| Body | 15–16 / 400 | default |
| Callout | 13 / 500 | labels, chips |
| Caption | 12 / 400 | timestamps, meta |

### Spacing, shape, elevation

- **Grid:** 4pt base, 8pt rhythm. Screen side margins 16–20px. Section gaps 24–32px.
- **Radius:** cards 16 · buttons 12–14 · bottom sheets 20–24 (top) · chips/avatars full pill. Prefer a continuous/"squircle" corner feel where the tool allows.
- **Elevation:** minimal. Flat surfaces + hairline separators do the structural work. Soft, diffuse shadow only for the FAB and bottom sheets (low opacity, large blur). Use iOS-style **grouped lists** for forms and settings.

### Motion & animation

**Philosophy:** motion should feel *expensive through restraint* — few animations, each meaningful, driven by natural physics and crisp timing. Continuity between screens (shared elements) is what reads as premium; scattered effects and looping ambient motion read as cheap and AI-generated. When in doubt, animate less. No confetti, no parallax overload, no constant ambient movement.

**Duration tokens** (crisp, never sluggish):
- `micro` 100ms — colour/opacity state changes
- `fast` 180ms — button press, chip cross-fade, tab content
- `base` 240ms — most entrances/exits, sheet content, list inserts
- `emphasis` 320ms — screen push transitions, shared-element morphs
- `signature` 480–560ms — one-off moments only (settle-up confirmation)

**Easing tokens** (never `linear` for movement):
- `signature-out` `cubic-bezier(0.16, 1, 0.3, 1)` — the house ease: expensive, settled ease-out for entrances and shared elements
- `standard` `cubic-bezier(0.4, 0, 0.2, 1)` — general in/out
- `exit` `cubic-bezier(0.4, 0, 1, 1)` — elements leaving
- `spring` (sheets, FAB, shared elements): low/no bounce — Flutter `SpringDescription(mass: 1, stiffness: ~260, damping: ~30)`; Compose `spring(dampingRatio = LowBouncy, stiffness = MediumLow)`

**Micro-interactions:**
- Button press: scale to 0.97, `fast`, spring back — paired with a light haptic.
- Selection (segmented control, member toggle): instant colour move + selection haptic.
- Toggle: thumb spring + light-impact haptic.

**Choreography / per-moment map:**

| Moment | Motion | Timing / ease |
|---|---|---|
| Screen push | Horizontal slide-in + slight parallax on the outgoing screen (iOS-style) | `emphasis` / `signature-out` |
| Bottom sheet (add expense, settle, split) | Spring up from bottom; backdrop dims to ~40% | `spring` |
| **Group card → Group detail** | **Shared-element:** the card morphs into the detail header (name + balance carry through) — the key "expensive" transition, used sparingly | `emphasis` / `signature-out` |
| FAB → Add expense | Optional container-transform: the FAB expands into the sheet | `emphasis` |
| List load | Staggered reveal: first ~6 rows fade + rise 8px at 32ms stagger; remaining rows appear plainly | `base` / `signature-out` |
| Optimistic add | New row expands height + fades in; "Pending" chip fades in | `base` |
| Pending → synced | Chip quietly cross-fades out (or a brief check that fades) | `fast` |
| Balance change | Numerals **count up/down** to the new value (tabular — no width shift). Balance hero + debt rows only | `base` / `signature-out` |
| Offline banner | Slides down on drop, slides up on reconnect | `base` |
| Tab switch | Content cross-fade (no slide) | `fast` |
| Loading | Skeleton shimmer: slow, low-contrast gradient sweep, ~1200ms loop | — |

**Signature moment — settle-up confirmation** (the one indulgence, kept classy): on "Record payment", the button briefly shows progress, then the sheet resolves to a success state — a **checkmark that draws itself** (stroke animation) with a gentle 0.9→1.0 spring scale, the settled amount fading in beneath, and a single soft glow that fades out. **Success haptic.** No confetti, no particles, no bounce. Happens once, ~`signature` duration.

**Haptics** (a large part of the premium feel — specify, don't leave to chance):
- Primary success (expense added, payment settled): success / notification haptic
- Validation error (splits don't sum): warning haptic
- Selection / segmented change: selection haptic
- Button press / toggle: light impact
- Pull-to-refresh threshold: light impact

Map to iOS `UIFeedbackGenerator` / Android `HapticFeedbackConstants` (Flutter: `HapticFeedback`).

**Reduced motion (required fallback):** when the OS reduced-motion setting is on, replace all movement, scale, shared-element morphs and count-ups with simple opacity cross-fades at `fast`; snap numerals to their final value; freeze the skeleton shimmer to a static state.

### Iconography

One clean line set — **Lucide** (or an SF-Symbols-like set). Consistent stroke weight throughout.

### Brand mark

Wordmark "Kongsi" in Geist medium, sentence case. Optional mark: two overlapping rounded shapes suggesting a split/share. Keep it minimal — the identity lives in the type and the money treatment, not a logo.

## 4. Information architecture

Bottom tab bar (2–3 tabs, minimal):
- **Groups** (home)
- **Account**
- *(Activity is v2 — omit for MVP)*

Global **FAB: "Add expense"** on Groups/Group detail. Modal/sheet flows sit above the tabs: add/edit expense, split editor, settle up, create group, invite.

## 5. MVP screen specifications

For each: purpose · key elements · states · copy notes.

**1. Welcome**
Purpose: one-screen value prop + entry. Elements: brand mark, one-line promise, "Get started" (primary) + "I have an account" (text). Copy: promise = "Split expenses with friends. Even offline."

**2. Sign in / Sign up**
Purpose: email + password auth ([ADR-025](docs/adr/ADR-025-email-password-auth.md) — magic link is out of the MVP). Two separate screens reached from Welcome, sharing a layout but not code — they are expected to diverge (sign-up gains a display name and terms; sign-in gains password recovery and a biometric shortcut). Elements, both: email field, password field, "Continue" (primary), legal footnote. States: idle, validating, error (inline, directive). Copy error: "Enter a valid email to continue." No "forgot password" yet — it needs an emailed reset link, so it arrives with the deep-link work in Phase 4.

**3. Biometric lock**
Purpose: gate app open. Elements: lock glyph, "Unlock Kongsi", Face/Touch prompt trigger, "Use passcode" fallback. Minimal, centered.

**4. Groups (home)**
Purpose: overall standing + group list. Elements: **balance summary header** (large tabular hero: net "you owe / you're owed" across all groups), list of **group cards** (name, stacked member avatars, your balance in that group with direction encoding), FAB. States: loading (skeleton cards), empty ("No groups yet. Create one to start splitting." + "Create group"), offline banner, per-group pending badge if unsynced. 

**5. Group detail**
Purpose: the group's ledger + actions. Elements: header (group name, members, **your balance in this group**), primary actions ("Add expense", "Settle up"), **expense list** (paginated, newest first — each row: description, who paid, date, amount, your share, pending/failed chip if unsynced), section for "Balances" entry. States: loading, empty ("No expenses yet. Add the first one."), offline, optimistic (new expense appears instantly with a "Pending" chip), failed-sync row (with inline "Retry").

**6. Add / Edit expense**
Purpose: the hero action. Elements: **large amount input** (numeric keypad, tabular), description field, "Paid by" selector (default: you), "Split" selector (segmented: Equally / Exact / Shares), member list preview, "Save" (primary). States: validating (splits must sum to total — live), error, saving (optimistic — closes immediately, row shows pending). Copy: save button = "Add expense" (create) / "Save changes" (edit); the resulting toast says "Added" / "Saved" — same verb family.

**7. Split editor**
Purpose: divide the amount. Elements: segmented control (Equally / Exact amounts / Shares), per-member rows with editable value + running remainder indicator, live validation banner if it doesn't sum. Copy for mismatch: "RM3.50 left to assign" / "RM2.00 over — adjust a share."

**8. Balances (who owes whom)**
Purpose: simplified debts. Elements: list of directional debt rows ("Aisha owes you RM40", "You owe Ben RM15") with direction encoding, each with a "Settle" action. Note: shows the *simplified* set of transactions. Empty: "All settled up. 🎉" (restrained).

**9. Settle up**
Purpose: record a payment + the payoff moment. Elements: from → to, amount (prefilled with the owed sum, editable), "Record payment" (primary). **Success:** a brief, tasteful confirmation (check animation + "Settled") — the one delightful beat. Copy: button "Record payment" → toast "Settled". Note: MVP only *records* a settlement; no real money moves — make that unambiguous ("This records a payment you made outside the app").

**10. Create group**
Purpose: start a group. Elements: name field, currency selector (locale default), add-members (from contacts or by email/link), "Create" (primary). States: validating, saving.

**11. Invite**
Purpose: bring people in. Elements: shareable invite link (copy + native share), current members list, pending invites. Copy: "Anyone with this link can join {group}." Note for engineering: this is the deferred-deep-link entry — design a clean "You've been invited to {group}" landing for the not-yet-installed recipient (can be a later screen, flag it).

**12. Account & settings**
Purpose: profile + controls, iOS grouped-list style. Groups: Profile (name, avatar, email) · Security ("App lock" biometric toggle) · Preferences (currency, appearance: system/light/dark) · About · Sign out (text) · **Delete account** (destructive, in its own group). States: confirm dialogs for sign-out and delete; delete explains data purge (GDPR-style).

## 6. Component inventory (the expected set — built on demand)

> **Design-side, build these first; engineering-side, do not.** In code a component is written when a screen actually needs it, then reused — charter §6-A warns against building a design system ahead of the screens that would use it. This list is the *expected* inventory, not a work queue. Rough arrival: buttons, text field and the empty-state template in Phase 1 (auth screens); group card, chips, offline banner, skeletons and the balance/currency components in Phase 2 (ledger); amount input, segmented control, bottom sheet and member/debt rows with add-expense and settle-up; avatars with invites in Phase 4.

Buttons: primary (filled accent), secondary (tinted/outline), text, destructive. · Amount input (large, tabular, keypad). · Text field (grouped-list style + standalone). · Segmented control (split type, appearance). · List rows: group card, expense row, member row, debt row, settings row. · Avatar + stacked-avatar cluster. · Chips: pending, failed, split-type, currency. · Offline banner (persistent, calm). · Toast/snackbar. · Bottom sheet. · FAB. · Empty-state template (icon + line + CTA). · Skeleton loaders. · Balance summary header. · Currency amount display (the tabular money component — used everywhere).

## 7. State matrix (apply to every data screen)

| State | Treatment |
|---|---|
| Loading | Skeletons matching final layout (no spinners on lists) |
| Empty | Icon + one directive line + a clear CTA ("an empty screen is an invitation") |
| Error | Plain, directive, in the interface's voice: what happened + how to fix. No apologies |
| Offline | Persistent calm banner: "You're offline. Changes will sync when you're back." |
| Optimistic | Item appears immediately with a "Pending" chip; resolves silently on sync |
| Failed sync | Row shows "Failed" chip + inline "Retry"; never blocks the rest of the UI |

## 7-A. Form validation (apply to every input in the app)

Any field with a rule — email format, password length, phone number, an amount
that must sum — follows the same timing, so validation never feels different from
one screen to the next:

1. **Silent while first typing.** No error before the user has tried to submit.
   Telling someone their email is invalid after one character is nagging.
2. **On submit, all rules run** and every failing field shows its message
   directly beneath it.
3. **After that, live.** While a field is showing an error it re-checks on every
   keystroke and the message clears the moment the input becomes valid.

In Flutter this is exactly `AutovalidateMode.onUserInteractionIfError` on the
`Form` — not `onUserInteraction` (errors from the first keystroke) and not
`onUnfocus` (the message goes stale while being fixed). Messages are directive
per §8: "Enter a valid email to continue.", not "Invalid email".

**Leaving a screen is not idle.** A form that has submitted successfully stays
disabled until it is gone. Re-enabling it during the navigation makes the fields
and button flash back to normal for a frame.

## 8. Voice & microcopy rules

- Active voice, sentence case, plain verbs. An action keeps its name through the flow ("Add expense" → toast "Added").
- Name things by what the user controls ("App lock", not "biometric auth config").
- Errors are directive, never vague, never apologetic.
- Empty states are invitations to act.
- Money is always shown with currency + tabular figures + direction; never a bare number where direction matters.

## 9. Accessibility & i18n (hard requirements)

- Contrast ≥ WCAG AA; **no meaning by colour alone** (money direction especially).
- Tap targets ≥ 44–48dp. Support dynamic type / text scaling without breaking layout.
- **RTL layouts** fully supported.
- Locale-aware currency and number formatting; tabular figures for alignment.
- Screen-reader labels on every amount and balance ("You owe Ben 15 ringgit").

## 10. Deliverables & how to iterate

1. Component library (light + dark).
2. All 13 MVP screens (light + dark), assembled from components.
3. The key flows shown as sequences: onboard/auth → create or join group → add expense → view balances → settle up → invite.
4. Describe or prototype the key transitions from the Motion spec — screen push, the group-card shared-element morph, optimistic add, and the settle-up confirmation — plus the haptic pairings.
5. Note any screen where you took the one allowed aesthetic risk, and why.

Iterate via chat. When done, the tokens (§3) get exported into the Phase 0 design-system setup in the engineering charter — so keep them clean and named.

---

### Open design questions to resolve during iteration
- Exact currency-picker UX (searchable list vs common-first).
- Whether "Balances" is a tab within Group detail or a pushed screen (lean: pushed screen for MVP).
- Contacts permission moment for invites (design the pre-permission priming screen).
