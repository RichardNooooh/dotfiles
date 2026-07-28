#!/usr/bin/env bash
# Bootstrap script to install Ansible and run the dotfiles playbook
# Usage: ./bootstrap.sh [--local|--remote|--install-only|-h|--help]
#
# Examples:
#   ./bootstrap.sh --local                          # Deploy to localhost
#   ./bootstrap.sh --remote                         # Deploy to remote hosts
#   ./bootstrap.sh --install-only                   # Install Ansible only

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "$ID"
    elif command -v lsb_release >/dev/null 2>&1; then
        lsb_release -is | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

install_ansible_debian() {
    log_info "Detected Debian/Ubuntu system"
    log_info "Updating package list..."
    sudo apt-get update
    log_info "Installing dependencies..."
    sudo apt-get install -y software-properties-common
    log_info "Adding Ansible PPA..."
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    log_info "Installing Ansible..."
    sudo apt-get install -y ansible
}

install_ansible_fedora() {
    log_info "Detected Fedora/RHEL system"
    log_info "Installing Ansible..."
    sudo dnf install -y ansible
}

install_ansible_pip() {
    log_warn "Could not detect package manager. Falling back to pip..."
    log_info "Installing pip and Ansible..."
    if command -v python3 >/dev/null 2>&1; then
        python3 -m pip install --user ansible
    elif command -v python >/dev/null 2>&1; then
        python -m pip install --user ansible
    else
        log_error "Python is not installed. Please install Python first."
        exit 1
    fi
}

install_ansible() {
    local os
    os=$(detect_os)
    log_info "Detected OS: $os"

    case "$os" in
        debian|ubuntu|pop|elementary|linuxmint)
            install_ansible_debian
            ;;
        fedora|rhel|centos|rocky|almalinux)
            install_ansible_fedora
            ;;
        *)
            log_warn "Unknown OS: $os"
            install_ansible_pip
            ;;
    esac
}

verify_ansible() {
    if command -v ansible >/dev/null 2>&1; then
        log_info "Ansible installed successfully!"
        ansible --version
    else
        log_error "Ansible installation failed or ansible is not in PATH"
        exit 1
    fi
}

show_usage() {
    cat << EOF
Usage: ./bootstrap.sh [OPTIONS]

Bootstrap script to install Ansible and run the dotfiles playbook.

DEPLOYMENT OPTIONS:
    --local                    Run playbook on localhost (default)
    --remote                   Run playbook on remote hosts defined in inventory.ini
    --install-only             Only install Ansible, don't run playbook
    -h, --help                 Show this help message

EXAMPLES:
    ./bootstrap.sh                          # Install Ansible and run on localhost
    ./bootstrap.sh --local                  # Same as above
    ./bootstrap.sh --remote                 # Run on remote hosts
    ./bootstrap.sh --install-only           # Just install Ansible

Before running with --remote, edit ansible/inventory.ini to configure your remote hosts.
EOF
}

main() {
    local run_mode="local"
    local install_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --local)
                run_mode="local"
                shift
                ;;
            --remote)
                run_mode="remote"
                shift
                ;;
            --install-only)
                install_only=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    log_info "Starting Ansible bootstrap..."

    # Check if running as root (not recommended for Ansible)
    if [ "$EUID" -eq 0 ]; then
        log_warn "Running as root is not recommended for Ansible playbooks"
        log_warn "These playbooks use 'become' where necessary"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Install Ansible if not present
    if ! command -v ansible >/dev/null 2>&1; then
        install_ansible
        verify_ansible
    else
        log_info "Ansible is already installed"
        ansible --version | head -1
    fi

    # Exit if install-only mode
    if [ "$install_only" = true ]; then
        log_info "Ansible installed. Exiting (--install-only mode)"
        exit 0
    fi

    # Determine playbook path
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local playbook_path="$script_dir/ansible/site.yml"
    local inventory_path="$script_dir/ansible/inventory.ini"

    if [ ! -f "$playbook_path" ]; then
        log_error "Playbook not found: $playbook_path"
        log_error "Please ensure the ansible/ directory exists"
        exit 1
    fi

    # Run appropriate playbook command
    log_info "Running Ansible playbook..."
    if [ "$run_mode" = "local" ]; then
        log_info "Running on localhost..."
        ansible-playbook -i "$inventory_path" "$playbook_path" --limit local --ask-become-pass
    else
        log_info "Running on remote hosts..."
        log_warn "Ensure you have configured ansible/inventory.ini with your remote hosts"
        ansible-playbook -i "$inventory_path" "$playbook_path" --limit remote --ask-pass --ask-become-pass
    fi

    log_info "Bootstrap complete!"
}

main "$@"
