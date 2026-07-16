# Global Environment

## Shell

- The execution environment uses zsh, not Bash.
- Generate shell commands and syntax compatible with zsh.
- Do not use Bash-specific features unless explicitly invoking `bash`.
- Do not assume that interactive aliases, functions, or `.zshrc` configuration are available.
- For scripts that specifically require Bash, use `#!/usr/bin/env bash` and invoke Bash explicitly.
