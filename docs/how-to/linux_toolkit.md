# linux_toolkit

## Purpose

Provides essential Linux system administration scripts for DevOps engineers to monitor, diagnose, and manage Linux servers efficiently.

## When to use

- Performing routine system health checks
- Debugging performance issues
- Managing services and processes
- Network diagnostics
- Security auditing

## Prerequisites

- Bash 4.0+
- Linux system with standard utilities (ps, ss, df, free, etc.)
- Root/sudo access for certain operations (service restart, process kill)

## Steps

### System Health Monitoring

Run comprehensive system health check:
```bash
./scripts/bash/linux_toolkit/system/health-check.sh
```

Customize thresholds:
```bash
CPU_THRESHOLD=70 MEM_THRESHOLD=85 ./scripts/bash/linux_toolkit/system/health-check.sh
```

Analyze disk usage:
```bash
./scripts/bash/linux_toolkit/system/disk-usage.sh
```

### Service Management

List failed systemd services (requires root):
```bash
sudo ./scripts/bash/linux_toolkit/service/manage-services.sh list-failed
```

Check service status:
```bash
./scripts/bash/linux_toolkit/service/manage-services.sh status nginx
```

Restart a service (requires root):
```bash
sudo DRY_RUN=true ./scripts/bash/linux_toolkit/service/manage-services.sh restart nginx
```

### Network Diagnostics

Run full network diagnostics:
```bash
./scripts/bash/linux_toolkit/network/net-diag.sh
```

Check specific network aspects:
```bash
./scripts/bash/linux_toolkit/network/net-diag.sh interfaces
./scripts/bash/linux_toolkit/network/net-diag.sh ports
./scripts/bash/linux_toolkit/network/net-diag.sh dns
./scripts/bash/linux_toolkit/network/net-diag.sh ping google.com
```

Test specific port:
```bash
./scripts/bash/linux_toolkit/network/net-diag.sh port localhost 22
```

### Process Management

List top processes by CPU/memory:
```bash
./scripts/bash/linux_toolkit/process/process-manager.sh top
```

Find processes by pattern:
```bash
./scripts/bash/linux_toolkit/process/process-manager.sh find nginx
```

Kill process (requires root):
```bash
sudo DRY_RUN=true ./scripts/bash/linux_toolkit/process/process-manager.sh kill 12345
```

Kill by pattern (requires root):
```bash
sudo DRY_RUN=true ./scripts/bash/linux_toolkit/process/process-manager.sh kill-pattern "python.*worker"
```

View process tree:
```bash
./scripts/bash/linux_toolkit/process/process-manager.sh tree 1
```

### Security Check

Run security audit:
```bash
./scripts/bash/linux_toolkit/security/security-check.sh
```

## Verify

All scripts return exit code 0 on success, non-zero on failure. Use `set -euo pipefail` in your scripts that call these utilities.

Test dry-run mode:
```bash
DRY_RUN=true ./scripts/bash/linux_toolkit/service/manage-services.sh restart nginx
# Should print what would happen without making changes
```

## Rollback

These scripts are read-only diagnostics or use systemd for service management which has built-in rollback via `systemctl reset-failed`.

## Common errors

- "systemctl not available": Not running on a systemd-based Linux
- "must be run as root": Use `sudo` for privileged operations
- "Process does not exist": PID already terminated
- "Cannot read auth.log": Insufficient permissions

## References

- [systemd documentation](https://www.freedesktop.org/wiki/Software/systemd/)
- [Linux man pages](https://man7.org/linux/man-pages/)
- [ss command替代netstat](https://access.redhat.com/solutions/175643)
- [Linux monitoring best practices](https://tuxcare.com/blog/linux-monitoring/)
