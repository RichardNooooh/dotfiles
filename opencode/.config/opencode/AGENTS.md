# Global Environment

## Shell

- The execution environment uses zsh, not Bash.
- Generate shell commands and syntax compatible with zsh.
- Do not use Bash-specific features unless explicitly invoking `bash`.
- Do not assume that interactive aliases, functions, or `.zshrc` configuration are available.
- For scripts that specifically require Bash, use `#!/usr/bin/env bash` and invoke Bash explicitly.

## Conventions

- All `*PLAN*.md` and `*NOTE*.md` files located at the project root are temporary files from prior sessions.
- Ensure all architectural and code decisions are explicitly accepted by user. Do not assume
  what the "correct" decision is.
- If a given prompt is vague or unclear, be sure to ask clarifying questions instead of making silent assumptions.
- Assume user cannot see output from subagents, so present options clearly before asking questions.
