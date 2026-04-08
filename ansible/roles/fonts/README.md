# Fonts Role

Installs JetBrainsMono font for terminal and editor use.

## Requirements

- `curl` for downloading fonts
- `fc-cache` for refreshing font cache
- Dependencies: common role (creates directories)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| fonts_install_dir | `{{ dotfiles_home }}/.local/share/fonts` | Font installation directory |
| fonts_url | JetBrainsMono GitHub release URL | Font download URL |

## Dependencies

- common

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - role: fonts
```
