# Linux Container Host Setup with Docker and Security Hardening

## Purpose

This guide explains how to set up a Linux system as a secure container host running Docker. It covers OS preparation, Docker installation, and security hardening measures to protect the host from container escapes and unauthorized access.

## When to Use

Use this guide when you need to:
- Set up a dedicated Linux server to run Docker containers in production
- Harden an existing Docker host against common attack vectors
- Implement defense-in-depth for container workloads
- Meet compliance requirements for container infrastructure
- Configure kernel-level security controls for containers

## Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04/22.04, Debian 11/12, RHEL 8/9, AlmaLinux 9, Rocky Linux 9
- **Architecture**: x86_64 or ARM64
- **RAM**: 4GB minimum (8GB+ recommended for production)
- **CPU**: 2+ cores
- **Disk**: 50GB+ available space (depends on container needs)
- **Network**: Static IP recommended for production

### Required Privileges
- Root or sudo access for installation and configuration
- Ability to modify kernel parameters
- Access to configure firewall rules

### Knowledge Prerequisites
- Basic Linux system administration
- Understanding of Docker concepts (containers, images, volumes, networking)
- Familiarity with command-line operations

## Steps

### Step 1: Prepare the Operating System

Update the system and install required packages:

```bash
# Update package lists and upgrade
sudo apt-get update && sudo apt-get upgrade -y

# Install required utilities
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq \
    auditd \
    fail2ban \
    ufw

# Check current kernel version
uname -r
```

For RHEL/CentOS:
```bash
sudo dnf update -y
sudo dnf install -y curl jq audit firewalld fail2ban
```

### Step 2: Configure Kernel Security Parameters

Create a sysctl configuration file for container security:

```bash
sudo tee /etc/sysctl.d/99-container-security.conf << 'EOF'
# Kernel hardening for container hosts

# Disable unused filesystems
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1

# Network security
net.ipv4.conf.all.forwarding = 0
net.ipv4.conf.default.forwarding = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# IP forwarding disabled for container bridge
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-arptables = 1

# Memory and process limits
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 2
kernel.panic = 10
kernel.panic_on_oops = 1

# User namespace limits
user.max_user_namespaces = 0
EOF

# Apply the configuration
sudo sysctl -p /etc/sysctl.d/99-container-security.conf
```

### Step 3: Install Docker

Install Docker from official repositories:

```bash
# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation
sudo docker --version
sudo docker run --rm hello-world
```

Configure Docker daemon for security:

```bash
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "icc": false,
  "ip-masq": true,
  "ipv6": false,
  "log-driver": "journald",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "metrics-addr": "127.0.0.1:9323",
  "storage-driver": "overlay2",
  "userland-proxy": false,
  "live-restore": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  },
  "default-cgroupns-mode": "host",
  "exit-on-return": false,
  "seccomp-profile": "",
  "default-address-pools": [
    {
      "base": "172.17.0.0/16",
      "size": 24
    }
  ]
}
EOF

# Create Docker config directory for systemd drop-in
sudo mkdir -p /etc/systemd/system/docker.service.d

# Reload systemd and restart Docker
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker

# Verify Docker is running
sudo systemctl status docker
```

### Step 4: Configure Docker Authorization

Set up Docker authorization plugins:

```bash
# Create Docker authorization config
sudo tee /etc/docker/policy.json << 'EOF'
{
  "defaultAllow": false,
  "rules": [
    {
      "type": "capability",
      "capabilities": ["CHOWN", "DAC_OVERRIDE", "FSETID", "FOWNER", "MKNOD", "NET_RAW", "SETGID", "SETUID", "SETFCAP", "SETPCAP", "NET_BIND_SERVICE", "SYS_CHROOT", "KILL", "AUDIT_WRITE"]
    },
    {
      "type": "volume",
      "volumes": ["*"]
    },
    {
      "type": "network",
      "networks": ["bridge", "host", "none"]
    }
  ]
}
EOF
```

### Step 5: Configure Container Security

Create a default container security policy:

```bash
# Create container security script
sudo tee /usr/local/bin/docker-security.sh << 'SCRIPT'
#!/bin/bash
set -euo pipefail

CONTAINER_USER="${CONTAINER_USER:-appuser}"
CONTAINER_CAP_DROP="${CONTAINER_CAP_DROP:-ALL}"
CONTAINER_CAP_ADD="${CONTAINER_CAP_ADD:-NET_BIND_SERVICE}"
CONTAINER_NO_NEW_PRIV="${CONTAINER_NO_NEW_PRIV:-true}"

echo "Applying container security settings..."

# Default seccomp profile (Docker default)
SECCOMP_PROFILE=$(cat <<'EOF'
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_ARM64"
  ],
  "syscalls": [
    { "names": ["accept", "accept4", "access", "alarm", "bind", "brk", "capget", "capset", "chdir", "chmod", "chown", "chown32", "clock_getres", "clock_gettime", "clock_nanosleep", "close", "connect", "copy_file_range", "creat", "dup", "dup2", "dup3", "epoll_create", "epoll_create1", "epoll_ctl", "epoll_pwait", "epoll_wait", "eventfd", "eventfd2", "execve", "execveat", "exit", "exit_group", "faccessat", "faccessat2", "fadvise64", "fadvise64_64", "fallocate", "fanotify_init", "fanotify_mark", "fchdir", "fchmod", "fchmodat", "fchown", "fchownat", "fcntl", "fcntl64", "fdatasync", "fgetxattr", "flistxattr", "flock", "fstat", "fstat64", "fstatat64", "fstatfs", "fstatfs64", "fsync", "ftruncate", "ftruncate64", "futex", "getcpu", "getcwd", "getdents", "getdents64", "getegid", "geteuid", "getgid", "getgroups", "getitimer", "getpeername", "getpgid", "getpgrp", "getpid", "getppid", "getpriority", "getrandom", "getresgid", "getresuid", "getrlimit", "getrusage", "getsid", "getsockname", "getsockopt", "gettid", "gettimeofday", "getuid", "init_module", "inotify_add_watch", "inotify_init", "inotify_rm_watch", "io_cancel", "io_destroy", "io_getevents", "io_setup", "io_submit", "kill", "lchown", "lchown32", "link", "linkat", "listen", "listxattr", "llistxattr", "_llseek", "lseek", "lstat", "lstat64", "madvise", "mbind", "mincore", "mkdir", "mkdirat", "mknod", "mknodat", "mlock", "mlock2", "mlockall", "mmap", "mmap2", "mprotect", "mq_getsetattr", "mq_notify", "mq_open", "mq_timedreceive", "mq_timedsend", "mq_unlink", "msgctl", "msgget", "msgsnd", "msync", "munlock", "munlockall", "munmap", "nanosleep", "newfstatat", "open", "openat", "openat2", "pause", "pipe", "pipe2", "poll", "ppoll", "prctl", "pread64", "preadv", "prlimit64", "pselect6", "pwrite64", "pwritev", "read", "readahead", "readdir", "readlink", "readlinkat", "readv", "recv", "recvfrom", "recvmmsg", "recvmsg", "remap_file_pages", "removexattr", "rename", "renameat", "renameat2", "restart_syscall", "rmdir", "rt_sigaction", "rt_sigpending", "rt_sigprocmask", "rt_sigqueueinfo", "rt_sigsuspend", "rt_sigtimedwait", "rt_tgsigqueueinfo", "sched_getaffinity", "sched_getattr", "sched_getparam", "sched_getscheduler", "sched_rr_get_interval", "sched_setaffinity", "sched_setattr", "sched_setparam", "sched_setscheduler", "sched_yield", "seccomp", "select", "semctl", "semget", "semop", "semtimedop", "send", "sendfile", "sendfile64", "sendmmsg", "sendmsg", "sendto", "setfsgid", "setfsgid32", "setfsuid", "setfsuid32", "setgid", "setgid32", "setgroups", "setgroups32", "setitimer", "setpgid", "setpriority", "setregid", "setregid32", "setresgid", "setresgid32", "setresuid", "setresuid32", "setreuid", "setreuid32", "setrlimit", "set_robust_list", "set_thread_area", "set_tid_address", "setuid", "setuid32", "shmat", "shmctl", "shmdt", "shmget", "shutdown", "sigaltstack", "signal", "signalfd", "signalfd4", "sigpending", "sigprocmask", "sigreturn", "sigsuspend", "socketcall", "socketpair", "splice", "stat", "stat64", "statfs", "statfs64", "statx", "symlink", "symlinkat", "sync", "sync_file_range", "syncfs", "sysinfo", "syslog", "tee", "tgkill", "time", "timer_create", "timer_delete", "timer_getoverrun", "timer_gettime", "timer_settime", "times", "tkill", "truncate", "truncate64", "ugetrlimit", "umask", "uname", "unlink", "unlinkat", "unshare", "utimensat", "utimes", "vfork", "vmsplice", "wait4", "waitid", "waitpid", "write", "writev"],
    "args": [],
    "comment": "",
    "includeIndex": 0
  ]
}
EOF
echo "$SECCOMP_PROFILE" | sudo tee /etc/docker/seccomp-default.json > /dev/null

echo "Container security settings applied successfully."
SCRIPT

chmod +x /usr/local/bin/docker-security.sh
sudo /usr/local/bin/docker-security.sh
```

