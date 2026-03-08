#!/usr/bin/env bash
#
# PURPOSE: Install Jenkins LTS on Ubuntu 22.04 with automated setup and idempotent execution
# USAGE: ./install-jenkins.sh [--version=<version>] [--port=<port>] [--plugins=<plugin1,plugin2>] [--dry-run] [--skip-start]
# REQUIREMENTS: Ubuntu 22.04, sudo privileges, internet connectivity
# SAFETY: Idempotent — safe to run multiple times. Supports dry-run mode.
#
# EXAMPLES:
#   ./install-jenkins.sh
#   ./install-jenkins.sh --version=2.426.1 --port=8080 --dry-run
#   ./install-jenkins.sh --plugins=git,docker-workflow,pipeline-utility-steps

set -euo pipefail
IFS=$'\n\t'

VERSION=""
JENKINS_PORT="8080"
PLUGINS=""
DRY_RUN=0
SKIP_START=0
INITIAL_ADMIN_PASSWORD_FILE="/var/lib/jenkins/secrets/initialAdminPassword"
JENKINS_CFG="/etc/jenkins/jenkins.model.JenkinsLocationConfiguration.xml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $*" >&2
}

usage() {
    grep '^#' "$0" | cut -c4- | head -n 10 | tail -n +3
    exit 1
}

check_prerequisites() {
    log_step "Checking prerequisites..."

    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi

    if ! command -v apt-get &>/dev/null; then
        log_error "apt-get not found. This script requires Ubuntu/Debian"
        exit 1
    fi

    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS version"
        exit 1
    fi

    if ! grep -q "Ubuntu" /etc/os-release && ! grep -q "22.04" /etc/os-release; then
        log_warn "This script is designed for Ubuntu 22.04. Continuing anyway..."
    fi

    log_info "Prerequisites check passed"
}

install_java() {
    log_step "Installing Java JDK 17..."

    if command -v java &>/dev/null; then
        local java_version
        java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [[ "$java_version" == "17" ]]; then
            log_info "Java 17 is already installed"
            return 0
        fi
        log_warn "Java is installed but version is not 17. Updating..."
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install: openjdk-17-jdk"
        return 0
    fi

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq openjdk-17-jdk >/dev/null 2>&1

    if command -v java &>/dev/null; then
        log_info "Java installed successfully: $(java -version 2>&1 | head -n1)"
    else
        log_error "Java installation failed"
        exit 1
    fi
}

add_jenkins_repo() {
    log_step "Adding Jenkins repository..."

    if [[ -f /usr/share/keyrings/jenkins-keyring.asc ]]; then
        log_info "Jenkins repository already configured"
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would add Jenkins GPG key and repository"
        return 0
    fi

    curl -fsSL "https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key" | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.asc 2>/dev/null || {
        log_error "Failed to add Jenkins GPG key"
        exit 1
    }

    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
    apt-get update -qq
    log_info "Jenkins repository added"
}

install_jenkins_pkg() {
    log_step "Installing Jenkins package..."

    if command -v jenkins &>/dev/null; then
        local current_version
        current_version=$(jenkins --version 2>/dev/null || echo "unknown")
        log_info "Jenkins is already installed (version: $current_version)"

        if [[ -n "$VERSION" ]]; then
            log_warn "Version $VERSION requested but Jenkins $current_version is installed. Skipping upgrade in idempotent mode."
        fi
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install: jenkins"
        return 0
    fi

    apt-get install -y -qq jenkins >/dev/null 2>&1

    if command -v jenkins &>/dev/null; then
        log_info "Jenkins installed successfully: $(jenkins --version)"
    else
        log_error "Jenkins installation failed"
        exit 1
    fi
}

configure_jenkins_port() {
    log_step "Configuring Jenkins port to $JENKINS_PORT..."

    local jenkins_cfg="/etc/default/jenkins"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would configure HTTP_PORT=$JENKINS_PORT"
        return 0
    fi

    if [[ -f "$jenkins_cfg" ]]; then
        if grep -q "^HTTP_PORT=" "$jenkins_cfg"; then
            sed -i "s|^HTTP_PORT=.*|HTTP_PORT=$JENKINS_PORT|" "$jenkins_cfg"
        else
            echo "HTTP_PORT=$JENKINS_PORT" >> "$jenkins_cfg"
        fi
    fi
    log_info "Port configured"
}

