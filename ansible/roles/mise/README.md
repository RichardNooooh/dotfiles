# Mise Role

Installs mise (formerly rtx) version manager and development tools.

## Requirements

- `curl` for downloading mise
- `bash` for activation scripts

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| dotfiles_home | `{{ ansible_env.HOME }}` | User home directory |
| dotfiles_repo | Repository path | Dotfiles repository location |

## Dependencies

None.

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - role: mise
```
