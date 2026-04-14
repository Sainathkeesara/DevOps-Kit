#!/usr/bin/env bash
set -euo pipefail

# git-install-wsl.sh — Install Git on Windows Subsystem for Linux (WSL)
# Purpose: Install and configure Git on WSL (Ubuntu, Debian, Kali, etc.)
# Usage: ./git-install-wsl.sh [--upgrade] [--version]
# Requirements: WSL with Ubuntu 20.04+, Debian 11+, or Kali Linux
# Safety: Dry-run mode supported (set DRY_RUN=true)
# Tested OS: WSL2 Ubuntu 22.04, WSL2 Debian 12

DRY_RUN=${DRY_RUN:-false}
UPGRADE=${UPGRADE:-false}
SHOW_VERSION=${SHOW_VERSION:-false}

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

command -v apt-get >/dev/null 2>&1 || { log_error "apt-get not found. This script is for Debian-based WSL."; exit 1; }

show_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --upgrade       Upgrade Git if already installed
  --version       Show installed Git version and exit
  --dry-run       Show what would be done without executing

Examples:
  $0                  # Install Git
  $0 --upgrade        # Upgrade Git to latest version
  $0 --version        # Show version info

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
        ;;
      --upgrade)
        UPGRADE=true
        shift
        ;;
      --version)
        SHOW_VERSION=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      *)
        log_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
}

check_git_installed() {
  if command -v git >/dev/null 2>&1; then
    local git_version
    git_version=$(git --version 2>/dev/null | grep -oP 'git version \K[0-9.]+')
    log_info "Git found: version $git_version"
    echo "$git_version"
  else
    log_info "Git not installed"
    echo ""
  fi
}

add_git_ppa() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would add Git PPA for latest version"
    return 0
  fi

  if [[ -f /etc/apt/sources.list.d/git-core-ppa.list ]]; then
    log_info "Git PPA already configured"
    return 0
  fi

  log_info "Adding Git PPA for latest versions..."
  apt-get update -qq
  apt-get install -y -qq software-properties-common
  add-apt-repository -y ppa:git-core/ppa 2>/dev/null || {
    log_warn "PPA not available, using system packages"
  }
}

install_git() {
  local current_version
  current_version=$(check_git_installed)

  if [[ -n "$current_version" && "$UPGRADE" != "true" ]]; then
    log_info "Git $current_version already installed. Use --upgrade to update."
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would install/upgrade Git"
    return 0
  fi

  log_info "Updating package lists..."
  apt-get update -qq

  log_info "Installing Git..."
  apt-get install -y -qq git

  local new_version
  new_version=$(check_git_installed)
  log_info "Git installed: $new_version"
}

configure_git() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would configure Git user.name and user.email"
    return 0
  fi

  log_info "Git configuration is user-specific."
  log_info "Configure your identity:"
  echo ""
  echo "  git config --global user.name 'Your Name'"
  echo "  git config --global user.email 'you@example.com'"
  echo ""
  log_info "Recommended: Enable credential caching for WSL:"
  echo "  git config --global credential.helper cache"
  echo ""
  log_info "Skipping user configuration in automated script."
}

parse_args "$@"

if [[ "$SHOW_VERSION" == "true" ]]; then
  check_git_installed
  exit 0
fi

log_info "Starting Git installation for WSL"
install_git
configure_git

log_info "Done!"
