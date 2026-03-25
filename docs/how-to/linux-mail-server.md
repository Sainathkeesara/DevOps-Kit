# Linux Mail Server Setup with Postfix and Dovecot

## Purpose

This guide explains how to set up and configure a complete mail server on Linux using Postfix (SMTP) and Dovecot (IMAP/POP3). The server will provide email sending, receiving, and retrieval capabilities for your organization.

## When to Use

Use this guide when you need to:
- Set up a corporate email server for your organization
- Host custom domain email services
- Configure local mail delivery for Linux servers
- Implement secure email communication with TLS encryption
- Replace third-party email services with self-hosted solution
- Set up email aliases and virtual mailboxes

## Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04/22.04, Debian 11/12, RHEL 8/9, Rocky Linux 9, AlmaLinux 9
- **Architecture**: x86_64 or ARM64
- **RAM**: 2GB minimum (4GB+ recommended for production)
- **CPU**: 2+ cores
- **Disk**: 20GB+ available space for email storage
- **Network**: Static IP with proper DNS records (MX, A, PTR)

### DNS Requirements
- Valid domain name registered
- MX record pointing to mail server
- A record for mail.domain.com
- Reverse DNS (PTR) record for IP
- SPF record for domain
- DKIM record (optional but recommended)
- DMARC record (optional but recommended)

### Required Privileges
- Root or sudo access for package installation
- Ability to modify DNS records
- Access to configure firewall rules

### Knowledge Prerequisites
- Basic Linux system administration
- Understanding of email protocols (SMTP, IMAP, POP3)
- Familiarity with DNS record types
- Knowledge of SSL/TLS certificates

## Steps

### Step 1: Update System and Install Dependencies

Update your package lists and install required packages:

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y postfix postfix-pcre postfix-ldap dovecot-core dovecot-imapd dovecot-pop3d dovecot-ldap openssl ca-certificates

# RHEL/CentOS
sudo dnf install -y postfix dovecot openssl ca-certificates
sudo systemctl enable postfix dovecot
```

### Step 2: Configure DNS Records

Before configuring the mail server, ensure your DNS is properly set up:

```bash
# Example DNS records (configure in your DNS provider)
# MX Record: @ -> mail.yourdomain.com (priority 10)
# A Record: mail.yourdomain.com -> 192.0.2.1
# PTR Record: 1.2.0.192.in-addr.arpa -> mail.yourdomain.com

# SPF Record (TXT):
v=spf1 mx -all

# DKIM Record (TXT) - generated after Postfix setup
# _domainkey.yourdomain.com -> v=DKIM1; k=rsa; p=your-public-key

# DMARC Record (TXT):
_dmarc.yourdomain.com -> v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@yourdomain.com
```

### Step 3: Generate SSL Certificates

Generate SSL certificates for secure email communication:

```bash
# Create SSL certificate directory
sudo mkdir -p /etc/ssl/private

# Generate self-signed certificate (for testing)
sudo openssl req -new -x509 -days 365 -nodes \
    -keyout /etc/ssl/private/mail.key \
    -out /etc/ssl/certs/mail.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=mail.yourdomain.com"

# Set proper permissions
sudo chmod 600 /etc/ssl/private/mail.key
sudo chmod 644 /etc/ssl/certs/mail.crt
```

For production, use Let's Encrypt or your CA of choice.

### Step 4: Configure Postfix Main Settings

Edit the Postfix main configuration:

```bash
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.backup
sudo nano /etc/postfix/main.cf
```

Add or modify these settings:

```bash
# Network Configuration
inet_interfaces = all
inet_protocols = all

# Domain Configuration
myhostname = mail.yourdomain.com
mydomain = yourdomain.com
myorigin = $mydomain
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# Mail Queue
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
home_mailbox = Maildir/

# Size Limits
message_size_limit = 52428800
mailbox_size_limit = 1073741824

# SASL Authentication
smtpd_sasl_auth_enable = yes
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_security_options = noanonymous
broken_sasl_auth_clients = yes

# TLS Configuration
smtpd_tls_cert_file = /etc/ssl/certs/mail.crt
smtpd_tls_key_file = /etc/ssl/private/mail.key
smtpd_tls_security_level = may
smtpd_tls_auth_only = no
smtpd_tls_CAfile = /etc/ssl/certs/ca-certificates.crt

# Submission Port (587)
submission inet n - - - - smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject

# SMTPS Port (465)
smtps inet n - - - - smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes

# Security
smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination
smtpd_helo_required = yes
disable_vrfy_command = yes
```

### Step 5: Configure Postfix Master Settings

Edit the Postfix master configuration:

```bash
sudo cp /etc/postfix/master.cf /etc/postfix/master.cf.backup
sudo nano /etc/postfix/master.cf
```

Ensure these services are enabled:

```bash
# Standard SMTP
smtp      inet  n       -       -       -       smtpd

# Submission
submission inet n       -       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes

