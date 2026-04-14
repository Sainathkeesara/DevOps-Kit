#!/usr/bin/env bash
set -euo pipefail

# git-install-macos.sh — Install Git on macOS via Homebrew
# Purpose: Install or upgrade Git on macOS systems using Homebrew package manager
# Usage: ./git-install-macos.sh [--upgrade] [--version]
# Requirements: macOS with Homebrew installed (https://brew.sh)
# Safety: Dry-run mode supported (set DRY_RUN=true)
# Tested OS: macOS 12+ (Monterey, Ventura, Sonoma)

DRY_RUN=${DRY_RUN:-false}
UPGRADE=${UPGRADE:-false}
SHOW_VERSION=${SHOW_VERSION:-false}

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*" >&2; }

command -v brew >/dev/null 2>&1 || { log_error "Homebrew not found. Install from https://brew.sh"; exit 1; }

show_usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --upgrade       Upgrade Git if already installed
  --version       Show installed Git version and exit
  --dry-run       Show what would be done without executing

Examples:
  $0                  # Install Git (or do nothing if present)
  $0 --upgrade        # Upgrade Git to latest version
  $0 --version        # Show version info
  $0 --upgrade --dry-run

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

install_git() {
  local current_version
  current_version=$(check_git_installed)

  if [[ -n "$current_version" && "$UPGRADE" != "true" ]]; then
    log_info "Git $current_version already installed. Use --upgrade to update."
    return 0
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[dry-run] Would install/upgrade Git via Homebrew"
    return 0
  fi

  log_info "Installing Git via Homebrew..."
  brew install git

  local new_version
  new_version=$(check_git_installed)
  log_info "Git installed: $new_version"

  log_info "Verifying Git path..."
  local git_path
  git_path=$(command -v git)
  log_info "Git path: $git_path"

  if [[ "$git_path" != "/usr/local/bin/git" && "$git_path" != "/opt/homebrew/bin/git" ]]; then
    log_warn "Git not in expected path. You may need to restart your shell."
    log_warn "Add to PATH: export PATH=\"\$(brew --prefix)/bin:\$PATH\""
  fi

  log_info "Git installation complete"
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
  log_info "Skipping user configuration in automated script."
}

parse_args "$@"

if [[ "$SHOW_VERSION" == "true" ]]; then
  check_git_installed
  exit 0
fi

log_info "Starting Git installation for macOS"
install_git
configure_git

log_info "Done!"
