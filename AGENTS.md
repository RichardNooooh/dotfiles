# AGENTS.md

Personal dotfiles for a WSL development environment and selected Windows applications. Read `README.md` for the
operational setup and deployment workflows.

## Active Architecture

- GNU Stow deploys WSL configuration as symlinks into `$HOME`.
- `stow_config` owns the active WSL package list.
- `update_windows` copies GlazeWM and YASB configuration into the Windows user profile.
- `stow_keyboard` and `update_windows_keyboard` are alternative WSL and Windows targets for the Cubtyl QMK config.
- mise owns development tool versions through `mise/.config/mise/config.toml`.

Do not duplicate exact tool versions or Neovim-managed dependency inventories in repository-level documentation.
Reference their canonical configuration files instead.

## Entry Points

```zsh
./stow_config
./update_windows
./stow_keyboard
./update_windows_keyboard
```

Run these scripts from the repository root. `update_windows` and `update_windows_keyboard` recursively delete their
destination directories before copying replacements; preserve that warning whenever documenting or changing them.

`bootstrap.sh`, `ubuntu_install`, and `ansible/**` are unsupported legacy or deferred setup paths. Do not modify
Ansible files or present Ansible as the primary architecture unless the user specifically requests Ansible work.

## Validation

CI runs repository linting only. There is no maintained integration test suite.

```zsh
pre-commit run --all-files
```

Relevant checks include Markdownlint, ShellCheck for non-zsh scripts, StyLua for Neovim Lua, actionlint, and
Ansible Lint for changes under `ansible/`.

## Constraints

- Preserve GNU Stow package structure: each package mirrors paths relative to its deployment target.
- Keep WSL and Windows deployment semantics distinct: WSL uses symlinks; Windows scripts copy directories.
- The ignored root `.env` provides `WINDOWS_CONFIG` to Windows update scripts. Do not commit local paths or secrets.
- Prefer small, factual documentation that points to current configuration over manually maintained snapshots.
