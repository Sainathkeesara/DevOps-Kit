# Linux Automated Patching with Ansible

## Purpose

Deploy an automated patch management system using Ansible to maintain security and stability across Linux servers. This guide covers Ansible controller setup, inventory configuration, patch playbooks, scheduling, and reporting.

## When to use

- Maintaining security compliance across multiple Linux servers
- Automating routine security patch deployment
- Ensuring consistent patch levels across production environments
- Meeting compliance requirements (PCI-DSS, SOC 2, HIPAA)
- Reducing manual intervention in patch management
- Implementing change management for system updates

## Prerequisites

- Ansible controller: Ubuntu 22.04+, RHEL 9+, or macOS
- Target servers: Ubuntu 20.04+, RHEL 8+, CentOS 8+
- SSH access with sudo privileges to all target hosts
- Python 3.8+ on controller and targets
- Network access from controller to target hosts on port 22

## Steps

### Step 1: Install Ansible on Controller

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# RHEL/CentOS
sudo yum install -y epel-release
sudo yum install -y ansible

# macOS
brew install ansible
```

Verify installation:
```bash
ansible --version
```

### Step 2: Create Project Directory Structure

```bash
mkdir -p ~/ansible-patching/{inventory,playbooks,roles,scripts}
cd ~/ansible-patching
```

### Step 3: Configure Inventory

Create `inventory/production.ini`:

```ini
[webservers]
web01.example.com ansible_host=192.168.1.10
web02.example.com ansible_host=192.168.1.11
web03.example.com ansible_host=192.168.1.12

[databases]
db01.example.com ansible_host=192.168.1.20
db02.example.com ansible_host=192.168.1.21

[appservers]
app01.example.com ansible_host=192.168.1.30
app02.example.com ansible_host=192.168.1.31

[production:children]
webservers
databases
appservers

[production:vars]
ansible_user=admin
ansible_python_interpreter=/usr/bin/python3
ansible_become=yes
ansible_become_method=sudo
```

### Step 3b: Configure Ansible Settings

Create `ansible.cfg`:

```ini
[defaults]
inventory = inventory/production.ini
roles_path = roles
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

### Step 4: Create Patch Management Playbook

Save to `playbooks/patch-management.yml`:

```yaml
---
- name: Linux Patch Management
  hosts: "{{ limit_hosts | default('all') }}"
  become: yes
  gather_facts: yes
  vars:
    dry_run: "{{ dry_run | default(true) | bool }}"
    patch_bundle: "{{ patch_bundle | default('critical') }}"

  tasks:
    - name: Update apt cache (Debian)
      ansible.builtin.apt:
        update_cache: yes
        cache_valid_time: 3600
      when: ansible_os_family == "Debian"

    - name: Apply critical updates (Debian)
      ansible.builtin.apt:
        upgrade: safe
        autoremove: yes
      when: 
        - ansible_os_family == "Debian"
        - patch_bundle in ['critical', 'security']

    - name: Apply security updates (RHEL)
      ansible.builtin.yum:
        security: yes
        update_only: yes
      when: ansible_os_family == "RedHat"

    - name: Reboot if required
      ansible.builtin.reboot:
        reboot_timeout: 600
      when: ansible_reboot_needed | default(false)
```

### Step 5: Test Connectivity

```bash
# Ping all hosts
ansible all -m ping

# Gather facts from one group
ansible webservers -m setup
```

### Step 6: Run Patch Simulation (Dry-Run)

```bash
# Test run without making changes
ansible-playbook playbooks/patch-management.yml --check --diff

# Or using the script
./scripts/bash/linux_toolkit/security/ansible-patch-management.sh --dry-run
```

### Step 7: Execute Patch Deployment

```bash
# Apply critical patches only
ansible-playbook playbooks/patch-management.yml \
  -e "patch_bundle=critical" \
  -e "dry_run=false"

# Apply all security updates
ansible-playbook playbooks/patch-management.yml \
  -e "patch_bundle=security" \
  -e "dry_run=false"
```

### Step 8: Schedule Automatic Patching

Create cron job for weekly patching:

```bash
# Add to crontab
crontab -e

# Schedule: Sundays at 2 AM
0 2 * * 0 /usr/bin/ansible-playbook /home/admin/ansible-patching/playbooks/patch-management.yml -e "patch_bundle=critical" >> /var/log/ansible-patch.log 2>&1
```

Or use systemd timers:

