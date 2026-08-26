---
name: writing-for-agents
description: Writing documents for agents. Use when creating or editing skills, or modifying AGENTS.md or CLAUDE.md.
---

Reference for writing any document an agent consumes: a skill, an `AGENTS.md` / `CLAUDE.md`, or a document reached by a pointer. The packaging differs; the writing does not: the same levers make the agent take the same process every run rather than produce the same output.

When writing an OpenCode skill or command, read [`SKILL-MECHANICS.md`](SKILL-MECHANICS.md) for its invocation mechanics.

## Context Pointers

A **context pointer** is a reference held in the agent's context that names out-of-context material and encodes when to reach it. A skill description is one; a line in `AGENTS.md` naming a document is the same object. The pointer's wording, not its target, decides when the agent reaches the material and how reliably. A must-have target behind a weak pointer is a variance bug: sharpen the wording first, and inline the material only if that fails.

A pointer states what the material is and the **branches** that should reach it. A branch is a distinct case the document handles. Every word of an always-loaded pointer costs on every turn, so prune it harder than the body:

- **Front-load the leading word**: the pointer does its triggering work.
- **One trigger per branch.** Collapse synonyms that name one branch; keep distinct branches.
- **Cut identity the body already carries.**

## The Two Loads

Every document and pointer spends one of two budgets:

- **Context load** is the cost of always-loaded material in the agent's window: an `AGENTS.md` line, a skill description, or anything in context every turn.
- **Cognitive load** is the cost on the human of knowing which documents exist and when to use them. The human is the index. It is the price of human agency; spend it where human judgment matters.

Material reached through a pointer avoids most context load at the price of the pointer. Material with no pointer relies entirely on cognitive load.

## Information Hierarchy

A document contains **steps**, ordered actions the agent performs, and **reference**, definitions, rules, and facts consulted on demand. They mix freely. Put each part on the **information hierarchy**, ranked by how soon the agent needs it:

1. **In-file step**: the primary tier, what the agent does in order.
2. **In-file reference**: consulted on demand; a flat peer set is often appropriate.
3. **Disclosed reference**: a separate file reached by a context pointer only when needed.

Push too little down and the top bloats; push too much and the agent cannot reach material it needs. **Progressive disclosure** moves reference behind a pointer to keep the top legible. Inline what every branch needs and disclose what only some branches need. When a document has steps, in-file reference that should be disclosed buries them and makes attention unreliable.

**Co-location** is the within-file companion: the hierarchy decides how far down material sits; co-location decides what sits beside it. Keep a concept's definition, rules, and caveats together. **Sprawl** is a document that is too long even when every line is live. Cure it with the hierarchy: disclose reference and split by branch or sequence.

## Steps And Completion Criteria

Every step ends on a **completion criterion**, the condition that tells the agent the work is done.

- **Clarity** asks whether the agent can tell done from not-done. A vague bound invites **premature completion**. Sharpen the bound first. Only when it remains fuzzy and the agent rushes should you hide later steps by splitting the sequence across a real context boundary.
- **Demand** asks how much work the criterion requires. "Every modified model accounted for" drives more **legwork** than "produce a change list." Demand also binds flat reference: "every rule applied" makes an all-reference document exhaustive.

The strongest criteria are checkable and exhaustive.

## When To Split

Splitting a document spends one of the two loads, so split only when the cut earns it:

- **By sequence**: split where post-completion steps tempt the agent to rush the current step. Keeping later steps out of view drives more legwork.
- **By invocation**, for skills: read [`SKILL-MECHANICS.md`](SKILL-MECHANICS.md).

## Leading Words

A **leading word** is a compact concept already in the model's pretraining that the agent thinks with while running the document, such as _lesson_, _fog of war_, or _tracer bullets_. Repeated as a token, not a sentence, it anchors behaviour with fewer tokens by recruiting priors. Prefer an existing word to a coined one.

It anchors execution in the body and invocation in a pointer. Refactor repeated ideas into a leading word where possible:

- "fast, deterministic, low-overhead" becomes _tight_, as in a _tight_ loop.
- "a loop you believe in" becomes _red_, turning a fuzzy gate into an observable state.

**Negation** is the failure mode beside this lever: prohibition makes the forbidden behaviour more available. Prompt the positive target instead. Keep a prohibition only as a hard guardrail, paired with what to do.

## Pruning

- Keep each meaning in a **single source of truth**. **Duplication** costs maintenance and tokens, and overweights a meaning.
- The environment is also a source of truth. A document that restates `package.json`, configuration, directory layout, or `--help` output is a cache. Cache unwritten conventions, reasons, and hidden gotchas; leave cheap lookups to the environment.
- Check every line for **relevance**. Without pruning, **sediment** accumulates: stale layers that hide live material.
- Hunt **no-ops** sentence by sentence. If an instruction does not change behaviour from the model's default, delete it rather than trimming it. A weak leading word is a no-op; replace it with a stronger one.
