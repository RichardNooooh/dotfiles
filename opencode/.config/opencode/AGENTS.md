# Global Environment

## Shell

- OpenCode executes tool commands with `/usr/bin/bash`.
- Interactive Ghostty and tmux sessions use Zsh.
- Do not assume that interactive aliases, functions, or shell startup configuration are available.
- Honor a script's declared interpreter instead of assuming the interactive shell.

## Conventions

- All `*PLAN*.md` and `*NOTE*.md` files located at the project root are temporary files from prior sessions.
- Ensure all architectural and code decisions are explicitly accepted by user. Do not assume
  what the "correct" decision is.
- If a given prompt is vague or unclear, be sure to ask clarifying questions instead of making silent assumptions.
- Assume user cannot see output from subagents, so present options clearly before asking questions.
- When permissions prohibit a write required by a skill, complete the read-only analysis, identify the deferred
  artifact and intended path, and wait for a writable agent rather than attempting the denied write.
- An agent without subagent permission must return delegation requirements to the coordinating primary; do not bypass
  permission restrictions.

## Research Delegation

- Keep researcher briefs concise: one focused question and at most two supporting goals, limited to what the primary
  needs for the current task. Specify narrow source boundaries, essential evidence, and a concrete stopping condition.
  Once sufficient evidence is found, stop and report remaining gaps rather than expanding the research scope.
- Start a fresh `research` agent for each brief and never resume it. Use one `research` agent by default; use up to
  three in one synthesis round only when their briefs are independently answerable. The primary owns synthesis and durable
  artifacts.
- For a non-trivial design choice that could benefit from current external practice, offer the user a bounded
  prior-art question and source scope, then wait for explicit approval before researching. Skip this offer for trivial
  or fully specified work.
- Once that bounded check is approved, delegate it to a fresh `research` agent; the primary owns synthesis.
