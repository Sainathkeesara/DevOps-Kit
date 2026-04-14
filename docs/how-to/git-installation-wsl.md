# Git Installation on WSL (Windows Subsystem for Linux)

## Purpose

Install and configure Git on Windows Subsystem for Linux (WSL) running Ubuntu, Debian, or Kali Linux. This guide covers automated installation, version management, and post-install configuration for WSL developers.

## When to use

- Setting up Git on a new WSL installation
- Upgrading Git to the latest version on WSL
- Configuring Git credentials and SSH keys on WSL
- Integrating Git with Windows authentication on WSL

## Prerequisites

- Windows 10 version 2004 or later (Build 19041+)
- WSL 2 installed and configured
- One of: Ubuntu 20.04+, Debian 11+, Kali Linux
- sudo privileges for package installation

## Steps

### 1. Verify WSL is running

```bash
wsl.exe -l -v
```

Ensure VERSION is 2.

### 2. Update package lists

```bash
sudo apt update && sudo apt upgrade -y
```

### 3. Run the installation script

```bash
chmod +x /path/to/git-install-wsl.sh
./git-install-wsl.sh
```

Options:
```bash
./git-install-wsl.sh --upgrade    # Upgrade to latest version
./git-install-wsl.sh --dry-run   # Preview without executing
```

### 4. Verify installation

```bash
git --version
which git
```

Expected: `git version 2.x.x`

### 5. Configure Git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 6. Configure credential caching

```bash
git config --global credential.helper cache
git config --global credential.helper store  # Persist for longer
```

### 7. Configure line endings for cross-platform compatibility

```bash
git config --global core.autocrlf input  # For Linux/WSL
```

### 8. Set default branch name

```bash
git config --global init.defaultBranch main
```

## Verify

### Check Git version

```bash
git --version
```

Output should show Git 2.40 or later.

### Check Git path

```bash
which git
```

Should show `/usr/bin/git` or `/usr/local/bin/git`.

### Test configuration

```bash
git config --list
git config --global --list
```

### Test repository creation

```bash
cd /tmp
mkdir test-repo && cd test-repo
git init
git status
rm -rf /tmp/test-repo
```

## Rollback

### Remove Git

```bash
sudo apt remove --purge git
sudo apt autoremove
```

### Reinstall from system packages

```bash
sudo apt update
sudo apt install git
```

## Common errors

### "add-apt-repository: command not found"

**Problem:** software-properties-common not installed.

**Solution:**
```bash
sudo apt install software-properties-common
```

### "Git version still old after upgrade"

**Problem:** PPA not added or package not refreshed.

**Solution:**
```bash
sudo add-apt-repository ppa:git-core/ppa
sudo apt update
sudo apt install git --upgrade
```

### "Credentials not cached between sessions"

**Problem:** WSL credential helper not configured.

**Solution:**
```bash
git config --global credential.helper /mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe
```

### "Permission denied pushing to GitHub"

**Problem:** SSH key not configured.

**Solution:**
```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
# Add public key to GitHub
cat ~/.ssh/id_ed25519.pub
```

### "Line ending differences on Windows"

**Problem:** core.autocrlf not set.

**Solution:**
```bash
git config --global core.autocrlf input
```

## References

- WSL Installation: https://docs.microsoft.com/en-us/windows/wsl/install
- Git on WSL: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
- Git Credential Manager: https://github.com/GitCredentialManager/git-credential-manager
- WSL Interop: https://learn.microsoft.com/en-us/windows/wsl/interop
