#!/usr/bin/env bash
# Bootstrap script to install Ansible and run Molecule tests
# Usage: ./bootstrap.sh [--local|--remote|--test|--test-role <role>|--test-local <role>|--test-debug <role>|--test-idempotence <role>|--test-parallel|--test-destroy]
#
# Examples:
#   ./bootstrap.sh --local                          # Deploy to localhost
#   ./bootstrap.sh --remote                         # Deploy to remote hosts
#   ./bootstrap.sh --test                           # Run all tests (CI mode)
#   ./bootstrap.sh --test-local common             # Test role locally
#   ./bootstrap.sh --test-debug common             # Test and enter container
#   ./bootstrap.sh --test-idempotence common       # Quick idempotence check
#   ./bootstrap.sh --test-parallel                  # Test all roles in parallel
#   ./bootstrap.sh --test-destroy                   # Clean up test containers

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
        . /etc/os-release
        echo "$ID"
    elif command -v lsb_release >/dev/null 2>&1; then
        lsb_release -is | tr '[:upper:]' '[:lower:]'
    elif [ -f /etc/arch-release ]; then
        echo "arch"
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

install_ansible_arch() {
    log_info "Detected Arch Linux system"
    log_info "Installing Ansible..."
    sudo pacman -Sy --noconfirm ansible
}

install_ansible_fedora() {
    log_info "Detected Fedora/RHEL system"
    log_info "Installing Ansible..."
    sudo dnf install -y ansible
}

install_ansible_alpine() {
    log_info "Detected Alpine Linux system"
    log_info "Installing Ansible..."
    sudo apk add ansible
}

install_ansible_opensuse() {
    log_info "Detected openSUSE system"
    log_info "Installing Ansible..."
    sudo zypper install -y ansible
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
    local os=$(detect_os)
    log_info "Detected OS: $os"

    case "$os" in
        debian|ubuntu|pop|elementary|linuxmint)
            install_ansible_debian
            ;;
        arch|manjaro|endeavouros)
            install_ansible_arch
            ;;
        fedora|rhel|centos|rocky|almalinux)
            install_ansible_fedora
            ;;
        alpine)
            install_ansible_alpine
            ;;
        opensuse*)
            install_ansible_opensuse
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

TESTING OPTIONS:
    --test                     Run Molecule tests for all roles (CI mode)
    --test-role <role>         Run Molecule tests for a specific role (CI mode)
    --test-local <role>        Test role locally with verbose output (all platforms)
    --test-debug <role>        Test role and drop into container shell for inspection
    --test-idempotence <role>  Run only idempotence check for a role
    --test-parallel            Run tests for all roles in parallel
    --test-destroy             Clean up all test containers

EXAMPLES:
    ./bootstrap.sh                          # Install Ansible and run on localhost
    ./bootstrap.sh --local                  # Same as above
    ./bootstrap.sh --remote                 # Run on remote hosts
    ./bootstrap.sh --install-only           # Just install Ansible

    # Testing
    ./bootstrap.sh --test                   # Test all roles (sequential)
    ./bootstrap.sh --test-parallel          # Test all roles (parallel)
    ./bootstrap.sh --test-role common       # Test specific role (CI mode)
    ./bootstrap.sh --test-local common      # Test with verbose output
    ./bootstrap.sh --test-debug common      # Test and enter container shell
    ./bootstrap.sh --test-idempotence mise   # Quick idempotence check only
    ./bootstrap.sh --test-destroy           # Clean up all test containers

LOCAL TESTING:
    The --test-local and --test-debug options are designed for development:
    - Tests run on all three platforms (Ubuntu, Arch, Fedora)
    - Containers are kept alive for inspection
    - Verbose Ansible output (-vv) is enabled
    - Use --test-debug to automatically enter the container after testing

Before running with --remote, edit ansible/inventory.ini to configure your remote hosts.

TEST REQUIREMENTS:
    - Docker (must be running)
    - molecule: pip3 install molecule
    - molecule-plugins[docker]: pip3 install molecule-plugins[docker]
EOF
}

