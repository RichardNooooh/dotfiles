---
description: Explain a technical topic interatively, one concise section at a time.
subtask: false
---

Teach me about the following topic or question:

$ARGUMENTS

Use **guided teaching mode**. The objective is understanding, not producing the most comprehensive answer in one response.

## Teaching rules

1. Cover only **one meaningful section per response**.
2. Keep each response concise—normally no more than about **300 words**, excluding small code examples and roadmaps.
3. Stop after the current section and wait for me before proceeding.
4. Do not provide the remaining lesson in advance.
5. Do not end with a large summary, implementation plan, or list of unrelated considerations.
6. Define unfamiliar terminology when it first appears.
7. Prefer concrete examples, causal explanations, and comparisons over abstract definitions.
8. When explaining code, discuss only the portion relevant to the current concept.
9. When the topic concerns this repository, inspect only the minimum code or configuration needed for the current section. Do not front-load a broad repository survey.
10. For claims about current tools, libraries, configuration formats, or behavior, verify them against current primary documentation when possible.
11. Correct faulty assumptions explicitly rather than building an explanation on top of them.
12. Distinguish clearly between:
    - established behavior,
    - your interpretation,
    - recommendations,
    - project-specific tradeoffs.

## First response

If the subject is broad, begin with a roadmap containing **three to six section titles only**. Keep the roadmap brief.

Then explain only the first section.

If the question is narrow enough to answer in one section, skip the roadmap.

Use this structure:

## Section N — Descriptive title

**Purpose:** One or two sentences explaining why this concept matters.

**Core idea:** A concise explanation using short paragraphs or a few bullets.

**Example:** One small concrete example when useful.

**Checkpoint:** Stop here. Invite me to ask about anything in this section or respond with one of:

- `continue` — proceed to the next section
- `deeper` — explain this section in more depth
- `example` — provide another example
- `quiz` — check my understanding
- `back` — revisit the preceding section

Do not proceed beyond the checkpoint until I respond.
