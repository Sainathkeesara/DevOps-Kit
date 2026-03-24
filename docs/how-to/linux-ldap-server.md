# Linux LDAP Authentication Server Setup

## Purpose

This guide explains how to set up and configure an LDAP (Lightweight Directory Access Protocol) authentication server on Linux using OpenLDAP. The server will serve as a central directory for user authentication, authorization, and address book services across your infrastructure.

## When to Use

Use this guide when you need to:
- Centralize user authentication across multiple Linux servers
- Implement single sign-on (SSO) for organizational applications
- Replace local `/etc/passwd` and `/etc/shadow` with directory-based authentication
- Integrate Linux systems with Windows Active Directory via LDAP federation
- Deploy a corporate address book solution
- Meet compliance requirements for centralized access control

## Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04/22.04, Debian 11/12, RHEL 8/9, AlmaLinux 9, Rocky Linux 9
- **Architecture**: x86_64 or ARM64
- **RAM**: 2GB minimum (4GB+ recommended for production)
- **CPU**: 2+ cores
- **Disk**: 20GB+ available space for directory data
- **Network**: Static IP recommended, port 389 (LDAP) and 636 (LDAPS) accessible

### Required Privileges
- Root or sudo access for package installation and configuration
- Ability to modify system authentication configuration
- Access to configure firewall rules

### Knowledge Prerequisites
- Basic Linux system administration
- Understanding of LDAP concepts (entries, DNs, attributes, schemas)
- Familiarity with PAM (Pluggable Authentication Modules)
- Knowledge of SSL/TLS certificate generation

## Steps

### Step 1: Update System and Install OpenLDAP

Update your package lists and install the required packages:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y slapd ldap-utils libldap-2.4-2

# RHEL/CentOS
sudo dnf install -y openldap openldap-servers openldap-clients

# Verify installation
slapd -V
```

### Step 2: Configure OpenLDAP Administrator Password

Set up the LDAP administrator password:

```bash
# Generate SSHA password hash
slappasswd -h {SSHA} -s your_secure_password

# Create password hash and save for later use
echo "{SSHA}your_generated_hash_here" | sudo tee /etc/ldap/admin_password.hash
```

### Step 3: Configure LDAP Domain

Create the LDAP domain configuration:

```bash
# Create LDAP configuration directory
sudo mkdir -p /etc/ldap/slapd.d

# Set domain components (example: dc=example,dc=com)
DOMAIN="example.com"
DC1=$(echo "$DOMAIN" | cut -d. -f1)
DC2=$(echo "$DOMAIN" | cut -d. -f2)

# Create the domain configuration file
sudo tee /tmp/domain.ldif << EOF
dn: olcDatabase={1}mdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcMdbConfig
olcDatabase: mdb
olcDbDirectory: /var/lib/ldap
olcSuffix: dc=$DC1,dc=$DC2
olcRootDN: cn=admin,dc=$DC1,dc=$DC2
olcRootPW: {SSHA}your_generated_hash_here
olcLimits: dn.exact=gidNumber=0+uidNumber=0,cn=peer,cn=external,cn=auth allow manage
olcLimits: dn.base="cn=Subschema" allow read
olcDbIndex: objectClass eq
olcDbIndex: cn,uid eq
olcDbIndex: uidNumber,gidNumber eq
olcDbIndex: member,memberUid eq
EOF

# Apply configuration
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/domain.ldif
```

### Step 4: Create Base Directory Structure

Create the organizational units for your LDAP directory:

```bash
# Create base.ldif for directory structure
sudo tee /tmp/base.ldif << EOF
dn: dc=$DC1,dc=$DC2
objectClass: top
objectClass: dcObject
objectClass: organization
o: $DOMAIN Organization
dc: $DC1

dn: cn=admin,dc=$DC1,dc=$DC2
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP Administrator
userPassword: {SSHA}your_generated_hash_here

dn: ou=people,dc=$DC1,dc=$DC2
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=$DC1,dc=$DC2
objectClass: organizationalUnit
ou: groups

dn: ou=serviceaccounts,dc=$DC1,dc=$DC2
objectClass: organizationalUnit
ou: serviceaccounts
EOF

# Add base entries
sudo ldapadd -x -D "cn=admin,dc=$DC1,dc=$DC2" -W -f /tmp/base.ldif
```

### Step 5: Enable LDAPS (SSL/TLS)

Configure LDAP over SSL for secure communications:

```bash
# Create SSL certificate directory
sudo mkdir -p /etc/ldap/ssl

# Generate self-signed certificate
sudo openssl req -new -x509 -nodes -days 365 \
    -keyout /etc/ldap/ssl/ldap.key \
    -out /etc/ldap/ssl/ldap.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=ldap.$DOMAIN"

# Set proper permissions
sudo chmod 600 /etc/ldap/ssl/ldap.key
sudo chmod 644 /etc/ldap/ssl/ldap.crt

