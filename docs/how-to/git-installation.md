# Git Installation on Linux

## Purpose

Install Git on Linux systems using the official source, package managers, or PPA. This guide covers automated installation and version management for Debian-based, RHEL-based, and Fedora distributions.

## When to use

- Setting up a new Linux system with Git
- Upgrading an existing Git installation to the latest stable version
- Installing a specific Git version for compatibility testing
- Implementing Git in a CI/CD pipeline

## Prerequisites

### Package Requirements
- `curl` or `wget` for downloading packages
- `build-essential` (for source builds on Debian)
- `make`, `gcc` (for source builds)
- Root or sudo access

### Supported Distributions
- Ubuntu 20.04 LTS and later
- Debian 11 and later
- AlmaLinux 9.x
- RHEL 9.x
- Fedora 38 and later

## Steps

### 1. Automated Installation (Recommended)

```bash
# Download and run the automation script
curl -sL https://raw.githubusercontent.com/your-repo/main/scripts/bash/git/git-install.sh | sudo bash
```

### 2. Install Specific Version

```bash
# From source (for any Linux)
sudo ./git-install.sh --version 2.45.0
```

### 3. Install on Ubuntu/Debian

```bash
# Using PPA (recommended)
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git

# Or use the script
sudo ./git-install.sh
```

### 4. Install on AlmaLinux/RHEL

```bash
# Using EPEL
sudo dnf install git

# Or use the script
sudo ./git-install.sh
```

### 5. Build from Source

```bash
# Download specific version from source
./git-install.sh --version 2.45.0 --from-source
```

## Verify

### Check Git Installation

```bash
# Verify Git is installed
git --version

# Expected output: git version 2.45.0

# Verify paths
which git
# /usr/bin/git or /usr/local/bin/git

# Check configuration
git config --list --show-origin
```

### Test Operation

```bash
# Initialize a test repository
mkdir -p /tmp/git-test && cd /tmp/git-test
git init
echo "test" > test.txt
git add test.txt
git commit -m "Initial commit"
git log

# Clean up
cd / && rm -rf /tmp/git-test
```

## Rollback

### Remove Git

```bash
# Debian/Ubuntu
sudo apt-get remove git

# AlmaLinux/RHEL
sudo dnf remove git

# From source (/usr/local)
sudo rm -f /usr/local/bin/git
sudo rm -f /usr/local/libexec/git-core/*
sudo rm -rf /usr/local/share/doc/git
```

## Common errors

### "add-apt-repository: command not found"

**Problem:** `add-apt-repository` is not installed.

**Solution:**
```bash
sudo apt-get install software-properties-common
```

### "make: command not found"

**Problem:** Build tools not installed.

**Solution:**
```bash
# Debian/Ubuntu
sudo apt-get install build-essential

# RHEL/AlmaLinux
sudo dnf groupinstall "Development Tools"
```

### "fatal: unsafe repository"

**Problem:** Git refuses to use the repository due to ownership.

**Solution:**
```bash
sudo chown -R $(whoami) .
git config --global --add safe.directory '*'
```

## References

- Official Git Installation: https://github.com/git/git/tree/master/contrib/buildsystems
- Git Downloads: https://github.com/git/git/releases
- Pro Git Book: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git