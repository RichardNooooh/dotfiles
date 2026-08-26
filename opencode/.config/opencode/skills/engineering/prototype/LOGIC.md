# Logic Prototype

A logic prototype lets someone drive a state model by hand. Use this when the question is about **business logic, state transitions, or data shape**: the kind of thing that looks reasonable on paper but only feels wrong once you push it through real cases.

## When this is the right shape

- "I'm not sure if this state machine handles the edge case where X then Y."
- "Does this data model actually let me represent the case where..."
- "I want to feel out what the API should look like before writing it."
- Anything where someone wants to **press buttons and watch state change**.

If the question is "what should this look like," this is the wrong branch. Use [UI.md](UI.md).

## Choose the format

Before writing code, always ask the user which format to build:

1. A **tiny interactive terminal app** for driving the model from a terminal.
2. A **single self-contained shareable HTML walkthrough** for clicking through the model in a browser.

Do not default, infer, or make this choice on the user's behalf, including when they are unavailable. Wait for their answer before building the prototype.

## Shared principles

### 1. State the question

Before writing code, write down what state model and what question you're prototyping. One paragraph, in the terminal prototype's README or top-of-file comment, or visibly at the top of the HTML demo. A logic prototype that answers the wrong question is pure waste, so make the question explicit so it can be checked later.

### 2. Keep the logic portable and pure

Put the actual logic, the bit answering the question, behind a small, pure interface that could be lifted out and dropped into the real codebase later. The terminal or HTML shell around it is throwaway; the logic module should not be.

The right shape depends on the question:

- **A pure reducer**: `(state, action) => state`. Good when actions are discrete events and state is a single value.
- **A state machine**: explicit states and transitions. Good when "which actions are even legal right now" is part of the question.
- **A small set of pure functions** over a plain data type. Good when there is no implicit current state, just transformations.
- **A class or module with a clear method surface** when the logic genuinely owns ongoing internal state.

Pick whichever shape best fits the question being asked, not whichever is easiest to wire to a shell. Keep it pure: no I/O, terminal code, DOM code, or `console.log` for control flow. The shell calls into it; nothing flows the other direction.

### 3. Keep the scope disposable

- Use in-memory state unless the question explicitly concerns persistence. If it does, use a clearly named disposable local file or scratch database.
- Build only the behavior needed to answer the one question. Do not add tests, production-grade error handling, abstractions, or speculative capabilities.
- Surface the full relevant state after every action so changes are visible.

## Terminal app

Choose this only after the user selects option 1.

### 1. Pick the language

Use whatever the host project uses. If the project has no obvious runtime, for example a docs repository, ask.

Match the project's existing conventions for tooling. Do not add a package manager or runtime just for the prototype.

### 2. Build the smallest TUI that exposes the state

Build it as a **lightweight TUI**: on every tick, clear the screen (`console.clear()` / `print("\033[2J\033[H")` / equivalent) and re-render the whole frame. The user should always see one stable view, not an ever-growing scrollback.

Each frame has two parts, in this order:

1. **Current state**, pretty-printed and diff-friendly: one field per line or formatted JSON. Use **bold** for field names or section headers and **dim** for less important context such as timestamps, IDs, and derived values. Native ANSI escape codes are fine: `\x1b[1m` bold, `\x1b[2m` dim, `\x1b[0m` reset. Do not pull in a styling library unless one already exists in the project.
2. **Keyboard shortcuts**, listed at the bottom: `[a] add user  [d] delete user  [t] tick clock  [q] quit`. Bold the key, dim the description, or use whichever treatment reads cleanly.

Behavior:

1. Initialize state as a single in-memory object or struct and render the first frame on start.
2. Read one keystroke or line at a time, then dispatch it to a handler that updates state.
3. Re-render the full frame after every action. Do not append; replace.
4. Loop until quit.

The whole frame should fit on one screen.

### 3. Make it runnable in one command

Add a script to the project's existing task runner (`package.json` scripts, `Makefile`, `justfile`, or `pyproject.toml`). The user should run `pnpm run <prototype-name>` or equivalent, never need to remember a path.

If the host project has no task runner, put the command at the top of the prototype's README.

### 4. Hand it over

Give the user the run command. The interesting moments are when they say "wait, that shouldn't be possible" or "huh, I assumed X would be different". Those are bugs in the idea, which is the whole point. If they want new actions added, add them. Prototypes evolve.

## Shareable HTML walkthrough

Choose this only after the user selects option 2.

### 1. Build one portable file

Build one plain HTML/CSS/JS file: no framework, bundler, server, or external dependency. Keep CSS and JavaScript inline so the file opens by double-click and remains usable when shared by email or chat.

Keep the pure logic in a small JavaScript module within a single `<script>` block. The page calls into it; the module must not reference the DOM, `document`, or button handlers.

### 2. Use domain language

Write for a non-developer such as a designer, product manager, or domain expert. Use domain language for labels, state, and actions, not reducer names or implementation terminology. Explain what is happening in plain words.

### 3. Build free play and guided scenarios

Lay out the page from top to bottom:

1. A title and one-line explanation of the question the demo explores.
2. A current-state panel that renders the full relevant state as labelled fields, not raw JSON, after every click. Call out what just changed when that helps understanding.
3. Free-play buttons: one always-available button for each action so someone can try the model in any order.
4. Guided walkthroughs: scenarios in separate tabs. Each tab explains the situation and what to watch for in plain language, then presents the ordered actions as real buttons. Starting a scenario resets to a known initial state; each step performs its action and advances the walkthrough.

Choose scenarios that expose the cases hard to reason about on paper: the happy path, a tricky edge case, and an attempt at something that should be illegal.

Keep it restrained: clean typography, generous spacing, and one accent color. Do not add animation or gimmicks that compete with the state and actions.

### 4. Hand it over

Give the user the HTML file or open it for them. They can use the guided scenarios or free play whenever convenient. If they want another action or scenario, add it.

## Capture the answer and prototype

Once the prototype answers its question, capture the answer and lift the validated reducer, machine, or function set into the real module. The terminal or HTML shell remains throwaway.

Creating a throwaway branch or committing the prototype requires explicit user approval. Never infer approval or capture it automatically. When approved, follow [SKILL.md](SKILL.md): keep the prototype out of main and record the verdict and question it settled in the issue or commit.

## Anti-patterns

- **Don't add tests.** A prototype that needs tests is no longer a prototype.
- **Don't wire it to the real database.** Use an in-memory store unless the question is specifically about persistence.
- **Don't generalise.** No "what if we wanted to support X later." The prototype answers one question.
- **Don't blur the logic and the shell together.** If the reducer or state machine references `console.log`, prompts, terminal escape codes, the DOM, or button handlers, it is no longer portable. Keep the shell as a thin layer over a pure module.
- **Don't reach for a framework, bundler, or server for the HTML format.** One file the recipient double-clicks; a React app or dev server defeats "shareable".
- **Don't ship the shell into production.** The terminal and HTML shells are optimized for being driven by hand. The logic module behind them is the bit worth keeping.
