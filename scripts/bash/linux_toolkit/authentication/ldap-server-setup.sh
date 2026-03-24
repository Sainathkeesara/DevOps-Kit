#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# LDAP Server Setup Automation Script
# Purpose: Automate OpenLDAP server installation and configuration on Linux
# Requirements: Ubuntu 20.04+, Debian 11+, RHEL 8+, CentOS Stream 8+
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
    info "Installing OpenLDAP packages..."

    dry_run "Would install OpenLDAP packages" || {
        if [ "$os" = "debian" ]; then
            apt-get update
            apt-get install -y slapd ldap-utils libldap-2.4-2 libnss-ldap libpam-ldap nslcd openssl
        elif [ "$os" = "rhel" ]; then
            dnf install -y openldap openldap-servers openldap-clients nss_ldap pam_ldap openssl
        fi
    }
}

generate_password() {
    local password="$1"
    slappasswd -h {SSHA} -s "$password"
}

configure_domain() {
    local domain="$1"
    local admin_password="$2"

    local dc1=$(echo "$domain" | cut -d. -f1)
    local dc2=$(echo "$domain" | cut -d. -f2)
    local password_hash=$(generate_password "$admin_password")

    info "Configuring LDAP domain: $domain"

    dry_run "Would configure LDAP domain $domain" || {
        cat > /tmp/domain_config.ldif << EOF
dn: olcDatabase={1}mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcDbDirectory: /var/lib/ldap
olcSuffix: dc=$dc1,dc=$dc2
olcRootDN: cn=admin,dc=$dc1,dc=$dc2
olcRootPW: $password_hash
olcDbIndex: objectClass eq
olcDbIndex: cn,uid eq
olcDbIndex: uidNumber,gidNumber eq
olcDbIndex: member,memberUid eq
EOF

        ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/domain_config.ldif 2>/dev/null || \
            warn "Domain configuration may already exist"
    }
}

create_base_structure() {
    local domain="$1"
    local admin_password="$2"

    local dc1=$(echo "$domain" | cut -d. -f1)
    local dc2=$(echo "$domain" | cut -d. -f2)
    local password_hash=$(generate_password "$admin_password")

    info "Creating base LDAP directory structure..."

    dry_run "Would create base structure for $domain" || {
        cat > /tmp/base_structure.ldif << EOF
dn: dc=$dc1,dc=$dc2
objectClass: top
objectClass: dcObject
objectClass: organization
o: $domain Organization
dc: $dc1

dn: cn=admin,dc=$dc1,dc=$dc2
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP Administrator
userPassword: $password_hash

dn: ou=people,dc=$dc1,dc=$dc2
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=$dc1,dc=$dc2
objectClass: organizationalUnit
ou: groups

dn: ou=serviceaccounts,dc=$dc1,dc=$dc2
objectClass: organizationalUnit
ou: serviceaccounts
EOF

        ldapadd -x -D "cn=admin,dc=$dc1,dc=$dc2" -w "$admin_password" -f /tmp/base_structure.ldif 2>/dev/null || \
            warn "Base structure may already exist"
    }
}

configure_tls() {
    local domain="$1"

    info "Configuring TLS/SSL for LDAP..."

    dry_run "Would configure TLS/SSL certificates" || {
        mkdir -p /etc/ldap/ssl

        openssl req -new -x509 -nodes -days 365 \
            -keyout /etc/ldap/ssl/ldap.key \
            -out /etc/ldap/ssl/ldap.crt \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=ldap.$domain" 2>/dev/null

        chmod 600 /etc/ldap/ssl/ldap.key
        chmod 644 /etc/ldap/ssl/ldap.crt

        cat > /etc/ldap/slapd_tls.ldif << EOF
dn: cn=config
changetype: modify
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/ssl/ldap.key
-
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/ssl/ldap.crt
EOF

        ldapmodify -Y EXTERNAL -H ldapi:/// -f /etc/ldap/slapd_tls.ldif 2>/dev/null || \
            warn "TLS configuration may already exist"
    }
}

configure_client() {
    local domain="$1"
    local admin_password="$2"

    local dc1=$(echo "$domain" | cut -d. -f1)
    local dc2=$(echo "$domain" | cut -d. -f2)

    info "Configuring LDAP client..."

    dry_run "Would configure LDAP client" || {
        cat > /etc/ldap/ldap.conf << EOF
BASE    dc=$dc1,dc=$dc2
URI     ldap://localhost ldaps://localhost
TLS_CACERT  /etc/ldap/ssl/ldap.crt
TLS_REQCERT demand
EOF

        cat > /etc/nslcd.conf << EOF
uid nslcd
gid nslcd
uri ldap://localhost
uri ldaps://localhost
base dc=$dc1,dc=$dc2
ssl on
tls_checkpeer yes
tls_cacertfile /etc/ldap/ssl/ldap.crt
binddn cn=admin,dc=$dc1,dc=$dc2
bindpw $admin_password
EOF

        chmod 600 /etc/nslcd.conf

        cat > /etc/nsswitch.conf << 'EOF'
passwd:         files ldap
group:          files ldap
shadow:         files ldap
hosts:          files dns
networks:       files dns
services:       files
protocols:      files
rpc:            files
ethers:         files
netmasks:       files
netgroup:       files
bootparams:     files
automount:      files
aliases:        files
EOF

        systemctl enable nslcd 2>/dev/null || true
        systemctl restart nslcd 2>/dev/null || true
    }
}

