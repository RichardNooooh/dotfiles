# Dotfiles

[![Lint](https://github.com/RichardNooooh/dotfiles/actions/workflows/lint.yml/badge.svg)](https://github.com/RichardNooooh/dotfiles/actions/workflows/lint.yml)

Personal dotfiles for a WSL development environment and selected Windows applications. GNU Stow deploys the WSL
configuration as symlinks; separate scripts copy Windows configuration into the Windows user profile.

> [!WARNING]
> The Ansible setup is currently broken and unsupported. The files remain in the repository for possible future work,
> but they are not the primary setup path.

## Deployment Model

| Target | Configuration | Command | Behavior |
| ------ | ------------- | ------- | -------- |
| WSL home | zsh, Ghostty, Neovim, Zellij, tmux, mise, OpenCode, local bin | `./stow_config` | Creates symlinks with GNU Stow |
| Windows profile | GlazeWM and YASB | `./update_windows` | Replaces destination directories by copying |
| WSL QMK tree | Cubtyl keyboard | `./stow_keyboard` | Creates symlinks with GNU Stow |
| Windows QMK tree | Cubtyl keyboard | `./update_windows_keyboard` | Replaces the keyboard directory by copying |

Run the scripts from the repository root. The shell configuration expects the repository at `~/.dotfiles`; the
Windows update scripts honor `DOTFILES` when their source repository is elsewhere.

## Fresh WSL Setup

Install these prerequisites using the appropriate upstream or distribution instructions:

- Git, zsh, and GNU Stow
- [mise](https://mise.jdx.dev/)
- [Oh My Zsh](https://ohmyz.sh/)
- The Powerlevel10k theme
- The `fzf-tab`, `zsh-autosuggestions`, and `zsh-syntax-highlighting` Oh My Zsh plugins

Clone the repository, deploy the WSL configuration, and install the tools declared in
`mise/.config/mise/config.toml`:

```zsh
git clone git@github.com:RichardNooooh/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./stow_config
mise install
exec zsh
```

`stow_config` deploys the package list defined inside the script. Resolve any existing-file conflicts before
rerunning it; the script does not overwrite conflicting files in `$HOME`.

## Windows Configuration

The Windows update scripts run from WSL. Create an ignored `.env` file in the repository root containing the Windows
user profile path:

```zsh
WINDOWS_CONFIG='/mnt/c/Users/<windows-user>'
```

Deploy GlazeWM and YASB with:

```zsh
./update_windows
```

> [!CAUTION]
> `update_windows` recursively deletes each destination directory before copying its replacement. With the default
> configuration, it replaces `.glzr` and `.config` under `WINDOWS_CONFIG`; it does not merge their contents.

The YASB weather widget also expects these variables in the Windows environment:

- `YASB_WEATHER_API_KEY`
- `YASB_WEATHER_LOCATION`

## Keyboard Configuration

Choose the command for the environment where the QMK tree lives:

```zsh
# Symlink keyboard/qmk_firmware into the WSL home directory
./stow_keyboard

# Copy Cubtyl into the Windows QMK tree
./update_windows_keyboard
```

> [!CAUTION]
> `update_windows_keyboard` recursively deletes the destination `cubtyl` directory before copying its replacement.

## WSL Clipboard

The tmux configuration sends copied text through the stowed `wsl-clipboard` wrapper. The wrapper prefers
`win32yank.exe` for reliable UTF-8 handling and falls back to the WSL-provided `clip.exe` when `win32yank.exe` is not
available.

## Maintenance

Update tools managed by mise:

```zsh
mise upgrade
```

Run the repository checks:

```zsh
pre-commit run --all-files
```

## Unsupported Setup

The following paths are retained but are not current setup workflows:

- `bootstrap.sh` and `ansible/**`: broken, deferred Ansible bootstrap
- `ubuntu_install`: incomplete legacy installer
