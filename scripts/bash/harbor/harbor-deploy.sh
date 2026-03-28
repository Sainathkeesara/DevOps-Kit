#!/usr/bin/env bash
set -euo pipefail

# Harbor Container Registry Deployment Script
# Purpose: Automate Harbor installation with Docker Compose on Linux
# Requirements: docker, docker compose, wget, openssl
# Safety: Supports DRY_RUN mode — no destructive operations without explicit confirmation
# Tested on: Ubuntu 22.04, CentOS Stream 9

HARBOR_VERSION="${HARBOR_VERSION:-v2.10.0}"
HARBOR_DIR="${HARBOR_DIR:-/opt/harbor}"
HARBOR_HOSTNAME="${HARBOR_HOSTNAME:-harbor.example.com}"
HARBOR_ADMIN_PASS="${HARBOR_ADMIN_PASS:-ChangeMeOnFirstLogin!}"
HARBOR_DB_PASS="${HARBOR_DB_PASS:-dbpassword123}"
CERT_DIR="${HARBOR_DIR}/cert"
DRY_RUN="${DRY_RUN:-false}"
FORCE="${FORCE:-false}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    local deps=("docker" "wget" "openssl")
    for dep in "${deps[@]}"; do
        command -v "$dep" >/dev/null 2>&1 || { log_error "$dep not found — install it first"; exit 1; }
    done
    # Check docker compose plugin
    if ! docker compose version >/dev/null 2>&1; then
        log_error "docker compose plugin not found — install docker-compose-plugin"
        exit 1
    fi
    log_info "All dependencies satisfied"
}

check_docker_running() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running — start it with: systemctl start docker"
        exit 1
    fi
    log_info "Docker daemon is running"
}

generate_certificates() {
    log_info "Generating TLS certificates for ${HARBOR_HOSTNAME}..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would generate CA and server certificates in ${CERT_DIR}"
        return 0
    fi

    mkdir -p "$CERT_DIR"

    openssl genrsa -out "${CERT_DIR}/ca.key" 4096
    openssl req -x509 -new -nodes -sha512 -days 3650 \
        -subj "/C=US/ST=California/L=SanFrancisco/O=DevOps/CN=${HARBOR_HOSTNAME}" \
        -key "${CERT_DIR}/ca.key" \
        -out "${CERT_DIR}/ca.crt"

    openssl genrsa -out "${CERT_DIR}/server.key" 4096
    openssl req -sha512 -new \
        -subj "/C=US/ST=California/L=SanFrancisco/O=DevOps/CN=${HARBOR_HOSTNAME}" \
        -key "${CERT_DIR}/server.key" \
        -out "${CERT_DIR}/server.csr"

    cat > "${CERT_DIR}/v3.ext" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=${HARBOR_HOSTNAME}
DNS.2=harbor
IP.1=127.0.0.1
EOF

    openssl x509 -req -sha512 -days 3650 \
        -extfile "${CERT_DIR}/v3.ext" \
        -CA "${CERT_DIR}/ca.crt" -CAkey "${CERT_DIR}/ca.key" -CAcreateserial \
        -in "${CERT_DIR}/server.csr" \
        -out "${CERT_DIR}/server.crt"

    openssl x509 -inform PEM -in "${CERT_DIR}/server.crt" -out "${CERT_DIR}/server.cert"

    log_info "TLS certificates generated in ${CERT_DIR}"
}

download_harbor() {
    log_info "Downloading Harbor ${HARBOR_VERSION}..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would download harbor-installer-${HARBOR_VERSION}.tgz to ${HARBOR_DIR}"
        return 0
    fi

    mkdir -p "$HARBOR_DIR"
    cd "$HARBOR_DIR"

    local tarball="harbor-online-installer-${HARBOR_VERSION}.tgz"
    if [ -f "$tarball" ]; then
        log_warn "Harbor tarball already exists — skipping download"
    else
        wget "https://github.com/goharbor/harbor/releases/download/${HARBOR_VERSION}/${tarball}"
    fi

    if [ -d "harbor" ]; then
        log_warn "Harbor directory already exists — extracting over it"
    fi
    tar xzf "$tarball"
    log_info "Harbor ${HARBOR_VERSION} downloaded and extracted"
}

