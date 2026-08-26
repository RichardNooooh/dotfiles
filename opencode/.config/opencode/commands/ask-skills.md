---
description: Ask which route fits your situation. A router over the skills in this repo. (No Arguments)
---

I am unsure which OpenCode command or skill to use right now. Can you use this guidance and our conversation to help me?

# Ask Skills

Use what I want to accomplish to recommend a route. If that is not clear, ask me. Commands are the adaptation boundary for upstream workflows that require an explicit user invocation; loadable skills are available for model invocation when their trigger applies.

A **flow** is a path through routes and skills. Most paths run along one **main flow**, and two **on-ramps** merge onto it. Everything else is standalone, or a vocabulary layer that runs underneath.

## The main flow: idea → ship

The route most work travels. I have an idea and want it built.

1. **`/grill-with-docs`** — sharpen the idea by interview. Start here when I **have a codebase**: it's stateful, retaining what it learns in `CONTEXT.md` and ADRs. (No codebase? Use `/grill-me` — see Standalone. Both load `grilling`; `grill-with-docs` is the one that leaves a paper trail.)
2. **Branch — can every question be settled in conversation?** If a question needs a runnable answer (state, business logic, a UI I have to see), detour through a prototype, bridged by **`/handoff`** in both directions (see Crossing sessions):
   - **`/handoff`** out, then I open a fresh session against that file,
   - load **`prototype`** to answer the question with throwaway code,
   - **`/handoff`** back what was learned, and reference it from the original idea thread.
3. **Branch — is this a multi-session build?**
   - **Yes** → **`/to-spec`** (turn the thread into a spec), then **`/to-tickets`** to split it into tracer-bullet tickets, each declaring its **blocking edges**. On a local tracker that's one file per ticket under `.scratch/<feature>/issues/`, worked blockers-first by hand; on a real tracker the edges become native blocking links, so any ticket whose blockers are done can be grabbed — kick off **`/implement`** per ticket, **clearing context between each one**.
   - **No** → **`/implement`** right here, in the same context window.

    Either way, **`/implement`** builds each issue by loading **`tdd`** internally — one red-green slice at a time — then closes out by loading **`code-review`**, a two-axis review (Standards + Spec) of the diff, before committing when requested. Load **`tdd`** on its own when I just want to build a concrete behaviour test-first without a full spec, and **`code-review`** on its own whenever I want to review a branch or PR against a fixed point.

### Context hygiene

Keep steps 1–3 in one intentional phase so the grilling, spec, and tickets all build on the same thinking. Each `/implement` then starts fresh, working from the ticket. Choose `/compact` or `/handoff` yourself at intentional boundaries; `/compact` continues the conversation, while `/handoff` carries selective context into a fresh session.

## On-ramps

A starting situation that generates work, then merges onto the main flow.

- **Bugs and requests piling up** → **`/triage`**. It moves issues through triage roles and produces agent-ready issues, which **`/implement`** later picks up.

  Triage is only for issues **I didn't create** — bug reports, incoming feature requests, anything that arrives raw. Tickets that `/to-tickets` produced are already agent-ready, so **don't triage them**.

- **Something's broken** → load **`diagnosing-bugs`**. For the hard ones: the bug that resists a first glance, the intermittent flake, the regression that crept in between two known-good states. It refuses to theorise until it has a **tight feedback loop** — one command that already goes red on *this* bug — then fixes with a regression test. Its post-mortem hands off to **`/improve-codebase-architecture`** when the real finding is that there's no good seam to lock the bug down.

- **A huge, foggy effort — a greenfield project or a huge feature build, too big for one session** → **`/wayfinder`**, the most cognitively demanding flow here. When the way from here to the destination isn't visible yet, it charts a **shared map** of **decision tickets** on the issue tracker and resolves them one at a time — producing **decisions, not deliverables** — until the fog is pushed back and the way is clear. Where **`/grill-with-docs`** sharpens an idea I can hold in one session, wayfinder is for the idea I can't — and it's slower and denser, so save it for exactly that, never a well-scoped feature.

  When the map clears, **it hands off, it doesn't build**: merge onto the main flow at **`/to-spec`**, which collapses the map's linked decisions into a buildable plan, then `/to-tickets` and `/implement` as usual. Looping the map straight into `/implement` skips that collapse and throws the linked detail away — go straight to `/implement` only when the effort turned out genuinely small.

