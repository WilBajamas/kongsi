# 02 · Dependency injection & app startup

**Study spine:** [technical-summary §3](../technical-summary.md) ·
[learning log → Dependency injection](../learning-log.md) · [ADR-002](../adr/ADR-002-state-management.md)

> **Read this as an interview, not a quiz.** The interviewer knows Flutter and
> architecture well, but has **never seen Kongsi**. So the questions are general —
> your job is to answer the idea first, then use Kongsi as the evidence. If an
> answer only makes sense to someone who has read your code, it hasn't landed.

---

## Warm-up

1. In plain words, what is dependency injection, and what problem does it solve?
   Assume the person asking has written code but never used a DI library.
A: Some classes need "other things" to work, which are called dependencies because we "depend" on that something to do our job. Just like a car manufacturer needed parts from other car manufacturers, hence dependency injection - which means instead of the class "creates" its own dependencies, it is given the dependencies it needs from the outside. This solves separation of concerns, the class doesn't need to know "how" it's built, but only need to know how to use it. The real win is swapping - because the class doesn't build its own stuff, I can hand it a fake version in a test and it won't even notice the difference, or swap the real implementation later without touching the class at all. It also means there's one single place that knows how the whole app is put together, instead of that knowledge being scattered inside every class.

2. What do you use for DI in Flutter, and how did you decide?
A: In previous projects I've used get_it with injectable packages - mainly because it's the industry standard and the code generation makes everything faster with injectable and also convenient where it's a service locator and can easily fetch dependencies anywhere (but it is also quite "dirty" in a sense that dependencies can be retrieved from anywhere which may get out of control). For this project I went with Riverpod, mainly because dependencies are declared rather than pulled - you can read the whole graph in the provider files and see exactly what depends on what. It also handles lifecycle for me (things are built lazily, disposed automatically when nothing needs them anymore), and I can override any dependency at the root in a test without touching app code. It was also a good chance to learn it properly. Right now I only use it as a DI tool, and in the future as the project grows, I might use riverpod as a state management solution as well with Riverpod 3.0 has added state benefits for async calls (loading, fetched, error etc.)

## The main questions

3. Riverpod is normally sold as a state-management library. You use it **only** for
   dependency injection, and something else holds screen state. Why split it that way?
A: Providing dependencies and managing state are two distinct concerns, so I gave each tool exactly one job - Riverpod hands out objects, Bloc/Cubit holds screen state. The reason that split matters is that two tools with one job each never fight. Nobody has to argue in a code review about whether a piece of state belongs in a provider or in a cubit, because the rule is already decided - if both tools could hold state, every feature would end up doing it slightly differently and the codebase would drift. Bloc is also the local hiring standard and my strongest tool, so keeping state there and letting Riverpod do the wiring plays to that. In the future if the project grows, I might use riverpod as a state management solution as well with Riverpod 3.0 has added state benefits for async calls (loading, fetched, error etc.) - but that would be a deliberate decision, not something I drift into.

4. Some things can't be created when the app starts — the value doesn't exist yet, or
   the code that owns it isn't allowed to be seen from where it's needed. How do you
   handle that? Walk me through your approach.
A: There are two different reasons this happens and they both get the same fix. The first is timing - the value simply doesn't exist yet when the provider is declared, like the app config that only gets read once a specific flavor's `main()` runs. The second is layering - the value does exist, but the layer that needs it isn't allowed to import the layer that owns it. In this project, `core` does not depend on features nor `app` level components. But `app` & `features` depends on `core` - so when core needs something the app owns (like the catalog of commands), it can't reach up for it. The fix for both is the same: the provider declares itself but throws instead of building a value, and the top level hands the real value down at startup before `MainApp` is built, wrapping it through a provider scope. So there's one place - the composition root - that knows how the whole app is assembled.

5. What happens in your app if a developer forgets to wire up one of those
   dependencies? When do they find out?
A: If it's a constructor argument they forgot, the compiler catches it straight away - a compile time error in the editor. If it's an override they forgot (one of those providers that throws instead of building itself), the analyzer can't catch it, but the app crashes the moment it starts up - before any screen renders, on the developer's own machine, on the very first run. So it never gets far enough to reach a user. That's the whole reason those providers throw instead of quietly falling back to a default - a loud crash at boot is far cheaper to fix than a silent wrong value that only shows up deep inside a feature weeks later.