# SMTPS
smtps     inet  n       -       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
```

### Step 6: Configure Dovecot

Edit the Dovecot main configuration:

```bash
sudo cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.backup
sudo nano /etc/dovecot/dovecot.conf
```

```bash
# Protocols
protocols = imap pop3 lmtp

# Listen on all interfaces
listen = *, ::

# Mail location
mail_location = maildir:/var/mail/vmail/%d/%n

# User configuration
mail_uid = 5000
mail_gid = 5000
mail_privileged_group = mail

# Authentication
auth_mechanisms = plain login
disable_plaintext_auth = no
```

Configure authentication:

```bash
sudo nano /etc/dovecot/10-auth.conf
```

```bash
auth_mechanisms = plain login
!include auth-passwdfile.conf.ext
!include auth-system.conf.ext
```

Configure SSL:

```bash
sudo nano /etc/dovecot/10-ssl.conf
```

```bash
ssl = yes
ssl_cert = </etc/ssl/certs/mail.crt
ssl_key = </etc/ssl/private/mail.key
```

### Step 7: Create Mail Users

Create a system user for mail:

```bash
# Create vmail user
sudo useradd -r -u 5000 -g 5000 -s /sbin/nologin -d /var/mail vmail

# Create mail directory
sudo mkdir -p /var/mail/vmail/yourdomain.com
sudo chown -R vmail:vmail /var/mail
sudo chmod -R 770 /var/mail
```

Add system users for email access:

```bash
# Create user with mail
sudo useradd -m -s /bin/bash john
sudo passwd john

# Or use virtual mailboxes (see Step 8)
```

### Step 8: Configure Virtual Mailboxes (Optional)

For virtual mailboxes (multiple domains, no system users):

```bash
# Create virtual domain file
sudo nano /etc/postfix/virtual_domains
```

```
yourdomain.com
anotherdomain.com
```

```bash
# Create virtual mailbox file
sudo nano /etc/postfix/virtual_mailbox
```

```
user1@yourdomain.com yourdomain.com/user1/
user2@yourdomain.com yourdomain.com/user2/
```

```bash
# Create virtual alias file
sudo nano /etc/postfix/virtual_alias
```

```
admin@yourdomain.com user1@yourdomain.com
support@yourdomain.com user2@yourdomain.com
```

```bash
# Generate lookup tables
sudo postmap /etc/postfix/virtual_domains
sudo postmap /etc/postfix/virtual_mailbox
sudo postmap /etc/postfix/virtual_alias

# Update main.cf for virtual domains
sudo postconf -e "virtual_mailbox_domains = hash:/etc/postfix/virtual_domains"
sudo postconf -e "virtual_mailbox_base = /var/mail/vmail"
sudo postconf -e "virtual_mailbox_maps = hash:/etc/postfix/virtual_mailbox"
sudo postconf -e "virtual_alias_maps = hash:/etc/postfix/virtual_alias"
sudo postconf -e "virtual_uid_maps = static:5000"
sudo postconf -e "virtual_gid_maps = static:5000"
```

### Step 9: Configure Firewall

Set up firewall rules:

```bash
# UFW (Ubuntu)
sudo ufw allow 25/tcp    # SMTP
sudo ufw allow 587/tcp   # Submission
sudo ufw allow 465/tcp   # SMTPS
sudo ufw allow 143/tcp   # IMAP
sudo ufw allow 993/tcp   # IMAPS
sudo ufw allow 110/tcp   # POP3
sudo ufw allow 995/tcp   # POP3S

# firewalld (RHEL/CentOS)
sudo firewall-cmd --permanent --add-service=smtp
sudo firewall-cmd --permanent --add-service=smtps
sudo firewall-cmd --permanent --add-service=submission
sudo firewall-cmd --permanent --add-service=imap
sudo firewall-cmd --permanent --add-service=imaps
sudo firewall-cmd --permanent --add-service=pop3
sudo firewall-cmd --permanent --add-service=pop3s
sudo firewall-cmd --reload
```

### Step 10: Start Services

Start and enable the mail services:

```bash
# Generate aliases database
sudo newaliases

# Test configuration
sudo postfix check

# Start services
sudo systemctl restart postfix
sudo systemctl enable postfix
sudo systemctl restart dovecot
sudo systemctl enable dovecot

# Check status
sudo systemctl status postfix
sudo systemctl status dovecot
```

## Verify

### Verify Services Running

```bash
# Check Postfix
sudo systemctl status postfix

# Check Dovecot
sudo systemctl status dovecot

# Check listening ports
sudo ss -tlnp | grep -E ':25|:465|:587|:143|:993|:110|:995'
```

### Verify Connectivity

```bash
# Test SMTP
telnet localhost 25
EHLO mail.yourdomain.com
QUIT

# Test IMAP
telnet localhost 143
A001 LOGIN username password
A001 LOGOUT

# Test with OpenSSL
openssl s_client -connect localhost:993 -quiet
```

### Verify DNS

```bash
# Check MX record
dig MX yourdomain.com

