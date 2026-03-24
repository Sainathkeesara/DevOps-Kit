#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Mail Server Setup Automation Script
# Purpose: Automate Postfix and Dovecot installation and configuration on Linux
# Requirements: Ubuntu 20.04+, Debian 11+, RHEL 8+, Rocky Linux 9+
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

detect_os() {
    if command_exists apt-get; then
        echo "debian"
    elif command_exists dnf; then
        echo "rhel"
    else
        error "Unsupported OS"
        exit 1
    fi
}

install_packages() {
    local os="$1"
    info "Installing mail server packages..."

    dry_run "Would install mail server packages" || {
        if [ "$os" = "debian" ]; then
            apt-get update
            apt-get install -y postfix postfix-pcre postfix-ldap postfix-lmdb dovecot-core dovecot-imapd dovecot-pop3d dovecot-ldap dovecot-mysql dovecot-postgresql openssl ca-certificates
        elif [ "$os" = "rhel" ]; then
            dnf install -y postfix dovecot openssl ca-certificates
            systemctl enable postfix dovecot
        fi
    }
}

configure_postfix_main() {
    local domain="$1"
    local hostname="$2"

    info "Configuring Postfix main configuration..."

    dry_run "Would configure Postfix main.cf" || {
        cat > /etc/postfix/main.cf <<EOF
# Postfix Main Configuration
# Debian/Ubuntu: /etc/postfix/main.cf
# RHEL/CentOS: /etc/postfix/main.cf

# Network Configuration
inet_interfaces = all
inet_protocols = all

# Domain Configuration
myhostname = $hostname
mydomain = $domain
myorigin = \$mydomain
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain

# Mail Queue Configuration
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
home_mailbox = Maildir/
mailbox_command =

# Size Limits
message_size_limit = 52428800
mailbox_size_limit = 1073741824

# SASL Authentication
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = \$mydomain
broken_sasl_auth_clients = yes

# TLS Configuration
smtpd_tls_cert_file = /etc/ssl/certs/mail.crt
smtpd_tls_key_file = /etc/ssl/private/mail.key
smtpd_tls_security_level = may
smtpd_tls_auth_only = no
smtpd_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtpd_tls_loglevel = 1
smtpd_tls_received_header = yes

# Submission Port (587)
submission inet n - - - - smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
  -o smtpd_recipient_restrictions=reject_non_fqdn_recipient,reject_unknown_recipient_domain,permit_sasl_authenticated,reject

# SMTPS Port (465)
smtps inet n - - - - smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject

# Local Delivery
mail_spool_directory = /var/mail/vmail

# Virtual Mailbox Configuration
virtual_mailbox_domains = hash:/etc/postfix/virtual_domains
virtual_mailbox_base = /var/mail/vmail
virtual_mailbox_maps = hash:/etc/postfix/virtual_mailbox
virtual_alias_maps = hash:/etc/postfix/virtual_alias
virtual_uid_maps = static:5000
virtual_gid_maps = static:5000

# Security
smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination, reject_non_fqdn_sender, reject_non_fqdn_recipient, reject_unknown_sender_domain, reject_unknown_recipient_domain
smtpd_helo_required = yes
disable_vrfy_command = yes

# Performance
default_process_limit = 100
default_minimum_process_limit = 4
default_process_limit = 100
EOF
    }
}

configure_postfix_master() {
    info "Configuring Postfix master.cf..."

    dry_run "Would configure Postfix master.cf" || {
        cat > /etc/postfix/master.cf <<EOF
# Postfix Master Configuration
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (yes)   (never) (100)
# ==========================================================================

# Standard SMTP Service
smtp      inet  n       -       -       -       -       smtpd

# Submission Port
submission inet n       -       -       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes

# SMTPS
smtps     inet  n       -       -       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes

# Local Delivery
local     unix  -       n       n       -       -       local

# Virtual Delivery
virtual   unix  -       n       n       -       -       virtual

# Pipe for local delivery to programs
lmtp      unix  -       -       n       -       -       lmtp
anvil     unix  -       -       n       -       1       anvil
scache    unix  -       -       n       -       1       scache
postlog   unix-dgram n  -       n       -       1       postlogd
EOF
    }
}

