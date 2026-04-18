# Ansible Ad-Hoc Commands Reference

## Purpose

This snippet provides common Ansible ad-hoc commands for quick operational tasks, system administration, and troubleshooting without writing full playbooks.

## When to use

- Quick one-off operations on remote hosts
- Gathering information from multiple servers
- Simple configuration changes
- Testing connectivity and Ansible setup

## Prerequisites

- Ansible installed (`ansible` and `ansible-playbook` commands available)
- SSH access to target hosts
- Inventory file configured
- SSH key-based authentication recommended

## Command Patterns

### Connection and Ping

```bash
# Test connectivity to all hosts
ansible all -m ping

# Test connectivity with specific inventory
ansible all -i inventory.ini -m ping

# Test connectivity to a group
ansible webservers -m ping

# Test with custom user
ansible all -m ping -u <username>

# Parallel ping (faster for many hosts)
ansible all -m ping -f 10
```

### File Operations

```bash
# Copy file to remote hosts
ansible all -m copy -a "src=/local/file.txt dest=/remote/path/file.txt"

# Copy with ownership
ansible all -m copy -a "src=/local/file.txt dest=/remote/file.txt owner=app group=app mode=0644"

# Fetch file from remote hosts
ansible all -m fetch -a "src=/remote/file.txt dest=/local/backups/ flat=yes"

# Create directory
ansible all -m file -a "path=/remote/dir state=directory mode=0755"

# Change file permissions
ansible all -m file -a "path=/remote/file mode=0644"

# Create symbolic link
ansible all -m file -a "src=/remote/file dest=/remote/link state=link"
```

### Package Management

```bash
# Install package (apt)
ansible all -m apt -a "name=nginx state=present"

# Install specific version
ansible all -m apt -a "name=nginx=1.18.0 state=present"

# Update package cache and upgrade all
ansible all -m apt -a "update_cache=yes state=latest"

# Remove package
ansible all -m apt -a "name=nginx state=absent"

# Install package with yum
ansible all -m yum -a "name=httpd state=present"

# Install package with dnf
ansible all -m dnf -a "name=postgresql state=present"

# Install package with zypper
ansible all -m zypper -a "name=vim state=present"
```

### Service Management

```bash
# Start service
ansible all -m service -a "name=nginx state=started"

# Stop service
ansible all -m service -a "name=nginx state=stopped"

# Restart service
ansible all -m service -a "name=nginx state=restarted"

# Enable service on boot
ansible all -m service -a "name=nginx enabled=yes"

# Using systemd module
ansible all -m systemd -a "name=nginx state=started enabled=yes"
```

### User Management

```bash
# Create user
ansible all -m user -a "name=deployuser password={{ password_hash }} shell=/bin/bash"

# Create user with SSH key
ansible all -m user -a "name=deployuser ssh_key_bits=4096 ssh_key_comment=deployuser"

# Delete user
ansible all -m user -a "name=deployuser state=absent"

# Change user password
ansible all -m user -a "name=deployuser password={{ new_password_hash }}"
```

### Shell and Command Execution

```bash
# Run arbitrary command
ansible all -m command -a "uptime"

# Run shell command
ansible all -m shell -a "df -h | grep /data"

# Run with sudo
ansible all -m command -a "apt-get update" -b

# Run with sudo and become password
ansible all -m command -a "rm -rf /tmp/*" -b -K

# Capture command output
ansible all -m command -a "hostname" -a "register: result" -a "changed_when: false"
```

### Gathering Facts

```bash
# Gather facts about all hosts
ansible all -m setup

# Filter facts
ansible all -m setup -a "filter=ansible_*_mb"

# Show only memory facts
ansible all -m setup -a "filter=*memory*"

# Save facts to file
ansible all -m setup --tree /tmp/facts
```

### Line in File Operations

