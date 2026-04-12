# Linux Identity Management with FreeIPA

## Purpose

Deploy and manage a FreeIPA (Fedora Identity Management) domain to provide centralized authentication, authorization, and account management for Linux infrastructure. FreeIPA integrates LDAP, Kerberos, DNS, and certificate services into a single, cohesive identity management solution.

## When to use

- Consolidating local `/etc/passwd`, `/etc/shadow`, and `/etc/group` accounts across multiple servers
- Implementing single sign-on (SSO) for Linux infrastructure
- Enforcing centralized password policies and account expiration
- Managing sudo rules and host-based access control from a central authority
- Requiring LDAP + Kerberos combined authentication (not LDAP alone)
- Implementing host keytab-based authentication for automated operations

## Prerequisites

### Server Requirements
- AlmaLinux 9.4+, RHEL 9.4+, or Fedora 38+
- Minimum 2 CPU cores, 4GB RAM (4GB recommended for production)
- 10GB free disk space for `/var/lib/ipa`
- Static IP address with FQDN configured in DNS
- TCP ports 80, 443, 389, 636, 88, 464, 123 UDP
- UDP ports 53, 88, 464, 123

### Client Requirements
- Any Linux distribution with FreeIPA client support
- Network connectivity to FreeIPA server on ports 80, 443, 389, 636, 88, 464
- FQDN resolution pointing to IPA server

### Network Requirements
- DNS domain configured (e.g., `corp.example.com`)
- Reverse DNS (PTR) records for IPA server
- Firewall rules allowing required ports

## Steps

### 1. Prepare the FreeIPA Server

```bash
# Verify OS version
cat /etc/almalinux-release
# Expected: AlmaLinux release 9.4 (Electric Blue)

# Check current hostname and configure FQDN
hostname
hostname fqdn
# Must return: hostname.corp.example.com

# Configure DNS resolver
cat /etc/resolv.conf
# Add nameserver pointing to localhost if using IPA-integrated DNS
```

### 2. Install FreeIPA Packages

```bash
# AlmaLinux / RHEL
sudo dnf install -y ipa-server ipa-server-dns

# Fedora
sudo dnf install -y freeipa-server freeipa-server-dns
```

### 3. Deploy IPA Server (Interactive)

```bash
sudo ipa-server-install \
  --realm=CORP.EXAMPLE.COM \
  --domain=corp.example.com \
  --password='YourSecurePassword123!' \
  --setup-dns \
  --dns-forwarder=8.8.8.8 \
  --no-ntp \
  --unattended
```

### 4. Deploy IPA Server (Non-Interactive with Script)

```bash
# Use the automation script
sudo chmod +x scripts/bash/linux/identity/freeipa-setup.sh
sudo ./scripts/bash/linux/identity/freeipa-setup.sh \
  --server \
  --realm=CORP.EXAMPLE.COM \
  --domain=corp.example.com \
  --admin-pass 'YourSecurePassword123!' \
  --dns-forwarder 8.8.8.8
```

### 5. Verify Server Deployment

```bash
# Login as admin
kinit admin@CORP.EXAMPLE.COM
# Password: YourSecurePassword123!

# Check user list
ipa user-find

# Check host list
ipa host-find

# Check service list
ipa service-find
```

### 6. Enroll an IPA Client

```bash
# On client machine
sudo ipa-client-install \
  --server=ipa01.corp.example.com \
  --realm=CORP.EXAMPLE.COM \
  --domain=corp.example.com \
  --password='YourSecurePassword123!' \
  --unattended
```

### 7. Create Users and Groups

```bash
# Create user
ipa user-add developer \
  --first=Developer \
  --last=Team \
  --password

# Create group
ipa group-add developers --desc="Development team members"

# Add user to group
ipa group-add-member developers --users=developer
```

### 8. Configure Sudo Rules

```bash
# Create sudo rule
ipa sudorule-add developer sudo

# Allow specific command
ipa sudorule-add-option developer sudo \
  --cmdcat=all

# Apply to group
ipa sudorule-add-group developer sudo --group=developers
```

### 9. Manage Host Access

```bash
# Enable automatic client enrollment
ipa hostgroup-add servers --desc="Production servers"

# Add host to group
ipa hostgroup-add-member servers --hosts=server01.corp.example.com
```

## Verify

### Test Server Functionality

```bash
# Authentication test
kinit admin@CORP.EXAMPLE.COM
klist

# User lookup
ipa user-show admin

# DNS resolution
dig SRV _ldap._tcp.corp.example.com
dig SRV _kerberos._tcp.corp.example.com
```

### Test Client Functionality

```bash
# SSH with Kerberos authentication
ssh -G user@client.corp.example.com | grep -i gssapi
# Should show: GSSAPIAuthentication yes

# Get Kerberos TGT
kinit
klist

# Check sudo access
sudo -l
```

### Health Check

```bash
# Run IPA healthcheck
ipa-healthcheck --failures-only

# Check services
ipa servicestatus
```

## Rollback

### Remove IPA Client

```bash
# On client machine
sudo ipa-client-install --uninstall
```

### Remove IPA Server

```bash
# WARNING: This destroys all data
sudo ipa-server-install --uninstall

# Manual cleanup
rm -rf /var/lib/ipa
rm -rf /etc/ipa
```

## Common errors

### "DNS is not configured properly"

**Problem:** IPA server installation fails with DNS validation error.

**Solution:**
```bash
# Configure DNS forwarder
# Add forwarder to /etc/named.conf or use IPA's internal DNS
# Ensure /etc/resolv.conf points to IPA server IP

# Verify DNS resolution
dig corp.example.com
dig _ldap._tcp.corp.example.com SRV
```

### "Hostname must be fully qualified"

**Problem:** hostname command returns short hostname.

**Solution:**
```bash
# Set FQDN
hostnamectl set-hostname ipa01.corp.example.com

# Edit /etc/hosts
# 192.168.1.10    ipa01.corp.example.com    ipa01
```

### "Insufficient permissions to become CA"

**Problem:** IPA server install fails with permission error.

**Solution:**
```bash
# Run with root privileges
sudo -i

# Or use dnf with --assumeyes
dnf install -y --assumeyes ipa-server
```

### "KDC cannot forward request"

**Problem:** Client enrollment fails with Kerberos error.

**Solution:**
```bash
# Ensure time sync on both server and client
# NTP should be configured
timedatectl status

# Check firewall on IPA server
firewall-cmd --list-all
# Ensure ports are open
```

### "ipa: ERROR: no such realm"

**Problem:** Realm name mismatch between client and server.

**Solution:**
```bash
# Ensure client uses exact realm from server
# Check /etc/ipa/default.conf on server
cat /etc/ipa/default.conf

# Re-run client install with correct realm
ipa-client-install --realm=CORP.EXAMPLE.COM
```

### "FreeIPA CA certificate is not valid"

**Problem:** Client shows certificate validation errors.

**Solution:**
```bash
# Update CA certificates
update-ca-trust extract

# On RHEL/AlmaLinux
openssl verify -CAfile /etc/ipa/ca.crt /etc/ipa/ca.crt
```

## References

- FreeIPA Documentation: https://documentation.redhat.com/product/null/
- FreeIPA Server Installation: https://access.redhat.com/documentation/en-us/red_hat_identity_management/1/html/installation_guide/index
- FreeIPA Client Configuration: https://access.redhat.com/documentation/en-us/red_hat_identity_management/1/html/client_configuration_guide/index
- Kerberos Documentation: https://web.mit.edu/kerberos/
- AlmaLinux IdM Setup: https://wiki.almalinux.org/documentation/1.3/integrating_freeipa_into_almalinux.html