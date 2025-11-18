#!/bin/bash

################################################################################
# Common Functions and Variables for Cloud Run Scripts
################################################################################

# Exit immediately if a command exits with a non-zero status.
set -Eeuo pipefail

# Trap to catch errors and print the command that failed
trap 'echo -e "[\033[0;31mERROR\033[0m] Command failed: $BASH_COMMAND (exit $?)" >&2' ERR

# --- Colors for output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Logging functions ---
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

# --- Generic Banner ---
print_banner() {
    local title="$1"
    local subtitle="$2"
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    printf "║ %-62s ║\n" " $title"
    if [ -n "$subtitle" ]; then
        printf "║ %-62s ║\n" " $subtitle"
    fi
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# --- Prerequisite Checks ---
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local all_ok=true
    
    # Check gcloud
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud SDK is not installed. Please run the setup script."
        all_ok=false
    else
        log_success "✓ gcloud SDK is installed"
    fi
    
    # Check Docker (optional, can be checked in scripts that need it)
    if [[ "${CHECK_DOCKER:-false}" == "true" ]]; then
        if ! command -v docker &> /dev/null; then
            log_error "Docker is not installed. Please run the setup script."
            all_ok=false
        else
            log_success "✓ Docker is installed"
        fi
    fi

    # Check authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q .; then
        log_error "Not authenticated with GCP. Please run 'gcloud auth login'."
        all_ok=false
    else
        log_success "✓ Authenticated with GCP"
    fi

    if [ "$all_ok" = false ]; then
        log_error "Prerequisite check failed. Please fix the issues above."
        exit 1
    fi
    echo ""
}

# --- Helper for user confirmation ---
confirm() {
    local prompt="${1:-Are you sure?}"
    local default_choice="${2:-n}"
    local choice
    
    if [[ "$default_choice" =~ ^[Yy]$ ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" choice
    choice=${choice:-$default_choice}
    
    [[ "$choice" =~ ^[Yy]$ ]]
}
