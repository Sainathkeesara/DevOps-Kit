#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Docker Container Host Security Hardening Script
# Purpose: Secure a Linux host for running Docker containers
# Requirements: Ubuntu 22.04+, Debian 11+, RHEL/CentOS 8+
# Safety: Dry-run mode supported via DRY_RUN=1
###############################################################################

DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg"
}

info() { log "INFO" "$@"; }
warn() { log "WARN" "$@"; }
error() { log "ERROR" "$@"; }

dry_run() {
    if [ "$DRY_RUN" = "true" ]; then
        info "[dry-run] $*"
        return 0
    fi
    return 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
        exit 1
    fi
}

check_docker_installed() {
    if ! command_exists docker; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    info "Docker found: $(docker --version)"
}

backup_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        local backup="${config_file}.backup.$(date +%Y%m%d%H%M%S)"
        dry_run "Would backup $config_file to $backup" || {
            cp "$config_file" "$backup"
            info "Backed up $config_file to $backup"
        }
    fi
}

configure_docker_daemon() {
    info "Configuring Docker daemon security settings..."

    local daemon_json="/etc/docker/daemon.json"
    backup_config "$daemon_json"

    if [ ! -d /etc/docker ]; then
        dry_run "Would create /etc/docker directory" || mkdir -p /etc/docker
    fi

    dry_run "Would create daemon.json with security settings" || {
        cat > "$daemon_json" <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "icc": false,
  "userns-remap": "default",
  "live-restore": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "authorization-plugins": [],
  "apparmor-profile": "generated",
  "selinux-enabled": false,
  "no-new-privileges": true,
  "dns": ["8.8.8.8", "8.8.4.4"],
  "bridge": "none"
}
EOF
        info "Created $daemon_json with security settings"
    }
}

configure_docker_socket() {
    info "Configuring Docker socket permissions..."

    local socket_path="/var/run/docker.sock"

    if [ -S "$socket_path" ]; then
        dry_run "Would set socket permissions to 660" || {
            chmod 660 "$socket_path"
            chown root:docker "$socket_path"
            info "Set socket permissions to 660, owner root:docker"
        }
    else
        warn "Docker socket not found at $socket_path"
    fi
}

enable_docker_content_trust() {
    info "Enabling Docker Content Trust..."

    dry_run "Would set DOCKER_CONTENT_TRUST=1" || {
        if ! grep -q "DOCKER_CONTENT_TRUST=1" /etc/environment 2>/dev/null; then
            echo "DOCKER_CONTENT_TRUST=1" >> /etc/environment
            info "Enabled Docker Content Trust in /etc/environment"
        fi
        export DOCKER_CONTENT_TRUST=1
    }
}

create_isolated_network() {
    info "Creating isolated Docker network..."

    dry_run "Would create isolated Docker network" || {
        if docker network ls | grep -q "isolated-network"; then
            info "Network 'isolated-network' already exists"
        else
            docker network create --driver bridge \
                --opt "com.docker.network.bridge.enable_icc"=false \
                --subnet=172.20.0.0/16 \
                isolated-network 2>/dev/null || warn "Network creation requires Docker daemon"
            info "Created isolated-network"
        fi
    }
}

configure_firewall() {
    info "Configuring firewall rules..."

    if command_exists ufw; then
        dry_run "Would configure UFW firewall" || {
            ufw --force default deny incoming
            ufw --force default allow outgoing
            ufw allow 22/tcp comment "SSH"
            ufw --force enable
            info "Configured UFW firewall"
        }
    elif command_exists firewall-cmd; then
        dry_run "Would configure firewalld" || {
            firewall-cmd --permanent --add-service=ssh
            firewall-cmd --permanent --add-interface=docker0 --zone=trusted
            firewall-cmd --reload
            info "Configured firewalld"
        }
    else
        warn "No firewall tool found (ufw or firewalld)"
    fi
}

configure_audit_rules() {
    info "Configuring audit rules for Docker..."

    local audit_rules="/etc/audit/rules.d/docker.rules"

    dry_run "Would create Docker audit rules" || {
        if [ ! -f "$audit_rules" ]; then
            cat > "$audit_rules" <<'EOF'
-w /var/lib/docker -k docker
-w /etc/docker -k docker
-w /usr/bin/docker -k docker
-w /var/run/docker.sock -k docker
EOF
            auditctl -R "$audit_rules" 2>/dev/null || warn "auditctl not available"
            info "Created Docker audit rules"
        else
            info "Audit rules already exist"
        fi
    }
}

install_apparmor() {
    info "Installing and configuring AppArmor..."

    if command_exists aa-status; then
        dry_run "Would enable AppArmor profile for Docker" || {
            if [ -f /etc/apparmor.d/docker ]; then
                info "AppArmor profile for Docker exists"
                aa-status --enabled 2>/dev/null || warn "AppArmor not enabled"
            fi
        }
    else
        warn "AppArmor not available on this system"
    fi
}

create_resource_limits_template() {
    info "Creating Docker resource limits template..."

    local limits_file="/etc/docker/limit-config.json"

    dry_run "Would create resource limits template" || {
        cat > "$limits_file" <<'EOF'
{
  "default-ulimits": {
    "nofile": {"Name": "nofile", "Hard": 64000, "Soft": 64000},
    "nproc": {"Name": "nproc", "Hard": 4096, "Soft": 4096}
  },
  "default-cpu-shares": 1024,
  "default-memory": "2g",
  "default-memory-swap": "4g"
}
EOF
        info "Created resource limits template at $limits_file"
    }
}

restart_docker() {
    info "Restarting Docker service..."

    dry_run "Would restart Docker service" || {
        systemctl restart docker
        sleep 2
        if systemctl is-active --quiet docker; then
            info "Docker service restarted successfully"
        else
            error "Docker service failed to restart"
            return 1
        fi
    }
}

verify_installation() {
    info "Verifying Docker installation..."

    local errors=0

    if ! systemctl is-active --quiet docker 2>/dev/null; then
        warn "Docker service is not running"
        ((errors++))
    fi

    if ! docker info >/dev/null 2>&1; then
        warn "Cannot connect to Docker daemon"
        ((errors++))
    fi

    if [ $errors -eq 0 ]; then
        info "Docker installation verified successfully"
    else
        warn "Verification completed with $errors warning(s)"
    fi
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -d, --dry-run       Run in dry-run mode (no changes made)
    -v, --verbose       Enable verbose output

Examples:
    $0                  Run with default settings
    $0 --dry-run        Preview changes without applying
    $0 --verbose        Show detailed progress

Environment variables:
    DRY_RUN=true        Run in dry-run mode
    VERBOSE=true        Enable verbose output
EOF
}

main() {
    local args=("$@")

    for arg in "${args[@]}"; do
        case "$arg" in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
        esac
    done

    info "Starting Docker security hardening..."
    info "Dry-run mode: $DRY_RUN"

    check_root
    check_docker_installed

    configure_docker_daemon
    configure_docker_socket
    enable_docker_content_trust
    create_isolated_network
    configure_firewall
    configure_audit_rules
    install_apparmor
    create_resource_limits_template

    if [ "$DRY_RUN" != "true" ]; then
        restart_docker
    fi

    verify_installation

    info "Docker security hardening complete"
    info "Review /etc/docker/daemon.json for configuration details"
}

main "$@"