### Step 6: Configure Firewall for Docker

Set up UFW rules for Docker:

```bash
# Configure UFW for Docker
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp comment 'SSH'

# Allow specific container ports if needed
# sudo ufw allow 8080/tcp comment 'Web application'

# Enable UFW
sudo ufw --force enable

# Verify UFW status
sudo ufw status verbose

# Configure Docker to manage iptables
sudo systemctl restart docker
```

For firewalld (RHEL/CentOS):
```bash
sudo firewall-cmd --permanent --zone=public --add-service=ssh
sudo firewall-cmd --permanent --zone=public --add-service=docker
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
```

### Step 7: Set Up Audit Logging

Configure auditd to monitor container-related events:

```bash
# Create audit rules for container security
sudo tee /etc/audit/rules.d/docker-container.rules << 'EOF'
# Monitor Docker daemon
-w /usr/bin/docker -p wa -k docker
-w /var/lib/docker -p wa -k docker
-w /etc/docker -p wa -k docker
-w /etc/containerd -p wa -k containerd
-w /var/run/docker.sock -p wa -k docker

# Monitor container operations
-a task,always -F arch=b64 -S execve -F key=container_exec
-a exit,always -F arch=b64 -S socket -S connect -k container_network

# Monitor privileged containers
-a always,exit -F path=/usr/bin/docker -F perm=aw -F key=docker_privileged
EOF

# Reload audit rules
sudo augenrules --load
sudo systemctl restart auditd

# Check audit rules
sudo auditctl -l
```

### Step 8: Configure Resource Limits

Set up systemd limits for Docker:

```bash
# Create systemd drop-in for Docker
sudo mkdir -p /etc/systemd/system/docker.service.d

sudo tee /etc/systemd/system/docker.service.d/limits.conf << 'EOF'
[Service]
# Limit number of processes
TasksMax=infinity

# Set memory limits
MemoryMax=infinity

# CPU limits (uncomment and adjust as needed)
# CPUQuota=200%
EOF

# Reload systemd
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### Step 9: Enable Docker Content Trust

Enable Docker Content Trust for image signing:

```bash
# Enable Docker Content Trust
echo "DOCKER_CONTENT_TRUST=1" | sudo tee -a /etc/environment

# Export for current session
export DOCKER_CONTENT_TRUST=1

# Verify
echo "DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST"
```

### Step 10: Create Non-Root User for Containers

Create a dedicated user for running containers:

```bash
# Create a non-root user for containers
CONTAINER_USER="containeruser"
sudo useradd -m -s /bin/bash -G docker "$CONTAINER_USER"

# Set up sudo access for docker management (optional)
echo "$CONTAINER_USER ALL=(ALL) NOPASSWD: /usr/bin/docker" | sudo tee /etc/sudoers.d/docker-$CONTAINER_USER

# Verify user
id "$CONTAINER_USER"
groups "$CONTAINER_USER"
```

### Step 11: Implement Fail2Ban for Docker

Configure fail2ban to protect Docker:

```bash
# Create fail2ban filter for Docker
sudo tee /etc/fail2ban/filter.d/docker-auth.conf << 'EOF'
[Definition]
failregex = .*authenticate.*failure.*ip=<HOST>
            .*authentication failure.*ip=<HOST>
            .*failed login.*ip=<HOST>
ignoreregex =
EOF

# Create jail for Docker
sudo tee /etc/fail2ban/jail.d/docker.conf << 'EOF'
[docker]
enabled = true
port = 2375,2376,2377
filter = docker-auth
logpath = /var/log/docker.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

# Restart fail2ban
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
sudo fail2ban-client status
```

## Verify

### Verify Docker Installation

```bash
# Check Docker version
docker --version
docker compose version