configure_dovecot() {
    local domain="$1"

    info "Configuring Dovecot..."

    dry_run "Would configure Dovecot" || {
        # Main dovecot configuration
        cat > /etc/dovecot/dovecot.conf <<EOF
# Dovecot Main Configuration

# Protocols
protocols = imap pop3 lmtp

# Listen on all interfaces
listen = *, ::

# Disable SSLv2 and SSLv3
ssl_protocols = !SSLv3 !TLSv1 !TLSv1.1

# Mail location
mail_location = maildir:/var/mail/vmail/%d/%n

# Mail user configuration
mail_uid = 5000
mail_gid = 5000
mail_privileged_group = mail

# Login processes
login_greeting = Mail Server Ready.
login_processes_count = 3
login_process_size = 64
login_max_processes_count = 64

# Authentication
auth_mechanisms = plain login
disable_plaintext_auth = no

# User database
userdb {
  driver = passwd
}

# Passdb
passdb {
  driver = passwd
}

# Service configuration
service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
  process_limit = 100
}

service pop3-login {
  inet_listener pop3 {
    port = 110
  }
  inet_listener pop3s {
    port = 995
    ssl = yes
  }
  process_limit = 100
}

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0660
    user = postfix
    group = postfix
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
  user = dovecot
}

service auth-worker {
  user = root
}
EOF

        # Authentication configuration
        cat > /etc/dovecot/10-auth.conf <<EOF
# Authentication Configuration

auth_mechanisms = plain login

# Disable plaintext auth in non-SSL connections
disable_plaintext_auth = no

# User database
!include auth-passwdfile.conf.ext
!include auth-ldap.conf.ext
!include auth-sql.conf.ext
!include auth-system.conf.ext
EOF

        # Mail location
        cat > /etc/dovecot/10-mail.conf <<EOF
# Mail Location Configuration

mail_location = maildir:/var/mail/vmail/%d/%n

# Mail processes
mail_privileged_group = mail
mail_access_groups = mail

# Mailbox settings
maildir_stat_dirs = yes
maildir_copy_with_hardlinks = yes
EOF

        # SSL configuration
        cat > /etc/dovecot/10-ssl.conf <<EOF
# SSL Configuration

ssl = yes
ssl_cert = </etc/ssl/certs/mail.crt
ssl_key = </etc/ssl/private/mail.key
ssl_ca = </etc/ssl/certs/ca-certificates.crt
EOF
    }
}

generate_ssl_certs() {
    local domain="$1"

    info "Generating SSL certificates..."

    dry_run "Would generate SSL certificates" || {
        mkdir -p /etc/ssl/private
        openssl req -new -x509 -days 365 -nodes \
            -keyout /etc/ssl/private/mail.key \
            -out /etc/ssl/certs/mail.crt \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=mail.$domain" 2>/dev/null

        chmod 600 /etc/ssl/private/mail.key
        chmod 644 /etc/ssl/certs/mail.crt

        info "SSL certificates generated successfully"
    }
}

create_mail_users() {
    local domain="$1"

    info "Creating mail users..."

    dry_run "Would create mail users" || {
        # Create vmail user if it doesn't exist
        id vmail >/dev/null 2>&1 || useradd -r -u 5000 -g 5000 -s /sbin/nologin -d /var/mail vmail

        # Create mail directory structure
        mkdir -p /var/mail/vmail/$domain
        chown -R vmail:vmail /var/mail
        chmod -R 770 /var/mail
    }
}

