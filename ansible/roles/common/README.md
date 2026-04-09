# Common Role

Installs base system packages across multiple Linux distributions.

## Requirements

- Supported OS: Debian/Ubuntu, Fedora/RHEL
- Privilege escalation required for package installation

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| dotfiles_home | `{{ ansible_facts['user_dir'] }}` | User home directory |
| dotfiles_user | `{{ ansible_facts['user_id'] }}` | Target username |

## Dependencies

None.

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - role: common
```