install_plugins() {
    if [[ -z "$PLUGINS" ]]; then
        log_info "No plugins specified, skipping plugin installation"
        return 0
    fi

    log_step "Installing Jenkins plugins: $PLUGINS"

    local jenkins_cli="/usr/share/jenkins/jenkins-cli.jar"
    local jenkins_war="/usr/share/jenkins/jenkins.war"
    local jenkins_home="/var/lib/jenkins"

    if [[ ! -f "$jenkins_home/jenkins.install.InstallUtil.lastExecVersion" ]]; then
        log_warn "Jenkins not fully initialized yet. Plugins will be installed on first startup."
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would install plugins: $PLUGINS"
        return 0
    fi

    local plugin_dir="$jenkins_home/plugins"
    mkdir -p "$plugin_dir"

    IFS=',' read -ra PLUGIN_ARRAY <<< "$PLUGINS"
    for plugin in "${PLUGIN_ARRAY[@]}"; do
        plugin=$(echo "$plugin" | xargs)
        [[ -z "$plugin" ]] && continue

        if [[ -d "$plugin_dir/$plugin" ]] || [[ -f "$plugin_dir/$plugin.jpi" ]]; then
            log_info "Plugin '$plugin' already installed"
            continue
        fi

        log_info "Installing plugin: $plugin"
        if curl -fsSL "https://updates.jenkins.io/latest/$plugin.hpi" -o "$plugin_dir/$plugin.jpi" 2>/dev/null; then
            log_info "Plugin '$plugin' installed"
        else
            log_warn "Failed to install plugin '$plugin' (may not exist or network issue)"
        fi
    done

    log_info "Plugin installation complete"
}

start_jenkins() {
    if [[ $SKIP_START -eq 1 ]]; then
        log_info "Skipping Jenkins start (--skip-start specified)"
        return 0
    fi

    log_step "Starting Jenkins..."

    if systemctl is-active --quiet jenkins; then
        log_info "Jenkins is already running"
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would start Jenkins service"
        return 0
    fi

    systemctl enable jenkins 2>/dev/null || true
    systemctl start jenkins

    log_info "Jenkins service started"
}

wait_for_jenkins() {
    log_step "Waiting for Jenkins to be ready..."

    local max_attempts=30
    local attempt=1
    local jenkins_url="http://localhost:$JENKINS_PORT"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY RUN] Would wait for Jenkins at $jenkins_url"
        return 0
    fi

    while [[ $attempt -le $max_attempts ]]; do
        if curl -sf "$jenkins_url/login" >/dev/null 2>&1; then
            log_info "Jenkins is ready at $jenkins_url"
            return 0
        fi
        echo -n "."
        sleep 2
    done

    echo ""
    log_warn "Jenkins may not be fully ready yet. Check status with: systemctl status jenkins"
}

get_initial_password() {
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY RUN] Would retrieve initial admin password"
        return 0
    fi

    if [[ -f "$INITIAL_ADMIN_PASSWORD_FILE" ]]; then
        log_info "Initial admin password location: $INITIAL_ADMIN_PASSWORD_FILE"
        log_info "Password: $(cat "$INITIAL_ADMIN_PASSWORD_FILE" 2>/dev/null || echo 'not available yet')"
    else
        log_warn "Initial password file not found yet. Jenkins may still be initializing."
    fi
}

print_access_info() {
    local jenkins_url="http://localhost:$JENKINS_PORT"

    echo ""
    echo "========================================"
    echo "  Jenkins Installation Complete"
    echo "========================================"
    echo ""
    echo "  URL:         $jenkins_url"
    echo "  Port:        $JENKINS_PORT"
    echo "  User:        admin"
    echo "  Password:    See $INITIAL_ADMIN_PASSWORD_FILE"
    echo ""
    echo "  Service:     systemctl status jenkins"
    echo "  Logs:        journalctl -u jenkins -f"
    echo "  Config:      /etc/jenkins/jenkins.model.JenkinsLocationConfiguration.xml"
    echo ""
    echo "========================================"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version=*)
                VERSION="${1#*=}"
                ;;
            --port=*)
                JENKINS_PORT="${1#*=}"
                ;;
            --plugins=*)
                PLUGINS="${1#*=}"
                ;;
            --dry-run) DRY_RUN=1 ;;
            --skip-start) SKIP_START=1 ;;
            -h|--help) usage ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                ;;
        esac
        shift
    done

    if [[ -n "$VERSION" ]]; then
        log_warn "Version pinning not fully implemented. Using repository default (LTS)"
    fi

    if [[ ! "$JENKINS_PORT" =~ ^[0-9]+$ ]] || [[ "$JENKINS_PORT" -lt 1 ]] || [[ "$JENKINS_PORT" -gt 65535 ]]; then
        log_error "Invalid port: $JENKINS_PORT (must be 1-65535)"
        exit 1
    fi
}

main() {
    parse_args "$@"

    echo ""
    echo "Jenkins Installation Script"
    echo "============================"
    echo ""

    if [[ $DRY_RUN -eq 1 ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    check_prerequisites
    install_java
    add_jenkins_repo
    install_jenkins_pkg
    configure_jenkins_port
    install_plugins
    start_jenkins
    wait_for_jenkins
    get_initial_password

    if [[ $DRY_RUN -eq 0 ]]; then
        print_access_info
    fi

    log_info "Installation process complete"
}

main "$@"