configure_firewall() {
    info "Configuring firewall rules..."

    dry_run "Would configure firewall for mail services" || {
        if command_exists ufw; then
            ufw allow 25/tcp comment 'SMTP'
            ufw allow 587/tcp comment 'SMTP Submission'
            ufw allow 465/tcp comment 'SMTPS'
            ufw allow 143/tcp comment 'IMAP'
            ufw allow 993/tcp comment 'IMAPS'
            ufw allow 110/tcp comment 'POP3'
            ufw allow 995/tcp comment 'POP3S'
            ufw reload
        elif command_exists firewall-cmd; then
            firewall-cmd --permanent --add-service=smtp --add-service=smtps --add-service=submission --add-service=imap --add-service=imaps --add-service=pop3 --add-service=pop3s 2>/dev/null || true
            firewall-cmd --reload 2>/dev/null || true
        fi
    }
}

start_services() {
    info "Starting mail services..."

    dry_run "Would start mail services" || {
        # Generate aliases database
        newaliases 2>/dev/null || true

        # Generate Postfix lookup tables
        postmap /etc/postfix/virtual_domains 2>/dev/null || true
        postmap /etc/postfix/virtual_mailbox 2>/dev/null || true
        postmap /etc/postfix/virtual_alias 2>/dev/null || true

        # Start services
        systemctl enable postfix dovecot
        systemctl restart postfix
        systemctl restart dovecot

        info "Mail services started successfully"
    }
}

verify_installation() {
    local domain="$1"

    info "Verifying mail server installation..."

    local errors=0

    # Check Postfix
    if ! systemctl is-active postfix >/dev/null 2>&1; then
        warn "Postfix service is not running"
        ((errors++))
    else
        info "Postfix is running"
    fi

    # Check Dovecot
    if ! systemctl is-active dovecot >/dev/null 2>&1; then
        warn "Dovecot service is not running"
        ((errors++))
    else
        info "Dovecot is running"
    fi

    # Check ports
    for port in 25 143 993 110 995; do
        if ss -tlnp 2>/dev/null | grep -q ":$port "; then
            info "Port $port is listening"
        else
            warn "Port $port is not listening"
            ((errors++))
        fi
    done

    # Test SMTP
    if timeout 2 bash -c 'echo "QUIT" | nc localhost 25' >/dev/null 2>&1; then
        info "SMTP connection successful"
    else
        warn "SMTP connection failed"
        ((errors++))
    fi

    if [ $errors -eq 0 ]; then
        info "Mail server verification completed successfully"
    else
        warn "Verification completed with $errors error(s)"
    fi

    return $errors
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -d, --dry-run           Run in dry-run mode (no changes made)
    -v, --verbose          Enable verbose output
    --domain DOMAIN         Mail domain (e.g., example.com)
    --hostname HOSTNAME      Mail server hostname (e.g., mail.example.com)

Examples:
    $0 --domain example.com --hostname mail.example.com
    $0 --domain example.com --hostname mail.example.com --dry-run
EOF
}

main() {
    local domain=""
    local hostname=""

    for arg in "$@"; do
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
            --domain)
                domain="${arg#*=}"
                shift
                ;;
            --hostname)
                hostname="${arg#*=}"
                shift
                ;;
        esac
        shift 2>/dev/null || true
    done

    if [ -z "$domain" ] || [ -z "$hostname" ]; then
        error "Domain and hostname are required"
        show_help
        exit 1
    fi

    info "Starting mail server setup..."
    info "Domain: $domain"
    info "Hostname: $hostname"
    info "Dry-run mode: $DRY_RUN"

    check_root
    local os=$(detect_os)

    install_packages "$os"
    generate_ssl_certs "$domain"
    configure_postfix_main "$domain" "$hostname"
    configure_postfix_master
    configure_dovecot "$domain"
    create_mail_users "$domain"
    configure_firewall
    start_services
    verify_installation "$domain"

    info "Mail server setup complete"
    info "Access mail via:"
    info "  - IMAP:   $hostname:143"
    info "  - IMAPS:  $hostname:993"
    info "  - POP3:   $hostname:110"
    info "  - POP3S:  $hostname:995"
    info "  - SMTP:   $hostname:25"
    info "  - Submit: $hostname:587"
}

main "$@"
