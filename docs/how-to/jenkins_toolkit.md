# Jenkins Toolkit (jenkins_toolkit)

## Purpose

The jenkins_toolkit provides automated installation and configuration scripts for Jenkins LTS on Ubuntu 22.04. These scripts handle Java installation, repository setup, Jenkins configuration, and plugin management with idempotent execution.

## When to use

Use jenkins_toolkit scripts when you need to:
- Install Jenkins on a fresh Ubuntu 22.04 server
- Configure Jenkins port and network settings
- Install Jenkins plugins during or after installation
- Set up a reproducible Jenkins installation

Do **not** use these for production without understanding the security implications. Review the script options and ensure appropriate network access controls are in place.

## Prerequisites

- Ubuntu 22.04 (Debian-based systems may work with minor adjustments)
- Root or sudo privileges
- Internet connectivity to download packages from pkg.jenkins.io
- At least 2GB RAM recommended for Jenkins
- Port availability for Jenkins UI (default: 8080)

## Installation

No installation required. Clone the DevOps-Kit repository:

```bash
git clone <repo> devops-kit
cd devops-kit
chmod +x scripts/bash/jenkins_toolkit/*.sh
```

## Tools

### install-jenkins.sh

Automated Jenkins LTS installation with idempotent execution.

```bash
./scripts/bash/jenkins_toolkit/install-jenkins.sh [--version=<version>] [--port=<port>] [--plugins=<plugin1,plugin2>] [--dry-run] [--skip-start]
```

**Arguments:**
- `--version=<version>` - Jenkins version (optional, defaults to LTS)
- `--port=<port>` - HTTP port for Jenkins UI (default: 8080)
- `--plugins=<plugin1,plugin2>` - Comma-separated list of plugins to install
- `--dry-run` - Show what would be done without making changes
- `--skip-start` - Install and configure but don't start Jenkins

**Examples:**

Basic installation:
```bash
sudo ./scripts/bash/jenkins_toolkit/install-jenkins.sh
```

Custom port with dry-run:
```bash
sudo ./scripts/bash/jenkins_toolkit/install-jenkins.sh --port=9090 --dry-run
```

Install with common plugins:
```bash
sudo ./scripts/bash/jenkins_toolkit/install-jenkins.sh --plugins=git,docker-workflow,pipeline-utility-steps
```

## Verify

After installation, verify Jenkins is running:

```bash
systemctl status jenkins
```

Access the Jenkins UI at `http://localhost:8080` (or your configured port).

Initial admin password is available at:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Rollback

To uninstall Jenkins:

```bash
sudo systemctl stop jenkins
sudo systemctl disable jenkins
sudo apt-get remove -y jenkins
sudo rm -rf /var/lib/jenkins
sudo rm -rf /var/cache/jenkins
```

Note: This removes all Jenkins data. Backup any jobs or configurations before running.

## Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| "apt-get not found" | Not a Debian-based system | Use alternative install method |
| "Java installation failed" | Network or package issues | Check internet, run `apt-get update` manually |
| "Port already in use" | Another service on port 8080 | Use `--port` to specify different port |
| "Jenkins not starting" | Permission or configuration issue | Check logs: `journalctl -u jenkins -f` |

## References

- Jenkins LTS Package — https://pkg.jenkins.io/debian: 2026-03-08)
- Jenkins User Handbook-stable/ (verified — https://www.jenkins.io/doc/book/ (verified: 2026-03-08)
- Jenkins CLI — https://www.jenkins.io/doc/book/managing/cli/ (verified: 2026-03-08)
