# Ansible Dotfiles Bootstrap

This directory contains Ansible playbooks for bootstrapping your dotfiles environment across different systems.

## Overview

The Ansible setup provides:
- **OS-agnostic** package installation (Debian/Ubuntu, Arch, Fedora, Alpine, openSUSE)
- **Local or remote** deployment options
- **mise** for managing all development tools (Python, Go, Node.js, Neovim, uv)
- **uv** for Python package management
- **Automated** Oh My Zsh installation and shell configuration
- **Dotfiles stowing** via GNU stow
- **Font installation** (JetBrainsMono)

## Directory Structure

```
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
|------|---------|
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
ansible-playbook -i inventory.ini site.yml --tags mise,uv
```

## Available Tags

| Tag | Description |
|-----|-------------|
| `common` | Base system packages |
| `mise` | Install mise and development tools |
| `uv` | Install Python packages via uv |
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

### uv
- Installs Python packages via `uv tool install`:
  - `debugpy` - Python debugger for Neovim DAP
  - `ruff` - Python linter/formatter
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
# Update only Python packages
ansible-playbook -i inventory.ini site.yml --tags uv

# Re-stow dotfiles
ansible-playbook -i inventory.ini site.yml --tags dotfiles
```

## Testing with Molecule

All roles include Molecule tests to ensure they work correctly and are idempotent across different Linux distributions.

### Quick Test (via bootstrap.sh)

```bash
# Test all roles (sequential)
./bootstrap.sh --test

# Test all roles (parallel - faster)
./bootstrap.sh --test-parallel

# Test a specific role (CI mode)
./bootstrap.sh --test-role common
./bootstrap.sh --test-role mise
./bootstrap.sh --test-role shell

# Local development testing with verbose output
./bootstrap.sh --test-local common

# Debug mode - test and enter container shell
./bootstrap.sh --test-debug common

# Quick idempotence check only
./bootstrap.sh --test-idempotence mise

# Clean up all test containers
./bootstrap.sh --test-destroy
```

### Local Development Testing

The `--test-local` and `--test-debug` options are designed for active development:

| Option | Purpose | Keeps Container | Enters Shell |
|--------|---------|----------------|--------------|
| `--test-local` | Verbose test output, all platforms | ✓ | ✗ |
| `--test-debug` | Test with shell access after | ✓ | ✓ |
| `--test-idempotence` | Quick idempotence check | ✗ | ✗ |

```bash
# Test locally with verbose Ansible output (-vvv)
./bootstrap.sh --test-local common
# Container stays running for inspection

# Test and automatically enter container shell
./bootstrap.sh --test-debug common
# Tests run, then drops you into Ubuntu container bash

# Quick idempotence check (faster)
./bootstrap.sh --test-idempotence shell
# Only checks if role produces changes on second run
```

After using `--test-local` or `--test-debug`, containers remain running. To inspect:

```bash
# List running containers
docker ps | grep molecule

# Enter a specific container
docker exec -it <container-name> bash

# View container logs
docker logs <container-name>

# Clean up when done
./bootstrap.sh --test-destroy
```

### Manual Molecule Testing

```bash
# Install Molecule and dependencies
pip3 install molecule molecule-plugins[docker] docker

# Test a specific role
cd ansible/roles/common
molecule test

# Test with specific platforms
molecule test --platform ubuntu-instance
molecule test --platform arch-instance
molecule test --platform fedora-instance

# Run full test sequence
molecule test          # Creates, converges, verifies, destroys
molecule create        # Just create the test instance
molecule converge      # Apply the role
molecule verify        # Run verification tests
molecule destroy       # Clean up

# Debug mode - keep container after test
molecule test --destroy never
molecule test --destroy never  # Keeps container for inspection
```

### Test Structure

Each role has a `molecule/default/` directory containing:

| File | Purpose |
|------|---------|
| `molecule.yml` | Platform definitions (Docker containers) |
| `converge.yml` | Playbook to apply the role |
| `verify.yml` | Assertions to verify the role worked |
| `Dockerfile.arch` | Custom Arch Linux image (systemd support) |

### Tested Platforms

Tests run on Docker containers for:
- **Ubuntu 24.04** (LTS)
- **Arch Linux** (rolling)
- **Fedora 40**

### CI/CD (GitHub Actions)

Tests automatically run on:
- Every push to `main` or `master`
- Every pull request
- Manual workflow dispatch

The workflow (`.github/workflows/molecule.yml`) tests:
1. All individual roles
2. Full playbook integration
3. Idempotence (re-running produces no changes)

### Writing Tests

To add tests to a role, create `molecule/default/verify.yml`:

```yaml
---
- name: Verify
  hosts: all
  gather_facts: false
  
  tasks:
    - name: Check if package is installed
      ansible.builtin.package:
        name: zsh
        state: present
      check_mode: true
      register: pkg_check
      
    - name: Assert package is installed
      ansible.builtin.assert:
        that:
          - pkg_check is not failed
```

### Idempotency Testing

All tests include an idempotence check:
- Role is applied twice
- Second run must produce **0 changes**

If idempotence fails, check for:
- Shell tasks without `changed_when`
- Commands that always report "changed"
- Missing `creates` or `removes` parameters

### Local Test Requirements

- Docker (or Podman with podman-docker)
- Python 3.11+
- molecule, molecule-plugins[docker]

### Debugging Tests

```bash
# Keep containers after test for inspection
molecule test --destroy never

# Login to running container
docker exec -it <container-name> bash

# Run specific test phase
molecule create
molecule converge
molecule verify
```