# Configure LDAP to use SSL
sudo tee /etc/ldap/slapd.ldif << EOF
dn: cn=config
changetype: modify
add: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/ssl/ldap.key
-
add: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/ssl/ldap.crt
EOF

sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f /etc/ldap/slapd.ldif
```

### Step 6: Configure LDAP Client

Set up system authentication to use LDAP:

```bash
# Install LDAP client packages
sudo apt-get install -y libnss-ldap libpam-ldap ldap-utils

# Configure NSS (Name Service Switch)
sudo tee /etc/nsswitch.conf << EOF
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

# Configure PAM (Pluggable Authentication Modules)
sudo tee /etc/pam.d/common-auth << EOF
auth    [success=1 default=ignore]  pam_ldap.so  use_first_pass
auth    required                        pam_permit.so
auth    optional                        pam_cap.so
EOF

sudo tee /etc/pam.d/common-account << EOF
account    [success=1 default=ignore]  pam_ldap.so
account    required                        pam_permit.so
EOF

sudo tee /etc/pam.d/common-password << EOF
password    [success=1 default=ignore]  pam_ldap.so try_first_pass
password    required                        pam_permit.so
EOF

sudo tee /etc/pam.d/common-session << EOF
session    [default=1]           pam_permit.so
session    required              pam_loginuid.so
session    required              pam_permit.so
session    optional              pam_ldap.so
session    required              pam_mkhomedir.so skel=/etc/skel umask=0077
EOF
```

### Step 7: Configure LDAP Client Connection

Edit the LDAP client configuration:

```bash
# Configure LDAP client
sudo tee /etc/ldap/ldap.conf << EOF
BASE    dc=$DC1,dc=$DC2
URI     ldap://localhost ldaps://localhost
TLS_CACERT  /etc/ldap/ssl/ldap.crt

# SSL/TLS options
TLS_REQCERT demand
EOF

# Configure nslcd (LDAP name service daemon)
sudo apt-get install -y nslcd

sudo tee /etc/nslcd.conf << EOF
uid nslcd
gid nslcd
uri ldaps://localhost
base dc=$DC1,dc=$DC2
ssl on
tls_checkpeer yes
tls_cacertfile /etc/ldap/ssl/ldap.crt
binddn cn=admin,dc=$DC1,dc=$DC2
bindpw your_admin_password
EOF

# Restart nslcd
sudo systemctl enable nslcd
sudo systemctl restart nslcd
```

### Step 8: Create LDAP Users

Add users to the LDAP directory:

```bash
# Create user LDIF file
sudo tee /tmp/add_users.ldif << EOF
dn: uid=jsmith,ou=people,dc=$DC1,dc=$DC2
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: jsmith
cn: John Smith
sn: Smith
givenName: John
displayName: John Smith
mail: jsmith@$DOMAIN
uidNumber: 10000
gidNumber: 10000
homeDirectory: /home/jsmith
loginShell: /bin/bash
userPassword: {SSHA}user_password_hash

dn: uid=alice,ou=people,dc=$DC1,dc=$DC2
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: alice
cn: Alice Anderson
sn: Anderson
givenName: Alice
displayName: Alice Anderson
mail: alice@$DOMAIN
uidNumber: 10001
gidNumber: 10000
homeDirectory: /home/alice
loginShell: /bin/bash
userPassword: {SSHA}user_password_hash
EOF

# Add users to LDAP
sudo ldapadd -x -D "cn=admin,dc=$DC1,dc=$DC2" -W -f /tmp/add_users.ldif
```

### Step 9: Create LDAP Groups

Add groups to the LDAP directory:

```bash
# Create group LDIF file
sudo tee /tmp/add_groups.ldif << EOF
dn: cn=developers,ou=groups,dc=$DC1,dc=$DC2
objectClass: posixGroup
cn: developers
gidNumber: 10000
memberUid: jsmith
memberUid: alice

dn: cn=admins,ou=groups,dc=$DC1,dc=$DC2
objectClass: posixGroup
cn: admins
gidNumber: 10001
memberUid: jsmith
EOF

# Add groups to LDAP
sudo ldapadd -x -D "cn=admin,dc=$DC1,dc=$DC2" -W -f /tmp/add_groups.ldif
```

### Step 10: Configure Firewall

Set up firewall rules for LDAP:

```bash
# UFW (Ubuntu)
sudo ufw allow 389/tcp comment 'LDAP'
sudo ufw allow 636/tcp comment 'LDAPS'
sudo ufw reload

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-service=ldap
sudo firewall-cmd --permanent --add-service=ldaps
sudo firewall-cmd --reload
```

## Verify

### Verify LDAP Server is Running

```bash
# Check slapd service status
sudo systemctl status slapd

# Check LDAP listening ports
sudo ss -tlnp | grep -E ':389|:636'

# Test LDAP connection
ldapwhoami -x -H ldap://localhost

# Test with authentication
ldapwhoami -x -D "cn=admin,dc=example,dc=com" -W -H ldap://localhost
```

### Verify LDAP Search

```bash
# Search for all entries
ldapsearch -x -H ldap://localhost -b "dc=example,dc=com"