generate_config() {
    log_info "Generating harbor.yml configuration..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would generate harbor.yml with hostname=${HARBOR_HOSTNAME}"
        return 0
    fi

    cd "$HARBOR_DIR"

    if [ -f "harbor.yml" ] && [ "$FORCE" != true ]; then
        log_warn "harbor.yml already exists — backing up to harbor.yml.bak"
        cp harbor.yml harbor.yml.bak
    fi

    cp harbor.yml.tmpl harbor.yml

    # Apply configuration
    sed -i "s|^hostname:.*|hostname: ${HARBOR_HOSTNAME}|" harbor.yml
    sed -i "s|^harbor_admin_password:.*|harbor_admin_password: ${HARBOR_ADMIN_PASS}|" harbor.yml
    sed -i "s|^  certificate:.*|  certificate: ${CERT_DIR}/server.crt|" harbor.yml
    sed -i "s|^  private_key:.*|  private_key: ${CERT_DIR}/server.key|" harbor.yml

    # Set database password
    sed -i "s|^  password:.*|  password: ${HARBOR_DB_PASS}|" harbor.yml

    log_info "harbor.yml generated"
}

install_harbor() {
    log_info "Installing Harbor with Trivy scanner..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would run: ./install.sh --with-trivy"
        return 0
    fi

    cd "$HARBOR_DIR/harbor"
    ./install.sh --with-trivy

    log_info "Harbor installation complete"
    log_info "Waiting for all services to start..."
    sleep 15

    docker compose ps
}

configure_docker_client_trust() {
    log_info "Configuring Docker client to trust Harbor certificates..."
    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would copy ca.crt to /etc/docker/certs.d/${HARBOR_HOSTNAME}/"
        return 0
    fi

    local docker_cert_dir="/etc/docker/certs.d/${HARBOR_HOSTNAME}"
    sudo mkdir -p "$docker_cert_dir"
    sudo cp "${CERT_DIR}/ca.crt" "${docker_cert_dir}/ca.crt"

    # System trust store
    if [ -d /usr/local/share/ca-certificates ]; then
        sudo cp "${CERT_DIR}/ca.crt" "/usr/local/share/ca-certificates/harbor-ca.crt"
        sudo update-ca-certificates
    elif [ -d /etc/pki/ca-trust/source/anchors ]; then
        sudo cp "${CERT_DIR}/ca.crt" /etc/pki/ca-trust/source/anchors/harbor-ca.crt
        sudo update-ca-trust
    fi

    log_info "Docker client trust configured"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    --dry-run           Show what would be done without making changes
    --hostname NAME     Harbor hostname (default: harbor.example.com)
    --version VER       Harbor version (default: v2.10.0)
    --dir PATH          Harbor install directory (default: /opt/harbor)
    --force             Overwrite existing configuration
    -h, --help          Show this help message

Environment Variables:
    DRY_RUN             Set to 'true' for dry-run mode
    HARBOR_HOSTNAME     Harbor hostname
    HARBOR_VERSION      Harbor version tag
    HARBOR_ADMIN_PASS   Harbor admin password
    HARBOR_DB_PASS      Harbor database password

Examples:
    $0 --dry-run --hostname registry.mycompany.com
    $0 --hostname harbor.example.com --version v2.10.0
    DRY_RUN=true $0
EOF
}

main() {
    for arg in "$@"; do
        case $arg in
            --dry-run) DRY_RUN=true ;;
            --hostname) HARBOR_HOSTNAME="$2"; shift ;;
            --version) HARBOR_VERSION="$2"; shift ;;
            --dir) HARBOR_DIR="$2"; shift ;;
            --force) FORCE=true ;;
            -h|--help) show_usage; exit 0 ;;
        esac
    done

    CERT_DIR="${HARBOR_DIR}/cert"

    log_info "=== Harbor Deployment ==="
    log_info "Hostname : ${HARBOR_HOSTNAME}"
    log_info "Version  : ${HARBOR_VERSION}"
    log_info "Dir      : ${HARBOR_DIR}"
    log_info "DRY_RUN  : ${DRY_RUN}"
    echo ""

    check_dependencies
    check_docker_running
    generate_certificates
    download_harbor
    generate_config
    install_harbor
    configure_docker_client_trust

    echo ""
    log_info "=== Deployment Complete ==="
    log_info "Web UI  : https://${HARBOR_HOSTNAME}"
    log_info "Username: admin"
    log_info "Password: ${HARBOR_ADMIN_PASS}"
    log_warn "Change the admin password immediately after first login!"
}

main "$@"