# Check Docker system info
docker info | grep -E "Server Version|Storage Driver|Cgroup Driver|Security Options"

# Verify Docker is running
sudo systemctl is-active docker

# Test Docker with a minimal container
docker run --rm --security-opt seccomp=unconfined --security-opt apparmor=unconfined alpine:latest echo "Docker works"
```

### Verify Kernel Security Settings

```bash
# Check kernel parameters
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.conf.all.forwarding
sysctl kernel.dmesg_restrict
sysctl kernel.kptr_restrict
sysctl kernel.yama.ptrace_scope

# Verify all settings applied
sudo sysctl --system
```

### Verify Firewall Configuration

```bash
# Check UFW status
sudo ufw status

# List all rules
sudo iptables -L -n -v
sudo ip6tables -L -n -v
```

### Verify Audit Logging

```bash
# Check auditd is running
sudo systemctl status auditd

# Test audit rule
sudo auditctl -l

# Generate a test event and check logs
docker pull alpine:latest 2>/dev/null
sudo ausearch -k docker | tail -10
```

### Verify Resource Limits

```bash
# Check Docker service limits
systemctl show docker | grep -i memory
systemctl show docker | grep -i tasks

# Check container resource limits (if running)
docker stats --no-stream
```

### Verify Security Options

```bash
# Check enabled security features
docker info | grep -i "Security Options"

# List seccomp profiles
ls -la /etc/docker/seccomp-default.json

# Verify AppArmor/SELinux status
docker run --rm --rm alpine:latest cat /proc/self/attr/current
```

## Rollback

### Remove Docker Completely

```bash
# Stop Docker
sudo systemctl stop docker
sudo systemctl disable docker

# Remove Docker packages
sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-get autoremove -y

# Remove Docker directories
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
sudo rm -f /etc/containerd/config.toml

# Remove user
sudo userdel -r containeruser 2>/dev/null || true

# Clean up firewall rules
sudo ufw disable
sudo iptables -F
sudo iptables -X
```

### Restore Kernel Parameters

```bash
# Remove custom sysctl config
sudo rm /etc/sysctl.d/99-container-security.conf

# Reset to defaults
sudo sysctl --system
```

### Remove Audit Rules

```bash
# Remove audit rules
sudo rm /etc/audit/rules.d/docker-container.rules
sudo systemctl restart auditd
```

## Common Errors

### Error: "docker: permission denied while trying to connect to the Docker daemon socket"

**Solution**: Add your user to the docker group:

```bash
sudo usermod -aG docker $USER
# Log out and back in, or run:
newgrp docker
docker ps
```

### Error: "iptables failed: iptables: No chain/target/match by that name"

**Solution**: Enable IP forwarding in kernel:

```bash
sudo modprobe ip_tables
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

### Error: "failed to start daemon: error initializing graphdriver: devicemapper"

**Solution**: Use overlay2 storage driver instead:

```bash
sudo systemctl stop docker
sudo rm -rf /var/lib/docker/devicemapper
echo '{"storage-driver": "overlay2"}' | sudo tee /etc/docker/daemon.json
sudo systemctl start docker
```

### Error: "Failed to load seccomp: unexpected EOF"

**Solution**: Validate and fix the seccomp JSON:

```bash
python3 -m json.tool /etc/docker/seccomp-default.json > /dev/null && echo "Valid JSON"
# If invalid, restore default
sudo rm /etc/docker/seccomp-default.json
sudo systemctl restart docker
```

### Error: "Port is already allocated"

**Solution**: Check what's using the port and either stop that service or use a different port:

```bash
sudo ss -tlnp | grep <port>
docker ps
# Either stop the conflicting service or change the container port
```

### Error: "Error response from daemon: cannot restart container"

**Solution**: Check container logs and resource availability:

```bash
docker logs <container_id>
docker system df
# Fix the underlying issue (resource limit, configuration error, etc.)
docker restart <container_id>
```

## References

- [Docker Security Documentation](https://docs.docker.com/engine/security/)
- [Docker Daemon Security](https://docs.docker.com/engine/security/protect-access/)
- [Kernel Runtime Security Instrumentation](https://docs.docker.com/engine/security/seccomp/)
- [AppArmor Docker Security](https://docs.docker.com/engine/security/apparmor/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Docker iptables Firewall](https://docs.docker.com/network/iptables/)
- [Container Security Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/container_security_guide)
