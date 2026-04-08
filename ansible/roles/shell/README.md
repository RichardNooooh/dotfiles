# Shell Role

Installs and configures zsh with Oh My Zsh framework.

## Requirements

- `zsh` package (installed by common role)
- `curl` for Oh My Zsh installation

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| dotfiles_home | `{{ ansible_facts['user_dir'] }}` | User home directory |
| dotfiles_user | `{{ ansible_facts['user_id'] }}` | Target username |
| shell_default_shell | `/usr/bin/zsh` | Default shell path |
| shell_oh_my_zsh_repo | Official Oh My Zsh repo URL | Installation script URL |

## Dependencies

- common

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - role: shell
```

## Notes

User-specific tasks run without privilege escalation to prevent Oh My Zsh from being installed as root.
