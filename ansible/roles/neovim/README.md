# Neovim Role

Sets up Neovim data directories and verifies tool dependencies.

## Requirements

- Neovim installed via mise
- `gcc`, `make` for treesitter compilation
- `git`, `python`, `node`, `go` for LSP/DAP tools

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| dotfiles_home | `{{ ansible_env.HOME }}` | User home directory |

## Dependencies

- mise (provides Neovim and tools)

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - role: neovim
```

## Notes

Treesitter parsers and Mason LSP tools are installed automatically by Neovim on first run, not by Ansible.
