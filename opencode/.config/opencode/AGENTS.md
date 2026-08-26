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