```bash
# Insert line after pattern
ansible all -m lineinfile -a "path=/etc/selinux/config line='SELINUX=enforcing' regexp='^SELINUX='"

# Remove line matching pattern
ansible all -m lineinfile -a "path=/etc/file.conf regexp='^#old-option' state=absent"

# Create file with content
ansible all -m lineinfile -a "path=/etc/rsyslog.conf line='*.* @syslog.example.com:514' create=yes"
```

### Git Operations

```bash
# Clone repository
ansible all -m git -a "repo=https://github.com/user/repo.git dest=/opt/app accept_hostkey=yes"

# Update repository
ansible all -m git -a "repo=https://github.com/user/repo.git dest=/opt/app update=yes"

# Checkout specific branch
ansible all -m git -a "repo=https://github.com/user/repo.git dest=/opt/app version=develop"
```

### Database Operations (PostgreSQL Example)

```bash
# Create database
ansible all -m postgresql_db -a "name=appdb state=present"

# Create user with database
ansible all -m postgresql_user -a "name=appuser db=appdb password=pass priv=ALL"

# Grant privileges
ansible all -m postgresql_privs -a "database=appdb role=appuser privs=ALL"
```

### JSON Query with Setup

```bash
# Get IP addresses
ansible all -m setup -a "filter=ansible_default_ipv4"

# Get all network interfaces
ansible all -m setup -a "filter=ansible_interfaces"

# Get distribution
ansible all -m setup -a "filter=ansible_distribution*"
```

### Cron Jobs

```bash
# Create cron job
ansible all -m cron -a "name=sync-data minute=*/5 job='/opt/scripts/sync.sh'"

# Remove cron job
ansible all -m cron -a "name=sync-data state=absent"

# Disable cron job
ansible all -m cron -a "name=sync-data disabled=yes"
```

### Selinux Operations

```bash
# Set SELinux enforcing
ansible all -m selinux -a "policy=targeted state=enforcing"

# Set SELinux permissive
ansible all -m selinux -a "policy=targeted state=permissive"

# Configure SELinux boolean
ansible all -m seboolean -a "name=httpd_can_network_connect state=yes persistent=yes"
```

### Debug and Troubleshooting

```bash
# Debug variable
ansible all -m debug -a "msg='The variable value is {{ my_var }}'"

# Print all facts
ansible all -m setup | less

# Check syntax of playbook without running
ansible-playbook --syntax-check site.yml

# List all tasks without running
ansible-playbook --list-tasks site.yml

# Check which hosts match
ansible-playbook --list-hosts site.yml
```

### Inventory Management

```bash
# Run against inventory from file
ansible all -i inventory.ini -m ping

# Run against specific host
ansible 192.168.1.100 -m ping

# Run against group
ansible webservers -m ping

# Run against multiple groups
ansible webservers:databases -m ping

# Run against hosts not in a group
ansible '!databases' -m ping
```

### Tag Operations

```bash
# Run only tasks with specific tag
ansible-playbook site.yml --tags=deploy

# Skip specific tags
ansible-playbook site.yml --skip-tags=debug

# List available tags
ansible-playbook site.yml --list-tags
```

## Verify

After running commands, verify:
- All hosts responded successfully
- Expected changes were made
- No errors in output (`failed=0`)
- Changed count matches expectations

## Rollback

- For idempotent operations, re-run with `state=absent` or opposite parameters
- Some changes (like user deletion) may not be reversible
- Use `-check` mode first to preview changes without executing

## Common Errors

| Error | Solution |
|-------|----------|
| `SSH ERROR: permission denied` | Check SSH key and user permissions |
| `hosts pattern found no matches` | Verify inventory file and host names |
| `FAILED! => {"msg": "module not found"}` | Install required Ansible modules |
| `apt-get: NOEXECVE` | Update apt and retry |
| `missing required arguments` | Check module syntax and required parameters |

## References

- [Ansible Ad-Hoc Command Guide](https://docs.ansible.com/ansible/latest/user_guide/intro_adhoc.html)
- [Ansible Modules Index](https://docs.ansible.com/ansible/latest/modules/list_of_all_modules.html)
- [Ansible Inventory Guide](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html)
