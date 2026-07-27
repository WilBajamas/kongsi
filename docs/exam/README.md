# Kongsi — Phase 0 Exam

The Post-Phase-0 consolidation, deliverable (c) (charter §6-A). This is not a quiz on
recall — it's a **defense** of every decision Phase 0 made. Authored by the mentor,
sat by you, whenever you're ready.

## How to sit it

- **Self-paced. No time limit, no fixed duration.** A section is done when you can
  defend it, not when a clock runs out.
- **Open book.** Reference the code, the [technical summary](../technical-summary.md),
  the [learning log](../learning-log.md), the [ADRs](../adr/README.md), and the
  [diagrams](../diagrams/). The bar is **explaining every decision and its
  trade-offs**, not remembering them cold.
- **One coherent section at a time** — not a mixed grab-bag. Sit them in order or
  pick a topic; each stands alone.
- The learning log is the **study spine**; each section names its spine up top.

## The stance: an interviewer who has never seen this project

From §02 onward, every section is written as a **real interview**. The interviewer
knows Flutter, architecture, and mobile engineering well — but has **never seen
Kongsi**. So the questions are general ("how would you handle X?"), and **you bring
the project as your evidence**.

That's deliberately harder than a quiz on your own code. It tests whether the
knowledge **transfers** — whether you understood the idea, or just remember what you
typed. If an answer only makes sense to someone who has read your files, it hasn't
landed.

**The rule this puts on the questions** (so the stance doesn't quietly drift):

- A question **never states a fact about the project**. Not the libraries, not the
  patterns, not the file layout. All the interviewer has is one line: *"an
  expense-splitting app that works offline."*
- A follow-up may only build on **what you'd have said out loud earlier** in that same
  sheet — never on what's in the repo.
- A pushback attacks the **general approach** ("some people do X — isn't that risky?"),
  never "your code does X."

*(§01 was written before this shift and reads as an insider exam; §02 still leaks some
project knowledge into its wording. Both left as-is — they're still fair tests of the
material.)*

## The question types

Every section mixes whichever of these fit the topic:

| Type | What it asks |
|---|---|
| **Warm-up** | The opener an interviewer actually starts with. Plain words, no jargon. |
| **Main** | The meat. "Why X over Y", "what breaks if…", approaches **used and rejected**. |
| **Pushback** | Where the interviewer challenges the decision and you hold or concede. |
| **Kata** | *(optional)* A small code task, for when you want the hands-on practice. `analyze --fatal-infos` + `test` are the pass check. Skipping it doesn't fail the section. |

## The viva

Each section ends with **viva prompts** — attacks on the decisions. You sit the
written + kata parts solo; then, in a live session, the mentor plays hostile
interviewer and you **defend the trade-offs out loud**. That live defense is where the
section is actually graded — the written work is preparation for it.

## Grading — there is no answer key, on purpose

The technical summary + learning log + code **are** the key (it's open book). Instead,
each section ends with a **rubric**: the criteria a lead-level answer must hit. Grade
your own written answers against it between sessions; the viva is the real test.

A **lead-level** answer (vs senior) consistently:

- **names the rejected alternative** and why it lost, not just the choice made;
- **concedes the honest trade-off** instead of pretending the choice was free;
- reasons about **cost-to-change and blast radius**, not just correctness;
- can say **when the decision would flip** (different scale, team, constraints).

## Sections

| # | Topic | Spine |
|---|---|---|
| [01](01-architecture-layering.md) | Architecture & layering | summary §2, §4 · diagram 02 |
| [02](02-dependency-injection.md) | DI & app startup | summary §3 · diagram 01 |
| [03](03-offline-sync.md) | Offline-first & syncing | summary §5 · diagram 04 |
| 04 | Network stack & error model | summary §7 · diagram 05 |
| 05 | Database & migrations | summary §6 · diagram 03 |
| 06 | Platform interop | summary §8 · diagram 06 |
| 07 | Testing doubles | summary §10 |
| 08 | Versioning & build numbers | summary §11 |
| 09 | CI/CD & reproducibility | summary §12, §13 · diagram 07 |
| 10 | Dependencies, toolchain & modern Dart | summary §14, §15 |

*(01–03 are drafted; the rest land as the exam is authored.)*
