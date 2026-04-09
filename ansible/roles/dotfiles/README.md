# Dotfiles Role

Manages dotfiles repository and stows configurations.

## Requirements

- `git` for cloning repository
- `stow` for managing symlinks (installed by common role)

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| dotfiles_home | `{{ ansible_facts['user_dir'] }}` | User home directory |
| dotfiles_user | `{{ ansible_facts['user_id'] }}` | System username |
| dotfiles_github_user | `RichardNooooh` | GitHub username for repo cloning |
| dotfiles_repo | `{{ dotfiles_home }}/.dotfiles` | Local repository path |
| dotfiles_stow_folders | `zsh,nvim,tmux,zellij,ghostty,mise` | Directories to stow |

## Dependencies

- common

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - role: dotfiles
  vars:
    dotfiles_repo: "/home/user/.dotfiles"
```