configure_firewall() {
    info "Configuring firewall rules..."

    dry_run "Would configure firewall for LDAP" || {
        if command_exists ufw; then
            ufw allow 389/tcp comment 'LDAP'
            ufw allow 636/tcp comment 'LDAPS'
            ufw reload
        elif command_exists firewall-cmd; then
            firewall-cmd --permanent --add-service=ldap 2>/dev/null || true
            firewall-cmd --permanent --add-service=ldaps 2>/dev/null || true
            firewall-cmd --reload 2>/dev/null || true
        fi
    }
}

add_user() {
    local domain="$1"
    local admin_password="$2"
    local username="$3"
    local full_name="$4"
    local email="$5"
    local password="$6"

    local dc1=$(echo "$domain" | cut -d. -f1)
    local dc2=$(echo "$domain" | cut -d. -f2)
    local uid_number=$((10000 + $(date +%s) % 1000))
    local password_hash=$(generate_password "$password")

    dry_run "Would add user $username" || {
        cat > /tmp/add_user.ldif << EOF
dn: uid=$username,ou=people,dc=$dc1,dc=$dc2
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: $username
cn: $full_name
sn: $(echo "$full_name" | awk '{print $NF}')
givenName: $(echo "$full_name" | awk '{print $1}')
displayName: $full_name
mail: $email
uidNumber: $uid_number
gidNumber: 10000
homeDirectory: /home/$username
loginShell: /bin/bash
userPassword: $password_hash
EOF

        ldapadd -x -D "cn=admin,dc=$dc1,dc=$dc2" -w "$admin_password" -f /tmp/add_user.ldif
        info "User $username added successfully"
    }
}

add_group() {
    local domain="$1"
    local admin_password="$2"
    local groupname="$3"
    local members="$4"

    local dc1=$(echo "$domain" | cut -d. -f1)
    local dc2=$(echo "$domain" | cut -d. -f2)
    local gid_number=$((10000 + $(date +%s) % 1000))

    dry_run "Would add group $groupname" || {
        local members_ldif=""
        for member in $members; do
            members_ldif="${members_ldif}memberUid: $member\n"
        done

        cat > /tmp/add_group.ldif << EOF
dn: cn=$groupname,ou=groups,dc=$dc1,dc=$dc2
objectClass: posixGroup
cn: $groupname
gidNumber: $gid_number
$(echo -e "$members_ldif")
EOF

        ldapadd -x -D "cn=admin,dc=$dc1,dc=$dc2" -w "$admin_password" -f /tmp/add_group.ldif
        info "Group $groupname added successfully"
    }
}

verify_installation() {
    local domain="$1"
    local admin_password="$2"

    local dc1=$(echo "$domain" | cut -d. -f1)
    local dc2=$(echo "$domain" | cut -d. -f2)

    info "Verifying LDAP installation..."

    local errors=0

    if ! systemctl is-active slapd >/dev/null 2>&1; then
        warn "slapd service is not running"
        ((errors++))
    fi

    if ! ldapwhoami -x -H ldap://localhost >/dev/null 2>&1; then
        warn "Cannot connect to LDAP server"
        ((errors++))
    fi

    if ! ldapsearch -x -H ldap://localhost -b "dc=$dc1,dc=$dc2" >/dev/null 2>&1; then
        warn "Cannot search LDAP directory"
        ((errors++))
    fi

    if [ $errors -eq 0 ]; then
        info "LDAP installation verified successfully"
    else
        warn "Verification completed with $errors error(s)"
    fi
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -d, --dry-run           Run in dry-run mode (no changes made)
    -v, --verbose          Enable verbose output
    --domain DOMAIN         LDAP domain (e.g., example.com)
    --admin-password PASS   LDAP admin password
    --add-user USERNAME     Add a user (use with --full-name, --email, --password)
    --full-name NAME        Full name for user
    --email EMAIL           Email for user
    --password PASS         Password for user
    --add-group GROUP       Add a group (use with --members)
    --members USER1,USER2   Comma-separated list of members

Examples:
    $0 --domain example.com --admin-password secret123
    $0 --domain example.com --admin-password secret123 --add-user jsmith --full-name "John Smith" --email jsmith@example.com --password userpass
    $0 --domain example.com --admin-password secret123 --add-group developers --members jsmith,alice
EOF
}

main() {
    local domain=""
    local admin_password=""
    local add_user=""
    local full_name=""
    local email=""
    local user_password=""
    local add_group=""
    local members=""

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
            --admin-password)
                admin_password="${arg#*=}"
                shift
                ;;
            --add-user)
                add_user="${arg#*=}"
                shift
                ;;
            --full-name)
                full_name="${arg#*=}"
                shift
                ;;
            --email)
                email="${arg#*=}"
                shift
                ;;
            --password)
                user_password="${arg#*=}"
                shift
                ;;
            --add-group)
                add_group="${arg#*=}"
                shift
                ;;
            --members)
                members="${arg#*=}"
                shift
                ;;
        esac
        shift 2>/dev/null || true
    done

    if [ -z "$domain" ] || [ -z "$admin_password" ]; then
        error "Domain and admin password are required"
        show_help
        exit 1
    fi

    info "Starting LDAP server setup..."
    info "Domain: $domain"
    info "Dry-run mode: $DRY_RUN"

    check_root
    local os=$(detect_os)

    install_packages "$os"
    configure_domain "$domain" "$admin_password"
    create_base_structure "$domain" "$admin_password"
    configure_tls "$domain"
    configure_client "$domain" "$admin_password"
    configure_firewall

    if [ -n "$add_user" ]; then
        add_user "$domain" "$admin_password" "$add_user" "$full_name" "$email" "$user_password"
    fi

    if [ -n "$add_group" ]; then
        add_group "$domain" "$admin_password" "$add_group" "$members"
    fi

    verify_installation "$domain" "$admin_password"

    info "LDAP server setup complete"
}

main "$@"
