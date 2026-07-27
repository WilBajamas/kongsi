# 03 · Offline-first & the sync queue

**Study spine:** [technical-summary §5](../technical-summary.md) ·
[learning log → Sync / offline architecture](../learning-log.md) ·
[ADR-003](../adr/ADR-003-offline-strategy.md) · [ADR-006](../adr/ADR-006-conflict-resolution.md)

> **Read this as an interview, not a quiz.** The interviewer knows mobile
> engineering well, but has **never seen Kongsi**. Answer the idea first, then use
> the project as your evidence. This is the deepest section — it's the part of the
> system an interviewer will dig hardest into, because it's where the real
> engineering is.

---

## Warm-up

1. "Offline-first" gets used loosely. What does it actually mean to you, and how is
   it different from an app that just caches some data so it can be read offline?

2. A user taps "save" with their phone in airplane mode. Walk me through what
   happens — from the tap, all the way to the data eventually reaching the server.

## The main questions

3. In an app like this, where does the "truth" live — on the phone or on the server?
   What does that choice change about how you build everything else?

4. When someone saves a change offline, two things need recording: the change itself,
   and the fact that it still needs to be sent. What goes wrong if only one of those
   two lands?

5. How do you make sure a change never gets lost on its way to the server? What
   guarantee are you actually aiming for, and what did you decide *not* to aim for?

6. If a system can end up sending the same change twice, what stops the server
   creating two copies of it?

7. When is it safe to remove something from the queue — before you send it, or after
   the server confirms? Talk me through the risk on each side.

8. Does the order things get sent in matter? Why, or why not?

9. One item in the queue is broken and the server keeps rejecting it. What happens to
   everything queued up behind it?

10. How do you tell the difference between "this particular change is bad" and "the
    network is down right now"? Why does your system need to care about that
    difference?

11. What actually makes the queue run? What triggers it?

12. If two of those triggers fire at almost the same moment, what stops the same
    items being sent twice at once?

13. A queued item might sit on the phone for weeks — through an app update, or a
    change to the server's database. How do you store it so it still works when it
    finally gets sent?

14. Your sync code has to send several different kinds of change — create a group,
    add an expense, settle a debt. How does it know how to send each one, without
    knowing what any of them actually are?

## The pushback

15. "Firebase gives you offline support out of the box. You've hand-built a queue,
    retry logic, failure classification, and a dead-letter path. That's a lot of code
    to own. Why not just use the thing that already works?"

16. "So you've knowingly built a system that can send the same thing twice. If I'm a
    user and I get charged twice, 'the server deduplicates it' isn't going to comfort
    me. Sell me on that design."

17. "One bad item stops your whole queue. That means one corrupt record blocks
    everything else that user did. Skipping past it and carrying on seems obviously
    better. Defend stopping."

18. "Two people edit the same expense while both are offline. They both come back
    online. What happens, and how confident are you in that answer?"

19. "You keep telling me the sync system knows nothing about features. Walk me through
    adding a brand new feature and show me exactly where the sync code has to change."

## Kata *(optional — answer only if you want the code practice)*

Add a **new kind of change** to the sync system end to end — pick anything simple,
like renaming a group. Make it save locally, queue itself, and send to the server,
without modifying the sync machinery itself.

Then answer: **which files did you have to touch, and which did you deliberately not
touch?** That list is the real answer to question 19.

## Rubric — a lead-level answer covers

- **Offline-first stated properly**: the local write is *authoritative and immediate*,
  not a cache warmed from the server. The app is fully usable with no network, and
  the network is an eventual detail — not "reads work offline."
- **The atomic pair**: the change and the record-that-it-needs-sending must land
  together or not at all, with the concrete failure named in both directions (a
  change that silently never syncs; a sent change the user can't see).
- **At-least-once chosen over exactly-once**, with the honest reason — exactly-once
  across an unreliable network costs enormous machinery for the same practical result
  — paired with **idempotency** (a client-generated id the server deduplicates on) as
  what makes repeats safe.
- **Delete-after-send** reasoned through: names the crash window between "sent" and
  "removed," accepts that it produces a duplicate, and points at idempotency as why
  that's fine. A weaker answer deletes first and loses data.
- **Order as a correctness rule, not a preference** — a create must land before the
  edits that depend on it.
- **Head-of-line blocking named** as the real problem, with the dead-letter as the
  fix: a permanently bad item steps aside so the queue keeps flowing.
- **The two failure kinds separated** — the item's own fault vs the environment — and,
  crucially, *why counting the wrong one is dangerous*: if being offline counted
  against the retry limit, a few offline launches would throw away perfectly good
  data.
- **Triggers named**, plus the guard against overlapping runs, plus honesty about
  which triggers exist today versus which are planned.
- **Storage shape kept separate from wire shape**, with the reason: a server-side
  rename must not break items already sitting on a user's phone.
- **The generic pipe defended**: each change carries its own destination, so the sync
  code never needs a central `switch` over feature types. Can name the rejected
  alternative and what it would cost (sync importing every feature — the pipe rots
  into something that knows the whole app).
- **Honesty on conflicts**: last-write-wins is chosen and its data-loss case is
  understood, but it has *not* been stress-tested with real concurrent offline edits.
  A lead says that plainly instead of overclaiming.
