# 03 · Offline-first & syncing

**Study spine:** [technical-summary §5](../technical-summary.md) ·
[learning log → Sync / offline architecture](../learning-log.md) ·
[ADR-003](../adr/ADR-003-offline-strategy.md) · [ADR-006](../adr/ADR-006-conflict-resolution.md) ·
[ADR-008](../adr/ADR-008-background-sync.md)

> **Read this as an interview.** The interviewer knows mobile engineering well but has
> **never seen your project** — all they know is one line: *"an expense-splitting app
> that works offline."* Nothing else. So every question is general, and **you** bring
> the project in as your evidence. If an answer assumes they've read your code, it
> hasn't landed.
>
> The **kata at the end is optional** — answer it if you want the practice, skip it
> otherwise.

---

## Warm-up

1. People throw around "offline-first" pretty loosely. What does it actually mean to
   you, and how is it different from an app that just caches some data?

2. A user opens your app in airplane mode and creates something. Walk me through what
   happens, from the tap to the moment it's on the server.

## The main questions

3. In an app like that, what's the source of truth — the phone or the server? What
   made you land where you did, and what does that decision cost you?

4. When someone makes a change with no connection, how do you make sure it actually
   reaches the server later? What's the mechanism?

5. What stops the same change being sent to the server twice?

6. There are three delivery guarantees people talk about: at-most-once, at-least-once,
   exactly-once. Which are you aiming for, and why not one of the others?

7. Say one queued change is broken — the server rejects it every single time. What
   happens to it, and what happens to everything queued behind it?

8. How do you tell the difference between "this change is bad" and "the network is
   down"? Does your retry logic treat those two the same way?

9. What actually triggers the sending? Is it on a timer, on user action, something
   else?

10. Two people edit the same expense while both are offline. They both come back
    online. What happens?

## The pushback

11. "You've essentially built a message queue inside a phone app. That's a lot of
    machinery for a bill-splitting app — why not just retry the API call a few times
    and show an error if it fails?"

12. "You're storing user actions as data and replaying them later. So what happens when
    you ship a new version of the app and someone still has old actions sitting in
    their queue that don't match the new code?"

13. "A product owner tells you a duplicate charge showed up once. Explain to them, in
    their language, why your system can produce a duplicate at all — and why that's
    the right design."

14. "Someone goes on holiday, uses the app offline for two weeks, and comes back with
    hundreds of queued changes. What happens when they reconnect?"

15. "What part of this would you say you got wrong, or would build differently next
    time?"

## Kata *(optional)*

Add a **new kind of change** to the sync system end to end — pick something plausible
for the app, like renaming a group. Wire it from the user action all the way through to
the server call.

Then answer: **how many existing files did you have to modify to do it?** Whatever the
number is, explain why it's that number, and whether you think it should be lower.

## Rubric — a lead-level answer covers

- **Offline-first defined properly** — the local store is where writes *land*, not a
  cache in front of the network. A cache is read-side and can be thrown away; this
  can't, because it holds data the server has never seen.
- **The local-database-as-truth trade-off named**, not just the benefit: the app is
  instant and works anywhere, but the phone can now hold state the server disagrees
  with, and that gap is what all the rest of the machinery exists to close.
- **The queue described as a pattern, not an invention** — the change and the "this
  needs sending" record are written *together*, so the screen and the sync intent can
  never disagree. A lead names the atomicity; a mid-level answer just says "I save it
  and send it later."
- **Idempotency explained by mechanism** — an id generated *on the device* means a
  repeat lands on the same row instead of creating a second one. Connects this to the
  delivery-guarantee choice rather than treating them as separate topics.
- **At-least-once chosen deliberately**, with exactly-once named as impractical over an
  unreliable network — same end result, far less machinery — and at-most-once rejected
  because losing a user's data is the worst outcome available.
- **Both failure traps identified** in Q7: infinite retries *and* one bad item blocking
  everything behind it in a strict queue. Names the escape hatch (park it aside) and
  what the user experience is when that happens.
- **The failure-classification insight** in Q8 — the single sharpest idea in this
  topic. Only a fault *in the change itself* should count toward giving up; being
  offline must never count, or a few days without signal would throw away perfectly
  good data.
- **Triggers named with their gap** — knows which triggers exist, and is honest about
  the ones that don't yet and what that costs a user in practice.
- **Conflict resolution answered honestly** — knows which strategy is in place, can
  state the case where it silently loses someone's edit, and doesn't pretend that's
  solved.
- **Schema/versioning of queued actions** (Q12) handled thoughtfully — separating the
  on-device format from the wire format, so the server changing shape can't break
  items already sitting in someone's queue. Bonus for admitting what's still unhandled.
- **Proportionality** (Q11) — defends the machinery for *this* app's promise, and can
  name the app where they genuinely wouldn't build it.
- **Self-critique** (Q15) is specific, not performative — names a real gap, why it's
  still open, and what would trigger fixing it.
