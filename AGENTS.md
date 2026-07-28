# AGENTS.md

Dotfiles repository using Ansible for bootstrapping.

## Repository Type

- **Primary**: Ansible playbooks for cross-platform dotfiles setup
- **Secondary**: Configuration files for zsh, nvim, tmux, ghostty, zellij

## Entry Points

```bash
# Bootstrap everything (installs Ansible, runs playbooks)
./bootstrap.sh --local          # Local deployment
./bootstrap.sh --remote         # Remote deployment (configure inventory.ini first)

# Manual stowing (after Ansible setup)
./stow_config                   # Stow main dotfiles (zsh, nvim, tmux, ghostty, zellij)
./stow_keyboard                 # Stow keyboard config (WSL-specific)
```

## Linting & Quality

CI runs repository linting only. There is no maintained role or integration test suite.

```bash
# Run all checks manually
pre-commit run --all-files
```

## Key Configuration Files

| File | Purpose |
| ------ | --------- |
| `mise/.config/mise/config.toml` | Tool versions (Python 3.14, Go 1.26, Node 24, Neovim latest) |
| `ansible/inventory.ini` | Host inventory (local + remote) |
| `ansible/site.yml` | Main playbook orchestrating all roles |
| `ansible/group_vars/all.yml` | Role variables (stow_folders, paths) |
| `ansible/.ansible-lint` | Ansible linting rules |

## Architecture Notes

- **Roles**: Ansible roles in `ansible/roles/`
- **Idempotency**: All roles must be idempotent (0 changes on second run)
- **Privilege escalation**: Most roles run as root; `mise`, `dotfiles`, `neovim` run as user
- **Dotfile management**: Uses GNU stow; unstows before restowing for clean state
- **Tool management**: mise handles all dev tools; uv handles Python packages

## Common Tasks

```bash
# Run specific tags only
ansible-playbook -i ansible/inventory.ini ansible/site.yml --tags mise

# Update tools after changing mise/.config/mise/config.toml
mise upgrade
```

## Constraints

- **No root**: Playbooks warn if run as root (use `--limit local` instead)
- **CI/CD**: GitHub Actions runs repository linting on pushes and pull requests
- **WSL**: Windows config path in `.env` (`WINDOWS_CONFIG='/mnt/c/Users/{USER}'`)