6. Most teams I talk to use a service locator — you ask a global container for what
   you need. Why didn't you go that way?
A: Service Locator is considered slightly dirty in retrieving dependencies because any class can get hold of any depencencies without any restriction. I prefer having a totally clean DI where dependencies are declared and injected in the constructor and is easily spotted in the provider files - if I want to know what a class needs, I read its constructor, I don't have to go hunting through the body for locator calls. The other thing a graph gives me that a locator doesn't is lifecycle - things get built lazily on first use, disposed automatically when nothing depends on them anymore, and I can invalidate one to force a rebuild. With a locator you register and dispose by hand. Although service locator is not a bad solution to DI, it can be convenient for fetching dependencies, but for this project I prefer to have very declarative DI graph.

7. Say I want to test a screen that depends on a database, a network client, and a
   clock. How does your setup make that testable?
A: This is exactly what DI buys me. In a widget test I wrap the screen in a provider scope and override those dependencies at the root - the database, the network client, the clock - so the screen gets fakes instead of the real thing, and I never have to touch the screen's own code to make that happen. For the doubles I pick per job: a mock (mocktail) when I only need to stub a return or verify that something got called, and a hand written fake when I need real behaviour over time, like an in-memory queue. The clock and the uuid generator are injected abstractions on purpose - if a class called `DateTime.now()` directly, a test could never control time, so instead they take a `Clock` and in tests I hand them one that always returns a fixed time. That's what makes the test deterministic instead of flaky. The project has unit tests, widget tests and golden tests (alchemist for goldens, mocktail for mocking), but the reason all three are even possible is that nothing builds its own dependencies.

8. Some things shouldn't be created until they're needed, others need to exist the
   moment the app opens. How do you control that?
A: What you're talking about is lazy initialization. Riverpod providers are lazy by default, so they are only created when they are needed. The bit worth saying is that "eager" isn't actually a setting you switch on - there's no flag for it. Every provider is lazy, full stop. Eager just means *I* choose to read one early, and the act of reading it is what builds it. So at startup I read the few things that must exist immediately - seeding the dev database, kicking off the first sync - and everything else stays unbuilt until something actually asks for it. That happens before `runApp` is called, with `MainApp` wrapped in a scope holding the container.

9. Where's the line for you — when does this kind of setup stop being worth it, and
   what would you do on a smaller app?
A: On the DI side specifically - for a three or four screen app I'd skip the DI library completely and just build the objects in `main()` and pass them down through constructors. The principle stays the same (nothing builds its own dependencies), it's only the tool I'd drop, because a whole graph library isn't worth it when the graph is five objects deep. Beyond DI, a smaller app with small functionalities wouldn't need an entire end to end testing, unit tests are good to test for functionality but widget and golden tests could be overkill and can be replaced with the human eyes and manual testing. As for architecture, pass through use cases without any business logic could be written off. Most small apps come with small teams, hence architecture and strict rules such as folder structures might be too much to handle and enforce, some editor errors from analysis options could be more lenient.

## The pushback

10. "You've pulled in a whole reactive graph library and you're using maybe 10% of it.
    That's a heavy dependency for something a factory function could do. Convince me."
A: I wouldn't put a percentage on it, but yes - I'm deliberately using the DI half and not the state half. The half I do use earns its place on its own though. A factory function hands me objects, but it doesn't give me overrides at the root so a test can swap a real database for a fake without touching app code, it doesn't dispose things when nothing needs them anymore, and it doesn't cache one instance so the whole app shares the same database connection - I'd end up hand writing all of that myself, badly. And to be fair, on a small app a factory function genuinely would be enough and I'd take that trade. At this size I'd rather have the graph. If I later use riverpod for state as well that's a bonus, but it's not the reason it's in the project today.

11. "You've told me some of your providers deliberately crash if they're not set up.
    Deliberately shipping code that throws sounds like a bug waiting to happen.
    Defend it."
