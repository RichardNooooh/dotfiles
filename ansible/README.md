# Ansible Dotfiles Bootstrap

This directory contains Ansible playbooks for bootstrapping your dotfiles environment across different systems.

## Overview

The Ansible setup provides:

- **OS-agnostic** package installation (Debian/Ubuntu, Fedora/RHEL)
- **Local or remote** deployment options
- **mise** for managing all development tools (Python, Go, Node.js, Neovim, uv)
- **uv** for Python package management
- **Automated** Oh My Zsh installation and shell configuration
- **Dotfiles stowing** via GNU stow
- **Font installation** (JetBrainsMono)

## Directory Structure

```text
ansible/
├── inventory.ini          # Host inventory (local + remote)
├── site.yml              # Main playbook
├── group_vars/
│   └── all.yml           # Variables (tool versions, paths)
└── roles/
    ├── common/           # Base system packages
    ├── mise/             # Install mise and tools
    ├── uv/               # Python packages via uv
    ├── shell/            # Oh My Zsh and zsh setup
    ├── dotfiles/         # Clone and stow dotfiles
    ├── neovim/           # Neovim configuration setup
    └── fonts/            # JetBrainsMono font installation
```

## Tool Versions (Configured)

| Tool | Version |
| ------ | --------- |
| Python | 3.14 |
| Go | 1.26 |
| Node.js | 24 (LTS) |
| Neovim | latest (0.12) |
| uv | latest |

## Quick Start

### 1. Local Deployment (Recommended for first run)

```bash
# From the dotfiles directory
./bootstrap.sh --local
```

### 2. Remote Deployment

Edit `ansible/inventory.ini` to add your remote hosts:

```ini
[remote]
myserver ansible_host=192.168.1.100 ansible_user=myuser
webserver ansible_host=example.com ansible_user=ubuntu ansible_port=2222
```

Then run:

```bash
./bootstrap.sh --remote
```

### 3. Install Ansible Only

If you just want to install Ansible without running playbooks:

```bash
./bootstrap.sh --install-only
```

## Running Playbooks Directly

If you already have Ansible installed:

```bash
# Local deployment
cd ansible
ansible-playbook -i inventory.ini site.yml --limit local

# Remote deployment
ansible-playbook -i inventory.ini site.yml --limit remote

# Run specific tags
ansible-playbook -i inventory.ini site.yml --tags mise
```

## Available Tags

| Tag | Description |
| ----- | ------------- |
| `common` | Base system packages |
| `mise` | Install mise, development tools, and Python packages |
| `shell` | Oh My Zsh and zsh configuration |
| `dotfiles` | Clone and stow dotfiles |
| `neovim` | Neovim setup and verification |
| `fonts` | Font installation |

## Role Details

### common

- Installs: zsh, stow, curl, wget, git, unzip, make, gcc, ripgrep, fd, tmux
- Creates: `~/.local/bin`, `~/.local/share/fonts`

### mise

- Downloads and installs mise
- Installs all tools from `mise/.config/mise/config.toml`:
  - Python 3.14, Go 1.26, Node.js 24
  - Neovim latest, uv latest
  - Additional: stylua, fd, ripgrep, fzf
- Installs Python packages via `uv tool install`:
  - `debugpy` - Python debugger for Neovim DAP
  - `ruff` - Python linter/formatter
  - `sqlfluff` - SQL linter/formatter
  - `ty` - Python type checker

### shell

- Installs Oh My Zsh (unattended)
- Changes default shell to zsh
- Backs up existing `.zshrc` if present
- Creates `.zshenv` if not exists

### dotfiles

- Creates `~/.config` subdirectories
- Runs `stow` for: zsh, ghostty, nvim, zellij, tmux
- Unstows before restowing to ensure clean state

### neovim

- Creates Neovim data directories
- Verifies required tools (git, gcc, make, python, node, go)
- Provides guidance on first-run setup

### fonts

- Downloads JetBrainsMono from GitHub releases
- Installs to `~/.local/share/fonts`
- Refreshes font cache

## What Gets Installed

### System Packages (via package manager)

- zsh, stow, git, curl, wget
- build tools: make, gcc, g++
- ripgrep, fd-find (or fd)
- tmux

### Development Tools (via mise)

- Python 3.14 + pip
- Go 1.26
- Node.js 24 LTS
- Neovim 0.12+
- uv (Python package manager)
- Additional: stylua, fzf

### Python Tools (via uv)

- debugpy - for Python debugging in Neovim
- ruff - fast Python linter/formatter
- ty - Python type checker

### Neovim Ecosystem (via Mason/Lazy)

On first Neovim run, these will be auto-installed:

- LSP Servers: lua_ls, gopls, ruff, ty
- DAP: delve (Go), debugpy (Python)
- Formatters: stylua, gofmt, ruff
- Treesitter parsers: bash, c, diff, python, go, lua, markdown, terraform, vim

## Troubleshooting

### Ansible not found after install

Log out and back in, or run:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Permission denied on bootstrap.sh

```bash
chmod +x bootstrap.sh
```

### Remote host connection issues

Ensure SSH key-based auth is set up:

```bash
ssh-copy-id user@remote-host
```

### Neovim treesitter compilation fails

Ensure build tools are installed (gcc, make). The `common` role handles this.

### Font not showing in terminal

Some terminals require restart. Verify with:

```bash
fc-list | grep -i jetbrains
```

## Configuration

### Tool Versions

Edit `mise/.config/mise/config.toml` to change versions, then re-run:

```bash
cd ansible && ansible-playbook -i inventory.ini site.yml --tags mise
```

### Inventory

Edit `ansible/inventory.ini` to add/modify hosts.

### Variables

Edit `ansible/group_vars/all.yml` to change:

- stow_folders
- Tool versions (though mise config is authoritative)
- Font URL
- Shell paths

## Post-Installation

After running the playbook:

1. **Open a new terminal** (or `exec zsh`) to activate zsh
2. **Run Neovim** for the first time:

   ```bash
   nvim
   ```

   Wait for Lazy to install plugins, then restart.
3. **Verify tools**:

   ```bash
   which python go node nvim uv
   python --version  # Should show 3.14
   go version        # Should show 1.26
   node --version    # Should show v24.x
   nvim --version    # Should show 0.12
   ```

## Maintenance

To update tools:

```bash
mise upgrade
```

To re-run specific parts:

```bash
# Re-stow dotfiles
ansible-playbook -i inventory.ini site.yml --tags dotfiles
```
