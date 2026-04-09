# AGENTS.md

Dotfiles repository using Ansible for bootstrapping with comprehensive Molecule testing.

## Repository Type

- **Primary**: Ansible playbooks for cross-platform dotfiles setup
- **Secondary**: Configuration files for zsh, nvim, tmux, ghostty, zellij
- **Testing**: Molecule tests for all roles (Docker-based, multi-platform)

## Entry Points

```bash
# Bootstrap everything (installs Ansible, runs playbooks)
./bootstrap.sh --local          # Local deployment
./bootstrap.sh --remote         # Remote deployment (configure inventory.ini first)

# Manual stowing (after Ansible setup)
./stow_config                   # Stow main dotfiles (zsh, nvim, tmux, ghostty, zellij)
./stow_keyboard                 # Stow keyboard config (WSL-specific)
```

## Testing (Critical)

All Ansible roles have Molecule tests. **Never skip testing when modifying roles.**

```bash
# Test all roles (sequential)
./bootstrap.sh --test

# Test all roles (parallel - faster)
./bootstrap.sh --test-parallel

# Test specific role (CI mode - destroys containers)
./bootstrap.sh --test-role <role>

# Development testing (keeps containers, verbose output)
./bootstrap.sh --test-local <role>      # Verbose (-vv), containers kept
./bootstrap.sh --test-debug <role>      # Test then enter container shell
./bootstrap.sh --test-idempotence <role>  # Quick idempotence check only

# Cleanup
./bootstrap.sh --test-destroy
```

Roles: `common`, `mise`, `uv`, `shell`, `dotfiles`, `neovim`, `fonts`

Test platforms: Ubuntu 24.04, Fedora 40 (Docker containers)

## Linting & Quality

Pre-commit hooks enforce standards:

```bash
# Run all checks manually
pre-commit run --all-files

# Specific tools
ansible-lint -c ansible/.ansible-lint ansible/
yamllint -c ansible/.yamllint ansible/
```

## Key Configuration Files

| File | Purpose |
|------|---------|
| `mise/.config/mise/config.toml` | Tool versions (Python 3.14, Go 1.26, Node 24, Neovim latest) |
| `ansible/inventory.ini` | Host inventory (local + remote) |
| `ansible/site.yml` | Main playbook orchestrating all roles |
| `ansible/group_vars/all.yml` | Role variables (stow_folders, paths) |
| `ansible/.ansible-lint` | Ansible linting rules |
| `ansible/.yamllint` | YAML linting rules |

## Architecture Notes

- **Roles**: 7 Ansible roles in `ansible/roles/`, each with `molecule/default/`
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

- **OS support**: Debian/Ubuntu, Fedora/RHEL
- **No root**: Playbooks warn if run as root (use `--limit local` instead)
- **CI/CD**: GitHub Actions runs Molecule tests + integration tests on PR/push
- **WSL**: Windows config path in `.env` (`WINDOWS_CONFIG='/mnt/c/Users/{USER}'`)