## Codebase health

Not feature work — upkeep.

- **`/improve-codebase-architecture`** — run whenever I have a spare moment to keep the codebase good to operate in. It surfaces **deepening opportunities**; picking one _generates an idea_ I can take into the main flow at `/grill-with-docs`. It's the survey that finds the candidates; load **`codebase-design`** (below) to design the chosen one.

## Vocabulary underneath

When the **words** or focused process, not the wider route, are the problem, load one of these skills directly; the routes above can load them too.

- Load **`grilling`** — a relentless interview to sharpen a plan or design.
- Load **`domain-modeling`** — sharpen the project's *domain* language: challenge a fuzzy term, resolve an overloaded word ("account" doing three jobs), record a hard-to-reverse decision as an ADR. It's the active discipline `/grill-with-docs` drives to keep `CONTEXT.md` a clean glossary.
- Load **`codebase-design`** — the deep-module vocabulary (module, interface, depth, seam, adapter, leverage, locality) for designing a module's *shape*: a lot of behaviour behind a small interface at a clean seam. `tdd` and `/improve-codebase-architecture` both speak it.
- Load **`tdd`** — build a concrete behaviour test-first without a full spec.
- Load **`code-review`** — review a branch or PR against a fixed point.
- Load **`prototype`** — make a small, throwaway program to answer one design question.
- Load **`research`** — when I need a durable, cited Markdown research artifact in the repo. It investigates a bounded question from high-trust primary sources; use ordinary documentation lookup or API fact-finding directly instead.
- Load **`diagnosing-bugs`** — establish a tight feedback loop before fixing a hard bug with a regression test.
- Load **`resolving-merge-conflicts`** — resolve a merge conflict while preserving each side's intended behaviour.

## Crossing sessions

- **`/handoff`** — when a thread is full or I need to branch off (e.g. into a session that loads `prototype`), this compacts the conversation into a markdown file. I don't continue in place — I **open a new session and reference that file** to carry the context across. It's the bridge between context windows, in either direction. Use it when I want a **fresh session** but need the **current conversation preserved**.
- **`/compact`** (built-in) — stay in the **same conversation**, letting the earlier turns be summarized. Use it at **intentional breaks between phases**, when I don't mind losing the verbatim history. Avoid compacting mid-phase — the agent can lose its way. `/handoff` forks; `/compact` continues.

## Standalone

Off the main flow entirely.

- **`/grill-me`** — the same relentless interview as `/grill-with-docs`, but for when I have **no codebase**. Stateless: it saves nothing locally, builds no `CONTEXT.md`. Reach for it to sharpen any plan or design that doesn't live in a repo.
- Load **`prototype`** — a small, throwaway program that answers one design question: does this state model feel right, or what should this UI look like. Throwaway from day one — keep the answer, delete the code. It's the detour in step 2 of the main flow, but reach for it any time a design question is hard to settle on paper.
- **`/teach`** — learn a concept over multiple sessions, using the current directory as a stateful workspace.
- Load **`writing-for-agents`** — a model-invoked skill for writing instructions and skills that agents can follow.
- **`/writing-great-skills`** — manual wrapper that loads `writing-for-agents` when I explicitly want to write or edit a skill.
- **`/wait-what`** — standalone command that re-pitches the previous message with the needed context in Simplified Technical English.

## Precondition

**`/setup-skills`** — run before `/triage`, `/to-spec`, or `/to-tickets` to configure the issue tracker, triage labels, and domain-doc layout they require. Other routes can use those docs when present but do not require setup. Custom issue trackers also work.
