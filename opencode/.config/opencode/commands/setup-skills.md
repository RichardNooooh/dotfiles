---
description: Configure this repo's issue tracker, triage label vocabulary, and domain doc layout for workflows that require them. (No Arguments)
---

# Setup Skills

Scaffold the per-repo configuration that the engineering skills assume:

- **Issue tracker** — where issues live (GitHub by default; local markdown is also supported out of the box)
- **Triage labels** — the strings used for the five canonical triage roles
- **Domain docs** — where `CONTEXT.md` and ADRs live, and the consumer rules for reading them

Explore, present what you found, confirm with me, then write.

## Process

### 1. Explore

Look at the current repo to understand its starting state. Read whatever exists; don't assume:

- `git remote -v` and `.git/config` — is this a GitHub repo? Which one?
- `AGENTS.md` at the repo root — does it exist? Is there already an `## Agent skills` section?
- `CONTEXT.md` and `CONTEXT-MAP.md` at the repo root
- `docs/adr/` and any `src/*/docs/adr/` directories
- `docs/agents/` — does this workflow's prior output already exist?
- `.scratch/` — sign that a local-markdown issue tracker convention is already in use
- Is the `/triage` workflow available? This decides whether Section B runs at all.
- Monorepo signals — a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*` with its own `src/`. Present only in a genuinely large multi-package repo; their absence means single-context, which is almost every repo.

### 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order — one section, one answer, then the next.

Lead each section with the recommended answer so I can accept it in a word. Give a one-line explainer only when the choice genuinely branches; skip the section entirely when exploration already settled it (Section B when the `/triage` workflow isn't available, Section C when there's no monorepo).

**Section A — Issue tracker.**

> Explainer: The "issue tracker" is where issues live for this repo. `/to-tickets`, `/triage`, and `/to-spec` read from and write to it — they need to know whether to call `gh issue create`, write a markdown file under `.scratch/`, or follow some other workflow you describe. Pick the place you actually track work for this repo.

Default posture: these workflows were designed for GitHub. If a `git remote` points at GitHub, propose that. If a `git remote` points at GitLab (`gitlab.com` or a self-hosted host), propose GitLab. Otherwise (or if I prefer), offer:

- **GitHub** — issues live in the repo's GitHub Issues (uses the `gh` CLI)
- **GitLab** — issues live in the repo's GitLab Issues (uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
- **Local markdown** — issues live as files under `.scratch/<feature>/` in this repo (good for solo projects or repos without a remote)
- **Other** (Jira, Linear, etc.) — ask me to describe the workflow in one paragraph; this workflow will record it as freeform prose

Record the choice in `docs/agents/issue-tracker.md`. The GitHub and GitLab templates carry a "PRs as a request surface" flag, defaulted **off** — leave it off and don't raise it; if I want external PRs in the triage queue, I can flip the flag in the file later.

**Section B — Triage label vocabulary.** Skip this section entirely if the `/triage` workflow isn't available (exploration told you) — an unavailable workflow needs no labels.

If it is available, ask exactly one question:

> Do you want to keep the default triage labels? (recommended: **yes**)

The defaults are the five canonical roles, each label string equal to its name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. On **yes**, write them as-is. Only if I say no — usually because my tracker already uses other names (e.g. `bug:triage` for `needs-triage`) — collect the overrides so `triage` applies existing labels instead of creating duplicates.

**Section C — Domain docs.** Default to **single-context** — one `CONTEXT.md` + `docs/adr/` at the repo root. This fits almost every repo; write it without asking.

Offer **multi-context** — a root `CONTEXT-MAP.md` pointing to per-context `CONTEXT.md` files — only when exploration found monorepo signals. Then confirm which layout I want.

### 3. Confirm and edit

Show me a draft of:

- The `## Agent skills` block to add to `AGENTS.md`
- The contents of `docs/agents/issue-tracker.md`, `docs/agents/domain.md`, and `docs/agents/triage-labels.md` (the last only when the `/triage` workflow is available)

Let me edit before writing.

### 4. Write

**Edit `AGENTS.md`:** create it if it does not exist.

If an `## Agent skills` block already exists in the chosen file, update its contents in-place rather than appending a duplicate. Don't overwrite my edits to the surrounding sections.

The block:

```markdown
## Agent skills

### Issue tracker

[one-line summary of where issues are tracked]. See `docs/agents/issue-tracker.md`.

### Triage labels

[one-line summary of the label vocabulary]. See `docs/agents/triage-labels.md`.

### Domain docs

[one-line summary of layout — "single-context" or "multi-context"]. See `docs/agents/domain.md`.
```

Include the `### Triage labels` sub-block, and write `docs/agents/triage-labels.md`, only when the `/triage` workflow is available and Section B ran. When it isn't, both are omitted.

Then write the docs files using these seed templates as a starting point:

- [issue-tracker-github.md](~/.config/opencode/command-resources/setup-skills/issue-tracker-github.md) — GitHub issue tracker
- [issue-tracker-gitlab.md](~/.config/opencode/command-resources/setup-skills/issue-tracker-gitlab.md) — GitLab issue tracker
- [issue-tracker-local.md](~/.config/opencode/command-resources/setup-skills/issue-tracker-local.md) — local-markdown issue tracker
- [triage-labels.md](~/.config/opencode/command-resources/setup-skills/triage-labels.md) — label mapping (only if the `/triage` workflow is available)
- [domain.md](~/.config/opencode/command-resources/setup-skills/domain.md) — domain doc consumer rules + layout

For "other" issue trackers, write `docs/agents/issue-tracker.md` from scratch using my description.

### 5. Done

Tell me the setup is complete and which engineering workflows and skills will now read from these files. Mention that I can edit `docs/agents/*.md` directly later — re-running `/setup-skills` is only necessary if I want to switch issue trackers or restart from scratch.
