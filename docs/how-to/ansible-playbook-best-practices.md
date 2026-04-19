# Ansible Playbook Best Practices Guide

A guide to writing production-ready Ansible playbooks

## Purpose
This guide covers best practices for writing maintainable, secure, and efficient Ansible playbooks in production environments.

## When to use
- Starting a new Ansible project
- Reviewing existing playbooks
- Setting up Ansible in a production environment

## Prerequisites
- Ansible 2.9+ installed
- Python 3.8+
- Access to target hosts via SSH

## Best Practices

### 1. Project Structure
```
ansible-project/
├── inventory/
│   └── production/
├── group_vars/
│   └── all.yml
├── host_vars/
├── playbooks/
├── roles/
└── ansible.cfg
```

### 2. Use ansible.cfg Properly
```ini
[defaults]
inventory = inventory/production
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

### 3. Always Use IDempotent Plays
```yaml
- name: Ensure Apache is installed
  apt:
    name: apache2
    state: present
  # state: present ensures idempotency
```

### 4. Use Handlers Properly
```yaml
- name: Restart Apache
  service:
    name: apache2
    state: restarted
  notify: Restart Apache
```

### 5. Secure Credential Handling
```yaml
# NEVER do this
vars:
  db_password: "plaintextpassword"

# DO this instead
vars:
  db_password: "{{ vault_db_password }}"
vault_encrypted_files:
  - group_vars/all/vault.yml
```

### 6. Use Tags
```yaml
- name: Deploy application
  import_playbook: deploy.yml
  tags:
    - deploy
    - web
```

### 7. Check Mode (Dry Run)
```bash
ansible-playbook site.yml --check
```

### 8. Diff Mode
```bash
ansible-playbook site.yml --diff
```

### 9. Use Parallelism Wisely
```bash
# Run 10 hosts at a time
ansible-playbook site.yml --forks 10
```

### 10. Logging and Verbosity
```bash
# Verbose output
ansible-playbook site.yml -vvv

# Log to file
ansible-playbook site.yml >> /var/log/ansible.log 2>&1
```

## Verify

### Syntax Check
```bash
ansible-playbook --syntax-check site.yml
```

### List Tasks
```bash
ansible-playbook site.yml --list-tasks
```

### List Hosts
```bash
ansible-playbook site.yml --list-hosts
```

### Dry Run with Changes
```bash
ansible-playbook site.yml --check --diff
```

## Rollback

### Using Version Control
```bash
git diff HEAD~1 playbooks/site.yml
git rollback playbooks/site.yml
```

### Using Checkpoint
```bash
# Before running
ansible-playbook site.yml --checkpoint=1

# To rollback
ansible-playbook site.yml --start-at-task="Deploy application"
```

## Common Errors

### Error: "FAILED! => ... become: false"
**Solution**: Add `become: True` to play or task

### Error: "FAILED! => ... ssh: handshake failed"
**Solution**: Add `host_key_checking = False` to ansible.cfg

### Error: "FAILED! => ... timed out waiting for module completion"
**Solution**: Increase `async` and `poll` values

### Error: "No inventory was able to be parsed"
**Solution**: Check inventory file syntax and path in ansible.cfg

### Error: "cryptography is required"
**Solution**: `pip install cryptography`

## References
- https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html
- https://galaxy.ansible.com/docs/