# Search for specific user
ldapsearch -x -H ldap://localhost -b "ou=people,dc=example,dc=com" "(uid=jsmith)"

# Search for groups
ldapsearch -x -H ldap://localhost -b "ou=groups,dc=example,dc=com" "(cn=developers)"
```

### Verify Client Authentication

```bash
# Test user lookup from LDAP
getent passwd jsmith

# Test group lookup from LDAP
getent group developers

# Verify user can authenticate
# (will prompt for password)
su - jsmith -c "id"
```

### Verify TLS/SSL

```bash
# Test LDAPS connection
ldapwhoami -x -H ldaps://localhost -Z

# Verify certificate
openssl s_client -connect localhost:636 -showcerts </dev/null 2>/dev/null | openssl x509 -noout -text | grep -A2 "Subject:"
```

## Rollback

### Remove LDAP Users and Groups

```bash
# Delete users
sudo ldapdelete -x -D "cn=admin,dc=example,dc=com" -W "uid=jsmith,ou=people,dc=example,dc=com"
sudo ldapdelete -x -D "cn=admin,dc=example,dc=com" -W "uid=alice,ou=people,dc=example,dc=com"

# Delete groups
sudo ldapdelete -x -D "cn=admin,dc=example,dc=com" -W "cn=developers,ou=groups,dc=example,dc=com"
sudo ldapdelete -x -D "cn=admin,dc=example,dc=com" -W "cn=admins,ou=groups,dc=example,dc=com"
```

### Disable LDAP Authentication

```bash
# Restore local authentication only
sudo tee /etc/nsswitch.conf << EOF
passwd:         files
group:          files
shadow:         files
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

# Stop and disable nslcd
sudo systemctl stop nslcd
sudo systemctl disable nslcd
```

### Remove OpenLDAP Completely

```bash
# Stop service
sudo systemctl stop slapd

# Remove packages
sudo apt-get remove --purge -y slapd ldap-utils libldap-2.4-2
sudo rm -rf /etc/ldap
sudo rm -rf /var/lib/ldap

# Remove client configuration
sudo apt-get remove --purge -y libnss-ldap libpam-ldap nslcd
```

## Common Errors

### Error: "ldap_bind: Invalid credentials (49)"

**Solution**: Verify the admin DN and password are correct. Check for trailing spaces in configuration files.

```bash
# Test with explicit credentials
ldapwhoami -x -D "cn=admin,dc=example,dc=com" -W -H ldap://localhost

# Reset admin password if needed
slappasswd -h {SSHA} -s new_password
# Update the password in your LDIF files
```

### Error: "ldap_sasl_bind(SIMPLE): Can't contact LDAP server (-1)"

**Solution**: Ensure the LDAP server is running and accessible.

```bash
# Check if slapd is running
sudo systemctl status slapd

# Check firewall rules
sudo iptables -L -n | grep 389

# Verify LDAP is listening
sudo ss -tlnp | grep 389
```

### Error: "TLS certificate verification: Error, certificate not found"

**Solution**: Configure the correct CA certificate path.

```bash
# Verify certificate exists
ls -la /etc/ldap/ssl/ldap.crt

# Update LDAP client configuration
sudo tee /etc/ldap/ldap.conf << EOF
BASE    dc=example,dc=com
URI     ldap://localhost ldaps://localhost
TLS_CACERT  /etc/ldap/ssl/ldap.crt
TLS_REQCERT allow
EOF
```

### Error: "getent shows no LDAP users"

**Solution**: Check nslcd configuration and service status.

```bash
# Restart nslcd with debug mode
sudo nslcd -d

# Check nslcd logs
sudo journalctl -u nslcd -n 50

# Verify nslcd is running
sudo systemctl status nslcd
```

### Error: "nss_ldap: failed to bind to LDAP server"

**Solution**: Verify binddn credentials in nslcd.conf.

```bash
# Check nslcd configuration
sudo cat /etc/nslcd.conf | grep -E "binddn|bindpw"

# Test binding with these credentials
ldapwhoami -x -D "cn=admin,dc=example,dc=com" -W -H ldap://localhost
```

## References

- [OpenLDAP Software Documentation](https://www.openldap.org/doc/)
- [Linux PAM Configuration](https://www.freedesktop.org/software/system-manual/system-manual-pam.html)
- [RFC 4511 - LDAPv3](https://tools.ietf.org/html/rfc4511)
- [Ubuntu OpenLDAP Server Guide](https://help.ubuntu.com/lts/serverguide/openldap-server.html)
- [Red Hat LDAP Documentation](https://access.redhat.com/documentation/en-us/red_hat_directory_server/)
- [LDAP Authentication on Linux](https://www.digitalocean.com/community/tutorials/how-to-authenticate-client-computers-using-ldap-on-ubuntu-18-04)
- [TLS/SSL Configuration for OpenLDAP](https://www.openldap.org/doc/admin24/tls.html)