# Check reverse DNS
dig -x $(hostname -I | awk '{print $1}')

# Check SPF
dig TXT yourdomain.com
```

### Test Email Delivery

```bash
# Send test email from command line
echo "Test message" | mail -s "Test Subject" user@yourdomain.com

# Check mail queue
sudo postqueue -p

# Check mail logs
sudo tail -f /var/log/mail.log
sudo tail -f /var/log/maillog
sudo tail -f /var/log/messages
```

## Rollback

### Stop Services

```bash
sudo systemctl stop postfix
sudo systemctl stop dovecot
```

### Restore Configuration Files

```bash
# Restore Postfix
sudo cp /etc/postfix/main.cf.backup /etc/postfix/main.cf
sudo cp /etc/postfix/master.cf.backup /etc/postfix/master.cf

# Restore Dovecot
sudo cp /etc/dovecot/dovecot.conf.backup /etc/dovecot/dovecot.conf
```

### Remove Packages

```bash
# Ubuntu/Debian
sudo apt-get remove --purge -y postfix dovecot
sudo rm -rf /var/mail

# RHEL/CentOS
sudo dnf remove -y postfix dovecot
sudo rm -rf /var/mail
```

### Reset Firewall

```bash
# UFW
sudo ufw delete allow 25/tcp
sudo ufw delete allow 587/tcp
sudo ufw delete allow 465/tcp
sudo ufw delete allow 143/tcp
sudo ufw delete allow 993/tcp
sudo ufw delete allow 110/tcp
sudo ufw delete allow 995/tcp

# firewalld
sudo firewall-cmd --permanent --remove-service=smtp
sudo firewall-cmd --permanent --remove-service=smtps
sudo firewall-cmd --reload
```

## Common Errors

### Error: "Connection refused" on port 25

**Solution**: Check if Postfix is running and listening on the correct interface.

```bash
# Check Postfix status
sudo systemctl status postfix

# Check configuration
sudo postconf | grep inet_interfaces

# Restart Postfix
sudo systemctl restart postfix
```

### Error: "Authentication failed" in email client

**Solution**: Verify SASL authentication is enabled and credentials are correct.

```bash
# Check SASL status
sudo postconf | grep smtpd_sasl

# Test authentication
testsaslauthd -u username -p password

# Check logs
sudo tail -f /var/log/mail.log | grep SASL
```

### Error: "Certificate verify failed" in email client

**Solution**: Ensure SSL certificate is valid and properly configured.

```bash
# Check certificate
openssl x509 -in /etc/ssl/certs/mail.crt -text -noout

# Verify certificate matches domain
openssl s_client -connect localhost:993 -showcerts </dev/null 2>/dev/null | openssl x509 -noout -subject

# Use Let's Encrypt for trusted certificates
sudo apt-get install certbot
sudo certbot certonly --standalone -d mail.yourdomain.com
```

### Error: "Mailbox locked" or "Permission denied"

**Solution**: Check file permissions and ownership.

```bash
# Fix mail directory permissions
sudo chown -R vmail:vmail /var/mail
sudo chmod -R 770 /var/mail

# Check SELinux (RHEL)
sudo setsebool -P nis_enabled 1
```

### Error: "550 5.7.1 Relay access denied"

**Solution**: Configure relay access or authenticate before sending.

```bash
# Enable submission
sudo postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
sudo systemctl restart postfix

# Or use authentication in email client
# Enable "Outgoing server requires authentication"
```

### Error: "User unknown" in virtual mailbox setup

**Solution**: Verify virtual mailbox configuration and rebuild lookup tables.

```bash
# Check virtual mailbox maps
sudo postmap -q user@domain.com hash:/etc/postfix/virtual_mailbox

# Rebuild lookup tables
sudo postmap /etc/postfix/virtual_domains
sudo postmap /etc/postfix/virtual_mailbox
sudo postmap /etc/postfix/virtual_alias

# Restart Postfix
sudo systemctl restart postfix
```

### Error: "Dovecot: imap-login: Disconnected" in logs

**Solution**: Check authentication configuration and SSL settings.

```bash
# Check Dovecot logs
sudo tail -f /var/log/mail.log | grep dovecot

# Verify SSL configuration
sudo doveconf -a | grep ssl

# Test authentication
doveadm auth test username password
```

## References

- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [Dovecot Documentation](https://doc.dovecot.org/)
- [Ubuntu Mail Server Guide](https://help.ubuntu.com/lts/serverguide/postfix.html)
- [Red Hat Postfix Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/setting_up_and_managing_mail/setting-up-postfix_monitoring-and-managing-mail)
- [Let's Encrypt Certificates](https://letsencrypt.org/getting-started/)
- [Email Security Best Practices](https://www.postfix.org/SECURITY_README.html)
- [SPF/DKIM/DMARC Setup](https://support.google.com/a/answer/174124?hl=en)