A: Deliberately crashing the app loudly is way better than failing silently and uncaught - if things are uncaught when it reaches users, it is worse than having devs -> testers -> internal users -> stakeholders catching it early and resolving it quickly. It has to be a runtime throw rather than a compile error because the compiler can't tell whether an override was actually provided at startup - so throwing is simply the earliest signal available. To be fair about the cost: if a wiring mistake somehow got past all of that and shipped, the app wouldn't start at all instead of half working. I'll take that trade, because a missing wire is exactly the kind of bug that shows up on the very first run, not the kind that hides for months.

12. "So you have Riverpod handing out objects, *and* you're passing dependencies into
    constructors by hand further down. That's two dependency systems in one app. Why
    isn't that confusing?"
A: They're not two systems, they're two different jobs. The constructor's job is to declare what a class needs to do its work. Riverpod's job is to decide which instance gets handed over, and how long it lives (caching it, disposing it). So riverpod isn't competing with the constructor - it's the thing that fills the constructor in at the top. The classes themselves - use cases, repositories, blocs - don't even know riverpod exists, there's no riverpod import inside them, they just take plain dart objects. That's on purpose: it means I can test a use case with fake dependencies without touching riverpod at all, and if I ever swap riverpod for something else, only the provider files change and everything below stays untouched. So riverpod only lives in the provider files and the widgets, everything under that is plain dart.

13. "A new developer joins on Monday. How long before they can add a new service
    without breaking startup — and what stops them getting it wrong?"
A: Adding a service is mostly a copy-paste job - every provider in the project follows the same shape, so they'd open the provider file, see ten examples of the exact thing they're about to do, and follow the pattern. Three things stop them getting it wrong: the compiler catches a missing constructor argument straight away, the DI graph is declared in one place so there's no hunting around for where something gets registered, and if the new service needs a value handed down from startup and they forget to wire it, the app crashes on the first run instead of failing quietly. Separately, getting their machine ready is already scripted - I've created a `README.md` to get a new developer started, and within the readme, there's a mention of two script files depending on the machine they use (windows powershell or mac linux). These scripts essentially does the same thing - setting up the environment by installing flutter / fvm, setup the development environment - setting up dev.json (default backend). Not to mention there's `analysis_option` to enforce certain development standards.

## Kata

Your app needs a new **analytics service**. It has two requirements: it needs a value
that only exists once the app is running (an API key from config), and you want a test
to be able to swap in a no-op version.

Wire it up end to end — the contract, the real implementation, the provider, the
startup wiring, and the test override. Keep it small; `flutter analyze --fatal-infos`
and `flutter test` are the pass check.

Then answer: **which existing thing in the app did you copy the pattern from, and
why did that pattern already exist?**

## Rubric — a lead-level answer covers

- **DI explained without jargon** — "objects don't build their own dependencies, they
  get handed them" — and the *reason* (swappable, testable, one place that knows how
  the app is assembled), not just the mechanic.
- **The bounded role defended**: providing objects and holding state are different
  jobs; keeping Riverpod in one lane is what stops it fighting Bloc. Names it as a
  deliberate constraint, not a limitation.
- **The composition root** described in general terms — one place at startup assembles
  everything — with the two distinct reasons a value has to be injected from the top
  (**it doesn't exist yet** vs **this layer isn't allowed to see it**). A lead
  separates those two; a mid-level answer blurs them into "config stuff."
- **Fail loud, fail early** argued as a deliberate trade-off: a startup crash is
  cheaper than a silent wrong default surfacing later in a feature. Concedes what it
  costs.
- **Service locator vs reactive graph** compared honestly — pull vs declared
  dependencies, lifecycle/disposal, invalidation — and does *not* pretend the rejected
  option is bad, only worse-fitting here.
- **Testability shown as the payoff**, not an afterthought — overriding a dependency at
  the root is the whole point of the pattern.
- **The two-systems question answered cleanly**: constructor injection is the *rule*,
  the DI container is what supplies the constructor arguments at the top. They're not
  competing.
- **Knows when it's overkill** — can name the app size or team shape where they'd skip
  it, without abandoning the principle.
