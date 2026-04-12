#!/usr/bin/env bash
set -euo pipefail

# git-install.sh — automated Git installation for Linux (idempotent)
# Purpose: Install or upgrade Git to the latest stable version on Linux
# Usage: ./git-install.sh [--version X.XX.XX] [--from-source]
# Requirements: curl, wget, build tools (for source build)
# Safety: Dry-run mode supported. Does not break existing Git installations.
# Tested OS: Ubuntu 22.04 LTS, Ubuntu 24.04 LTS, AlmaLinux 9.4, Fedora 40

DRY_RUN=${DRY_RUN:-false}
CUSTOM_VERSION=""
BUILD_FROM_SOURCE=false
GIT_PREFIX="/usr/local"

log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"; }
log_warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $*"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }

command -v curl >/dev/null 2>&1 || { log_error "curl not found"; exit 1; }
command -v wget >/dev/null 2>&1 || { log_error "wget not found"; exit 1; }

if [ "$DRY_RUN" = true ]; then
  log_info "DRY RUN MODE — no changes will be made"
fi

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --version X.XX.XX    Install specific Git version (default: latest stable)
  --from-source      Build Git from source instead of using packages
  --dry-run         Show what would be done without executing
  -h, --help       Show this help message

Examples:
  # Install latest stable Git
  $0

  # Install specific version
  $0 --version 2.45.0

  # Build from source
  $0 --from-source
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) CUSTOM_VERSION="$2"; shift 2 ;;
    --from-source) BUILD_FROM_SOURCE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) log_error "Unknown option: $1"; usage; exit 1 ;;
  esac
done

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian) OS="debian"; ;;
      almalinux|rhel|centos) OS="rhel"; ;;
      fedora) OS="fedora"; ;;
      *) OS="unknown"; ;;
    esac
  else
    OS="unknown"
  fi
  log_info "Detected OS: $OS"
}

get_current_git_version() {
  if command -v git >/dev/null 2>&1; then
    git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
  else
    echo "none"
  fi
}

get_latest_version() {
  local latest
  latest=$(curl -sL https://github.com/git/git/tags 2>/dev/null | grep -oE 'git-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz' | head -1 | sed 's/git-//; s/\.tar\.gz//')
  echo "$latest"
}

install_debian() {
  log_info "Installing Git on Debian/Ubuntu"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would add Git PPA and install"
    return 0
  fi

  if [ -n "$CUSTOM_VERSION" ]; then
    log_info "Installing Git $CUSTOM_VERSION from source"
    install_from_source "$CUSTOM_VERSION"
  else
    log_info "Adding Git PPA (ppa:git-core/ppa)"
    add-apt-repository -y ppa:git-core/ppa 2>/dev/null || log_warn "Failed to add PPA"
    apt-get update -qq
    apt-get install -y -qq git
  fi
}

install_rhel() {
  log_info "Installing Git on RHEL/AlmaLinux"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would install Git from IUS or source"
    return 0
  fi

  if [ -n "$CUSTOM_VERSION" ] || [ "$BUILD_FROM_SOURCE" = true ]; then
    install_from_source "$CUSTOM_VERSION"
  else
    dnf install -y -q git 2>/dev/null || yum install -y -q git 2>/dev/null || log_warn "Package install failed"
  fi
}

install_fedora() {
  log_info "Installing Git on Fedora"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would install Git"
    return 0
  fi

  if [ -n "$CUSTOM_VERSION" ] || [ "$BUILD_FROM_SOURCE" = true ]; then
    install_from_source "$CUSTOM_VERSION"
  else
    dnf install -y -q git 2>/dev/null || log_warn "Package install failed"
  fi
}

install_from_source() {
  local version="${1:-$(get_latest_version)}"
  log_info "Building Git $version from source"

  if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would download and build Git $version"
    return 0
  fi

  local tmpdir="/tmp/git-build-$version"
  mkdir -p "$tmpdir"
  cd "$tmpdir"

  log_info "Downloading Git $version"
  curl -sL "https://github.com/git/git/archive/refs/tags/v$version.tar.gz" | tar xz

  cd "git-$version"

  log_info "Installing build dependencies"
  case "$OS" in
    debian) apt-get install -y -qq make gcc libcurl4-gnutls-dev libexpat1-dev zlib1g-dev libssl-dev gettext ;;
    rhel) dnf install -y -q make gcc gcc-c++ libcurl-devel expat-devel openssl-devel gettext-devel || yum install -y make gcc gcc-c++ libcurl-devel expat-devel openssl-devel gettext-devel ;;
    fedora) dnf install -y -q make gcc libcurl-devel expat-devel openssl-devel gettext-devel ;;
  esac

  log_info "Configuring Git"
  ./configure --prefix="$GIT_PREFIX" --with-tcl --without-gitweb 2>/dev/null || ./configure --prefix="$GIT_PREFIX" --with-tcl

  log_info "Compiling Git (this may take a few minutes)"
  make -j"$(nproc)" all

  log_info "Installing Git"
  make install

  export PATH="$GIT_PREFIX/bin:$PATH"

  cd /
  rm -rf "$tmpdir"

  log_info "Git $version installed to $GIT_PREFIX/bin"
}

verify_installation() {
  local git_path="$GIT_PREFIX/bin/git"
  if [ -x "$git_path" ]; then
    log_info "Git installed: $($git_path --version)"
  elif command -v git >/dev/null 2>&1; then
    log_info "Git installed: $(git --version)"
  else
    log_error "Git installation verification failed"
    return 1
  fi
}

main() {
  detect_os
  local current_version
  current_version=$(get_current_git_version)
  log_info "Current Git version: $current_version"

  local target_version="${CUSTOM_VERSION:-$(get_latest_version)}"
  log_info "Target Git version: $target_version"

  if [ "$current_version" = "$target_version" ]; then
    log_info "Git is already at version $target_version — nothing to do"
    exit 0
  fi

  case "$OS" in
    debian) install_debian ;;
    rhel) install_rhel ;;
    fedora) install_fedora ;;
    *) log_error "Unsupported OS: $OS"; exit 1 ;;
  esac

  verify_installation
  log_info "Git installation complete"
}

main "$@"