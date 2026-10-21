# Global Environment

## Shell

- OpenCode executes tool commands with `/usr/bin/bash`.
- Interactive Ghostty and tmux sessions use Zsh.
- Do not assume that interactive aliases, functions, or shell startup configuration are available.
- Honor a script's declared interpreter instead of assuming the interactive shell.

## Conventions

- All `*PLAN*.md` and `*NOTE*.md` files located at the project root are temporary files from prior sessions.
- Assume user cannot see output from subagents, so present options clearly before asking questions.
- When permissions prohibit a write required by a skill, complete the read-only analysis, identify the deferred
  artifact and intended path, and wait for a writable agent rather than attempting the denied write.
- An agent without subagent permission must return delegation requirements to the coordinating primary; do not bypass
  permission restrictions.

## Unresolved Decisions

- Ask the user before choosing an unapproved scope, behavior, architecture, interface, implementation approach, or
  meaningful trade-off. Routine implementation mechanics within an approved approach do not require separate approval.
- As soon as you identify an unresolved decision, stop the entire task. Present the decision and relevant options,
  then wait for the user's answer. Do not continue investigating, implementing, or delegating while awaiting that answer.
- Never treat a recommendation, an invented default, or an unstated assumption as user approval.
- Subagents must stop and report unresolved decisions to their primary. The primary may resolve them using existing
  user approval; otherwise it must ask the user and wait.

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