```bash
# Create systemd service
sudo cat > /etc/systemd/system/ansible-patching.service << EOF
[Unit]
Description=Ansible Patch Management

[Service]
Type=oneshot
User=root
WorkingDirectory=/home/admin/ansible-patching
ExecStart=/usr/bin/ansible-playbook playbooks/patch-management.yml -e "patch_bundle=critical"
EOF

# Create systemd timer
sudo cat > /etc/systemd/system/ansible-patching.timer << EOF
[Unit]
Description=Run Ansible Patching Weekly

[Timer]
OnCalendar=Sun *-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl enable --now ansible-patching.timer
```

### Step 9: Configure Patch Reporting

Create a reporting script `scripts/patch-report.sh`:

```bash
#!/bin/bash
REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="/var/log/patch-report-${REPORT_DATE}.txt"

{
    echo "Patch Management Report - $REPORT_DATE"
    echo "========================================"
    echo ""
    
    echo "Server Inventory:"
    ansible all --list-hosts
    echo ""
    
    echo "Last Patch Status:"
    ansible all -m setup -a "filter=ansible_date_time" | grep ansible_date_time
    echo ""
    
    echo "Security Updates Available:"
    ansible all -m shell -a "apt-get -s upgrade 2>/dev/null | grep -i security | wc -l"
} > "$REPORT_FILE"

# Email report
mail -s "Weekly Patch Report - $REPORT_DATE" admin@example.com < "$REPORT_FILE"
```

### Step 10: Implement Patch Rollback Strategy

Create rollback playbook `playbooks/patch-rollback.yml`:

```yaml
---
- name: Patch Rollback
  hosts: "{{ target_host }}"
  become: yes
  tasks:
    - name: List installed packages before rollback
      ansible.builtin.shell: |
        dpkg --list > /tmp/packages-before.txt
      register: before_list

    - name: Rollback specific package
      ansible.builtin.apt:
        name: "{{ package_name }}"
        state: previous
      when: package_name is defined
```

## Verify

1. Check Ansible connectivity:
```bash
ansible all -m ping
```

2. Verify dry-run results:
```bash
ansible-playbook playbooks/patch-management.yml --check
```

3. Confirm patch application:
```bash
# Check last patch date
ansible all -m shell -a "stat /var/cache/apt/archives"

# Verify security packages
ansible all -m shell -a "dpkg --list | grep -i security"
```

4. Test emergency rollback:
```bash
ansible-playbook playbooks/patch-rollback.yml -e "target_host=web01.example.com"
```

## Rollback

### Manual Rollback of Last Update

```bash
# On target host
sudo apt-get remove --purge <package>
sudo apt-get install <package>=<previous-version>
```

### Full System Restore

```bash
# Using backup
sudo apt-get update
sudo apt-get install --reinstall <package>
```

### Emergency Recovery

If system becomes unstable:

```bash
# Boot into previous kernel
sudo reboot

# Select "Advanced options" -> previous kernel
# Or use: sudo grub-reboot "1>"
```

## Common errors

### Error: "sudo: a terminal is required"

**Symptom:** `sudo: a terminal is required to run sudo`

**Solution:** Configure passwordless sudo for Ansible user:
```bash
sudo visudo
# Add: admin ALL=(ALL) NOPASSWD: ALL
```

### Error: "apt cache is locked"

**Symptom:** `Could not get lock /var/lib/apt/lists/lock`

**Solution:** Wait for other apt processes to complete, or add retry logic:
```yaml
- name: Update with retry
  ansible.builtin.apt:
    update_cache: yes
  register: result
  retries: 3
  delay: 10
  until: result is succeeded
```

### Error: "No space left on device"

**Symptom:** `No space left on device` during apt-get

**Solution:** Clean up before patching:
```bash
ansible all -m shell -a "apt-get clean && rm -rf /var/lib/apt/lists/*"
ansible all -m shell -a "docker system prune -af"
```

### Error: "Kernel update requires reboot"

**Symptom:** Patch applied but system still shows vulnerable

**Solution:** Reboot after kernel updates:
```bash
ansible-playbook playbooks/patch-management.yml --tags reboot
```

### Error: "Python3 not found"

**Symptom:** `msg: python3 interpreter not found`

**Solution:** Install Python on targets:
```bash
# Via Ansible
ansible all -m raw -a "apt-get install -y python3"

# Or in playbook
- name: Install Python
  raw: test -e /usr/bin/python3 || (apt-get update && apt-get install -y python3)
```

## References

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible APT Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html)
- [Ansible Yum Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/yum_module.html)
- [Red Hat Security Updates](https://access.redhat.com/security/updates)
- [Ubuntu Security Notices](https://usn.ubuntu.com/)
- [CIS Benchmarks for Linux](https://www.cisecurity.org/benchmark/linux)
