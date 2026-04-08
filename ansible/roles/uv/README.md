# UV Role

Installs uv (Python package manager) and Python development tools.

## Requirements

- `curl` for standalone installation
- mise (optional, for mise-based installation)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| uv_install_method | `mise` | Installation method: `mise` or `standalone` |
| uv_installer_url | astral.sh installer URL | UV standalone installer URL |
| tools | `[debugpy, ruff, ty]` | Python tools to install via uv |

## Dependencies

- mise (when uv_install_method is `mise`)

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - role: uv
  vars:
    uv_install_method: standalone
```
