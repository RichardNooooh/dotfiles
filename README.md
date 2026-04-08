# Dotfiles

[![Molecule Tests](https://github.com/RichardNooooh/dotfiles/actions/workflows/molecule.yml/badge.svg)](https://github.com/RichardNooooh/dotfiles/actions/workflows/molecule.yml)

Organized dotfiles inspired by ThePrimeagen. Note that the
Ansible files were vibe-configured by Kimi K2.5 using OpenCode.
Use at your own risk. The Molecule tests are not that good either...

## Why use Ansible for this?

I began using VMs on my Proxmox cluster as my dev environment, and I wanted a very convenient
way configuring my dotfiles on all of them. I really like the idea of spinning up a VM, easily configure 
my dotfiles on there, then destroy it all whenever I want to. At the same time, I'm not willing
to invest time on something like NixOS, which seems a bit *too much* for me.

## Quick Start (New Ansible Setup)

Bootstrap your entire environment with one command:

```bash
# Run on your local machine
./bootstrap.sh --local

# Or run on remote hosts (configure ansible/inventory.ini first)
./bootstrap.sh --remote
```

See `ansible/README.md` for detailed documentation.

## What's Included

- **Shell**: zsh + Oh My Zsh (git plugin)
- **Editor**: Neovim with LSP, DAP, and Treesitter
- **Terminal**: Ghostty + tmux + zellij
- **Fonts**: JetBrainsMono

## Prerequisites

All prerequisites are automatically installed by the Ansible playbook:

- `zsh` - shell
- `nvim` - editor (installed via mise)
- `ghostty` - terminal (stowed from dotfiles)
- `stow` - dotfile management
- `ripgrep`, `fd-find` - search tools for Telescope

### Windows (WSL) Configuration

Create an `.env` file with the `WINDOW_CONFIG` variable:

```bash
WINDOW_CONFIG='/mnt/c/Users/{USER}'
```

`yasb` requires a `.env` file containing:
- `YASB_WEATHER_API_KEY`
- `YASB_WEATHER_LOCATION`

## Tool Versions (Managed by mise)

| Tool | Version |
|------|---------|
| Python | 3.14 |
| Go | 1.26 |
| Node.js | 24 LTS |
| Neovim | latest (0.12+) |
| uv | latest |

## Directory Structure

```
.dotfiles/
├── ansible/              # Ansible playbooks for bootstrapping
│   ├── bootstrap.sh      # Main entry point
│   ├── inventory.ini     # Host inventory (local + remote)
│   ├── site.yml          # Main playbook
│   └── roles/            # Individual setup roles
├── zsh/                  # Zsh configuration
├── nvim/                 # Neovim configuration
├── tmux/                 # Tmux configuration
├── zellij/               # Zellij configuration
├── ghostty/              # Ghostty terminal config
├── fonts/                # JetBrainsMono font files
├── keyboard/             # QMK keyboard firmware
├── mise.toml             # mise configuration (tool versions)
└── README.md             # This file
```

## Manual Setup (Without Ansible)

If you prefer not to use Ansible:

```bash
# 1. Install base packages (example for Debian/Ubuntu)
sudo apt install zsh stow curl git build-essential

# 2. Install mise
curl https://mise.run | sh

# 3. Install tools via mise
mise install

# 4. Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 5. Stow dotfiles
./stow_config

# 6. Install Python packages via uv
uv tool install debugpy ruff ty
```

## Neovim Dependencies

Your Neovim config uses Mason for LSP/DAP tools. On first run, it will auto-install:

**LSP Servers**:
- `lua_ls` - Lua language server
- `gopls` - Go language server
- `ruff` - Python linter
- `ty` - Python type checker

**DAP (Debuggers)**:
- `delve` - Go debugger
- `debugpy` - Python debugger

**Formatters**:
- `stylua` - Lua formatter
- `gofmt` - Go formatter (built-in)

**Treesitter Parsers**:
- bash, c, diff, python, go, lua, markdown, terraform, vim

## Post-Installation

After running the bootstrap:

1. **Restart your shell** to activate zsh:
   ```bash
   exec zsh
   ```

2. **Run Neovim** to install plugins:
   ```bash
   nvim
   ```
   Wait for Lazy.nvim to install plugins, then restart Neovim.

3. **Verify installations**:
   ```bash
   python --version  # 3.14
   go version        # 1.26
   node --version    # v24.x
   nvim --version    # 0.12
   which debugpy ruff ty  # Python tools
   ```

## Maintenance

Update tools managed by mise:
```bash
mise upgrade
```

Re-run specific Ansible roles:
```bash
cd ansible
ansible-playbook -i inventory.ini site.yml --tags mise,uv
```

## Testing

The Ansible setup includes comprehensive Molecule tests for all roles:

```bash
# Test all roles
./bootstrap.sh --test
./bootstrap.sh --test-parallel  # Faster, runs in parallel

# Test a specific role (CI mode)
./bootstrap.sh --test-role common

# Local development testing
./bootstrap.sh --test-local common       # Verbose output, inspect containers
./bootstrap.sh --test-debug common       # Test and enter container shell
./bootstrap.sh --test-idempotence mise    # Quick idempotence check
./bootstrap.sh --test-destroy           # Clean up test containers
```

Tests run in Docker containers (Ubuntu, Arch, Fedora) to verify:
- Role functionality
- **Idempotency** (no changes on second run)
- Cross-platform compatibility

**Development Features:**
- `--test-local`: Verbose output (-vv), containers kept for inspection
- `--test-debug`: Test then automatically enter container shell
- `--test-idempotence`: Fast idempotence-only check

See `ansible/README.md` for detailed testing documentation.

## Supported Platforms

The Ansible playbook supports:
- Debian/Ubuntu

## Troubleshooting

**Ansible not found**: Run `./bootstrap.sh --install-only` to install Ansible only.

**Font not showing**: Run `fc-cache -fv` and restart your terminal.

**Neovim treesitter fails**: Ensure `gcc` and `make` are installed (handled by common role).

## TODO

1. Clean up the `update_windows_keyboard` script and keyboard directory structure.
2. ~~Clean up bootstrapping scripts~~ ✅ Now uses Ansible with Molecule testing
3. Fix test-role (uv) in CI (some weird inability to verify `uv` being available there...)