check_test_requirements() {
    # Check if molecule is installed
    if ! command -v molecule >/dev/null 2>&1; then
        log_warn "Molecule not found. Installing..."
        pip3 install molecule molecule-plugins[docker] docker
    fi
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is required for Molecule tests but not found"
        log_info "Please install Docker and ensure you can run docker commands"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

run_molecule_tests() {
    local test_role="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local roles_dir="$script_dir/ansible/roles"
    
    check_test_requirements
    
    cd "$roles_dir"
    
    if [ -n "$test_role" ]; then
        # Test specific role
        if [ -d "$test_role/molecule" ]; then
            log_info "Running Molecule tests for role: $test_role"
            cd "$test_role"
            molecule test
        else
            log_error "Role '$test_role' does not have Molecule tests"
            log_info "Available roles with tests:"
            for d in */molecule; do
                log_info "  - $(dirname $d)"
            done
            exit 1
        fi
    else
        # Test all roles
        log_info "Running Molecule tests for all roles..."
        local failed_roles=""
        
        for role_dir in */molecule; do
            if [ -d "$role_dir" ]; then
                local role=$(dirname "$role_dir")
                log_info "Testing role: $role"
                cd "$roles_dir/$role"
                if ! molecule test; then
                    log_error "Tests failed for role: $role"
                    failed_roles="$failed_roles $role"
                fi
                cd "$roles_dir"
            fi
        done
        
        if [ -n "$failed_roles" ]; then
            log_error "Some roles failed tests:$failed_roles"
            exit 1
        else
            log_info "All Molecule tests passed!"
        fi
    fi
}

run_molecule_local() {
    local test_role="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local roles_dir="$script_dir/ansible/roles"
    
    check_test_requirements
    
    if [ -z "$test_role" ]; then
        log_error "--test-local requires a role name"
        log_info "Usage: ./bootstrap.sh --test-local <role>"
        exit 1
    fi
    
    if [ ! -d "$roles_dir/$test_role/molecule" ]; then
        log_error "Role '$test_role' does not have Molecule tests"
        log_info "Available roles with tests:"
        for d in "$roles_dir"/*/molecule; do
            if [ -d "$d" ]; then
                log_info "  - $(basename $(dirname $d))"
            fi
        done
        exit 1
    fi
    
    log_info "Running local Molecule tests for role: $test_role"
    log_info "Platforms: Ubuntu 24.04, Arch Linux, Fedora 40"
    log_info "Container will be kept alive for inspection"
    log_info "Ansible verbose mode enabled (-vv)"
    echo ""
    
    cd "$roles_dir/$test_role"
    
    # Export verbose environment
    export ANSIBLE_VERBOSITY=2
    export MOLECULE_NO_LOG=false
    
    # Run test but don't destroy
    log_info "Creating test containers..."
    molecule create || { log_error "Failed to create containers"; exit 1; }
    
    log_info "Converging (applying role)..."
    molecule converge || { log_error "Converge failed"; exit 1; }
    
    log_info "Running verification tests..."
    molecule verify || { log_error "Verification failed"; exit 1; }
    
    log_info "Running idempotence check..."
    molecule idempotence || { log_warn "Idempotence check had changes (this may be OK for some roles)"; }
    
    log_info ""
    log_info "✓ Local testing complete!"
    log_info ""
    log_info "Container is still running. To inspect:"
    log_info "  docker exec -it <container-name> bash"
    log_info ""
    log_info "To view logs:"
    log_info "  docker logs <container-name>"
    log_info ""
    log_info "To destroy when done:"
    log_info "  cd ansible/roles/$test_role && molecule destroy"
    log_info "  OR: ./bootstrap.sh --test-destroy"
}

run_molecule_debug() {
    local test_role="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local roles_dir="$script_dir/ansible/roles"
    
    check_test_requirements
    
    if [ -z "$test_role" ]; then
        log_error "--test-debug requires a role name"
        log_info "Usage: ./bootstrap.sh --test-debug <role>"
        exit 1
    fi
    
    if [ ! -d "$roles_dir/$test_role/molecule" ]; then
        log_error "Role '$test_role' does not have Molecule tests"
        exit 1
    fi
    
    log_info "Running debug Molecule tests for role: $test_role"
    log_info "Platforms: Ubuntu 24.04, Arch Linux, Fedora 40"
    echo ""
    
    cd "$roles_dir/$test_role"
    
    # Run full test but keep containers
    export ANSIBLE_VERBOSITY=2
    
    log_info "Running molecule test (destroy will be skipped)..."
    if molecule test --destroy never; then
        log_info "✓ Tests passed!"
    else
        log_warn "Tests failed or had issues"
    fi
    
    # Get container names
    local containers=$(docker ps --format "{{.Names}}" | grep "molecule-$test_role" || true)
    
    if [ -n "$containers" ]; then
        log_info ""
        log_info "Running containers:"
        echo "$containers" | while read container; do
            log_info "  - $container"
        done
        
        log_info ""
        log_info "Entering Ubuntu container shell..."
        local ubuntu_container=$(echo "$containers" | grep "ubuntu" | head -1)
        
        if [ -n "$ubuntu_container" ]; then
            log_info "Container: $ubuntu_container"
            echo ""
            docker exec -it "$ubuntu_container" bash
        else
            log_warn "No Ubuntu container found. Available containers:"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep "molecule-$test_role"
            
            log_info ""
            log_info "To enter a specific container:"
            log_info "  docker exec -it <container-name> bash"
        fi
        
        log_info ""
        log_info "To destroy all test containers:"
        log_info "  ./bootstrap.sh --test-destroy"
    else
        log_warn "No running containers found"
    fi
}

run_molecule_idempotence() {
    local test_role="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local roles_dir="$script_dir/ansible/roles"
    
    check_test_requirements
    
    if [ -z "$test_role" ]; then
        log_error "--test-idempotence requires a role name"
        log_info "Usage: ./bootstrap.sh --test-idempotence <role>"
        exit 1
    fi
    
    if [ ! -d "$roles_dir/$test_role/molecule" ]; then
        log_error "Role '$test_role' does not have Molecule tests"
        exit 1
    fi
    
    log_info "Running idempotence check for role: $test_role"
    log_info "This will run the role twice and check for changes..."
    echo ""
    
    cd "$roles_dir/$test_role"
    
    # Quick test: create, converge twice, check for changes
    log_info "Setting up container..."
    molecule destroy
    molecule create
    
    log_info "First converge..."
    molecule converge
    
    log_info "Second converge (idempotence check)..."
    if molecule converge 2>&1 | tee /tmp/molecule_idempotence.log | grep -q "changed=0.*failed=0"; then
        log_info "✓ Idempotence check PASSED - no changes on second run"
    else
        log_warn "⚠ Idempotence check had changes - reviewing output..."
        grep -E "(changed=|TASK|PLAY)" /tmp/molecule_idempotence.log | tail -20
    fi
    
    molecule destroy
    rm -f /tmp/molecule_idempotence.log
}

run_molecule_parallel() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local roles_dir="$script_dir/ansible/roles"
    
    check_test_requirements
    
    log_info "Running Molecule tests in parallel for all roles..."
    log_info "This requires GNU parallel. Installing if needed..."
    
    if ! command -v parallel >/dev/null 2>&1; then
        log_warn "GNU parallel not found. Attempting to install..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y parallel
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -Sy --noconfirm parallel
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y parallel
        else
            log_error "Could not install GNU parallel. Please install it manually."
            exit 1
        fi
    fi
    
    cd "$roles_dir"
    
    # Create a temp file with all roles to test
    local tmpfile=$(mktemp)
    for role_dir in */molecule; do
        if [ -d "$role_dir" ]; then
            echo "$(dirname "$role_dir")" >> "$tmpfile"
        fi
    done
    
    log_info "Testing $(wc -l < "$tmpfile") roles in parallel..."
    
    # Run tests in parallel
    parallel --jobs 3 --joblog /tmp/molecule_parallel.log \
        'cd {}; echo "Testing: {/}"; molecule test' ::: $(cat "$tmpfile")
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_info "✓ All parallel tests passed!"
    else
        log_error "Some parallel tests failed. Check /tmp/molecule_parallel.log"
        cat /tmp/molecule_parallel.log
    fi
    
    rm -f "$tmpfile"
    return $exit_code
}

cleanup_molecule() {
    log_info "Cleaning up all Molecule test containers..."
    
    # Find and destroy all molecule containers
    local containers=$(docker ps -a --format "{{.Names}}" | grep "molecule-" || true)
    
    if [ -n "$containers" ]; then
        log_info "Found containers:"
        echo "$containers"
        
        log_info "Stopping and removing..."
        echo "$containers" | xargs -r docker stop 2>/dev/null || true
        echo "$containers" | xargs -r docker rm -f 2>/dev/null || true
        
        log_info "✓ Cleanup complete"
    else
        log_info "No Molecule containers found"
    fi
    
    # Also clean up any dangling images from molecule
    local dangling=$(docker images --filter "dangling=true" --filter "label=molecule" -q 2>/dev/null || true)
    if [ -n "$dangling" ]; then
        log_info "Removing dangling images..."
        echo "$dangling" | xargs -r docker rmi 2>/dev/null || true
    fi
}

main() {
    local run_mode="local"
    local install_only=false
    local run_tests=false
    local test_role=""
    local test_local=false
    local test_debug=false
    local test_idempotence=false
    local test_parallel=false
    local test_destroy=false
    local test_role_name=""

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
            --test)
                run_tests=true
                shift
                ;;
            --test-role)
                if [[ -n "${2:-}" ]] && [[ "${2:-}" != --* ]]; then
                    test_role="$2"
                    shift 2
                else
                    log_error "--test-role requires a role name"
                    exit 1
                fi
                ;;
            --test-local)
                if [[ -n "${2:-}" ]] && [[ "${2:-}" != --* ]]; then
                    test_local=true
                    test_role_name="$2"
                    shift 2
                else
                    log_error "--test-local requires a role name"
                    log_info "Usage: ./bootstrap.sh --test-local <role>"
                    exit 1
                fi
                ;;
            --test-debug)
                if [[ -n "${2:-}" ]] && [[ "${2:-}" != --* ]]; then
                    test_debug=true
                    test_role_name="$2"
                    shift 2
                else
                    log_error "--test-debug requires a role name"
                    log_info "Usage: ./bootstrap.sh --test-debug <role>"
                    exit 1
                fi
                ;;
            --test-idempotence)
                if [[ -n "${2:-}" ]] && [[ "${2:-}" != --* ]]; then
                    test_idempotence=true
                    test_role_name="$2"
                    shift 2
                else
                    log_error "--test-idempotence requires a role name"
                    log_info "Usage: ./bootstrap.sh --test-idempotence <role>"
                    exit 1
                fi
                ;;
            --test-parallel)
                test_parallel=true
                shift
                ;;
            --test-destroy)
                test_destroy=true
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

    # Handle test destroy first (can be combined with others)
    if [ "$test_destroy" = true ]; then
        cleanup_molecule
        # If no other test mode, just exit
        if [ "$test_local" = false ] && [ "$test_debug" = false ] && [ "$test_idempotence" = false ] && [ "$test_parallel" = false ] && [ "$run_tests" = false ] && [ -z "$test_role" ]; then
            exit 0
        fi
    fi

    # Handle various test modes
    if [ "$test_local" = true ]; then
        run_molecule_local "$test_role_name"
        exit 0
    fi

    if [ "$test_debug" = true ]; then
        run_molecule_debug "$test_role_name"
        exit 0
    fi

    if [ "$test_idempotence" = true ]; then
        run_molecule_idempotence "$test_role_name"
        exit 0
    fi

    if [ "$test_parallel" = true ]; then
        run_molecule_parallel
        exit 0
    fi

    if [ "$run_tests" = true ] || [ -n "$test_role" ]; then
        log_info "Running in test mode..."
        run_molecule_tests "$test_role"
        exit 0
    fi

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
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
        ansible-playbook -i "$inventory_path" "$playbook_path" --limit local
    else
        log_info "Running on remote hosts..."
        log_warn "Ensure you have configured ansible/inventory.ini with your remote hosts"
        ansible-playbook -i "$inventory_path" "$playbook_path" --limit remote --ask-pass --ask-become-pass
    fi

    log_info "Bootstrap complete!"
}

main "$@"
