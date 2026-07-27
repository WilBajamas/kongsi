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
A: This app does cache data, and the cached data is actually the single source of truth for user's data. But since this app is meant to be used with others, it also has a syncing system which syncs up not only user-created data but also incoming data. When the app goes offline or has choppy internet connection, everytime the user creates a record, it updates the local db - drift, then adds to a outgoing queue to sync with the server, so whenever the internet is stable, it will sync with the server and update both locally and remote. Other apps just cache data for fast retrieval but the data is only meant for the user alone, and if the connection is bad, it will just show an error message, but this app will continue to work with / without internet connection and does its "syncing" silently in the background.

2. A user opens your app in airplane mode and creates something. Walk me through what
   happens, from the tap to the moment it's on the server.
A: User creates an expense in airplane mode -> calls a cubit function receiving the info -> cubit calls a use case function (passing the info) -> use case calls a repository function -> repository retrieves the info from presentation -> parses the info into drift's data model -> repository uses drift's data model and inserts it into 2 drift tables (outbox & expenses).
Not implemented but part of future enhancements: Sync system listens to outbox table & connectivity manager -> filter outbox expenses' "sync" status -> retrieves the ones not synced -> check internet connection -> if connectivity good -> immediately parses (decodes) filtered outbox expense into actual commands (translated to supabase readable json) -> passes commands to a sender -> does a POST request to supabase (via dio client) -> supabase updated.
This flow is implemented: This dart project uses `EventChannels` to communicate with native platforms to retrieve a stream of connectivity updates -> a sync bloc listens to it -> once internet connection is back up -> follows the same procedure as before (filter outbox expenses and so on)

## The main questions

3. In an app like that, what's the source of truth — the phone or the server? What
   made you land where you did, and what does that decision cost you?
A: The source of truth is the local db within the phone's storage. Because this is an offline first app and having to improve UX for the user via optimistic state, we've decided to have the SSoT to be the local db which will reflect all user actions and data to be seen without interruptions. But having this system cost us way more planning ahead rather than just set up a http client wrapper and be done with it. The entire offline-first system we've built needs strategic thinking of user's experience, architecturing, workflows, sequences and syncing flows.

4. When someone makes a change with no connection, how do you make sure it actually
   reaches the server later? What's the mechanism?
A: We have a syncing system built separately from the main features of the app. That system is designed to retrive pending-sync records from the outbox (via local db table); We then have a connectivity manager which listens to internet connection statuses -> after connection is successful -> proceeds to send the records to the server.

5. What stops the same change being sent to the server twice?
A: We're using special UUIDs as the primary key for each and every outbox record we insert into drift tables, if the same "group" or "expense" is being updated, the same row in the drift table will be replaced with the latest one. But in some instances when the app crashes while sending the change (and doesn't update the sync statuses) then the app relaunches, the sync could push the changes up again resulting in a row being sent to the server twice or more. But supabase's table have been set to use non-duplicate primary keys so the server never records a duplicate.

6. There are three delivery guarantees people talk about: at-most-once, at-least-once,
   exactly-once. Which are you aiming for, and why not one of the others?
A: If you're asking about the syncing-tries to server, then it's at-least-once. Because of many factors: Unreliable network, choppy / slow connectivity, which are not the user's fault nor purposeful action - which is why I've opted for at least once.

7. When is it safe to take something off the queue — before you send it, or after the
   server confirms? Talk me through the risk on each side.
A: This app has two ways of taking something off the queue: The first is a successful send. The 2nd is when the record has failed to sync after 5 attempts, we consider it a failure and will remove it from the queue. This prevents future sync attempts to be blocked by this single "poison pill" and future records may depend on the broken one previously.

8. Does the order things get sent in matter? Why, or why not?
A: Yes, the order does matter. Because of the nature of the business logic - records may depend on previous records, so it's better to have the dependencies sorted out and completed first before moving on to the following ones.

9. Say one queued change is broken — the server rejects it every single time. What
   happens to it, and what happens to everything queued behind it?
A: 

10. How do you tell the difference between "this change is bad" and "the network is
    down"? Does your retry logic treat those two the same way?

11. What actually triggers the sending? Is it on a timer, on user action, something
    else?
A: It's reconnection to the internet and app launch for now. I've setup something using Flutter's Event Channel to listen to connectivity changes. In the future the app will immediately sync up the server once the outbox has received a new record - normally from user actions.

12. If two of those triggers fire at almost the same moment, what stops the same work
    happening twice?

13. As you add more kinds of change over time, what stops the sending code growing a
    branch for each one?

14. Two people edit the same expense while both are offline. They both come back
    online. What happens?

## The pushback

15. "You've essentially built a message queue inside a phone app. That's a lot of
    machinery for a bill-splitting app — why not just retry the API call a few times
    and show an error if it fails?"

16. "Firebase gives you offline support out of the box. Why hand-build any of this?"

17. "You're storing user actions as data and replaying them later. So what happens when
    you ship a new version of the app and someone still has old actions sitting in
    their queue that don't match the new code?"

18. "A product owner tells you a duplicate charge showed up once. Explain to them, in
    their language, why your system can produce a duplicate at all — and why that's
    the right design."

19. "Someone goes on holiday, uses the app offline for two weeks, and comes back with
    hundreds of queued changes. What happens when they reconnect?"

20. "You've been telling me the sync side doesn't know anything about your features.
    Walk me through adding a brand new feature and show me exactly where the sync code
    has to change."

21. "What part of this would you say you got wrong, or would build differently next
    time?"

## Kata *(optional)*

Add a **new kind of change** to the sync system end to end — pick something plausible
for the app, like renaming a group. Wire it from the user action all the way through to
the server call.

Then answer: **which files did you have to touch, and which did you deliberately not
touch?** That list is the real answer to question 20.

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
- **Delete-after-send reasoned through** (Q7): names the crash window between "sent"
  and "removed," accepts that it produces a duplicate, and points at idempotency as
  why that's fine. A weaker answer removes it first and loses data.
- **Order treated as a correctness rule, not a preference** (Q8) — a create has to land
  before the edits that depend on it.
- **Both failure traps identified** in Q9: infinite retries *and* one bad item blocking
  everything behind it in a strict queue. Names the escape hatch (park it aside) and
  what the user experience is when that happens.
- **The failure-classification insight** in Q10 — the single sharpest idea in this
  topic. Only a fault *in the change itself* should count toward giving up; being
  offline must never count, or a few days without signal would throw away perfectly
  good data.
- **Overlapping runs guarded** (Q12) — knows that two triggers firing together would
  otherwise process the same items twice, and can name how that's prevented.
- **The generic pipe defended** (Q13, Q20): each change carries its own destination, so
  the sending code never needs a central `switch` over feature types. Names the
  rejected alternative and its cost — sync importing every feature, until the pipe
  rots into something that knows the whole app.
- **Build-vs-buy answered without defensiveness** (Q16): can say what an off-the-shelf
  offline layer would have given them, what it would have cost (backend lock-in, less
  control over conflict and retry behaviour), and that building it once by hand was
  partly a deliberate learning choice.
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
