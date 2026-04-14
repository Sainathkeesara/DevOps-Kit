# Git Installation on macOS

## Purpose

Install Git on macOS systems using Homebrew package manager. This guide covers automated installation, verification, and post-install configuration for macOS developers.

## When to use

- Setting up a new macOS machine for development
- Installing Git for the first time on macOS
- Upgrading Git to the latest version on macOS
- Configuring Git after installation

## Prerequisites

- macOS 12 (Monterey) or later
- Homebrew installed (run `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`)
- Terminal access with sudo privileges for installation

## Steps

### 1. Verify Homebrew is installed

```bash
brew --version
```

Expected output: Homebrew 4.x or later. If not installed, install from https://brew.sh

### 2. Run the installation script

```bash
chmod +x /path/to/git-install-macos.sh
./git-install-macos.sh
```

Or with options:
```bash
./git-install-macos.sh --upgrade    # Upgrade if already installed
./git-install-macos.sh --dry-run    # Preview without executing
```

### 3. Verify installation

```bash
git --version
which git
```

Expected: `git version 2.x.x` and path should be `/usr/local/bin/git` or `/opt/homebrew/bin/git`

### 4. Configure Git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 5. Configure credential caching (optional)

```bash
git config --global credential.helper cache
git config --global credential.helper osxkeychain  # For macOS Keychain
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

Should show Homebrew's Git path, not the system Git at `/usr/bin/git`.

### Test Git functionality

```bash
git config --list
git status
```

## Rollback

### Remove Git installed via Homebrew

```bash
brew uninstall git
```

### Revert to system Git (if needed)

```bash
brew uninstall git
export PATH=/usr/bin:$PATH
```

## Common errors

### "brew: command not found"

**Problem:** Homebrew is not installed.

**Solution:**
```bash
/ bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### "Git not in PATH after installation"

**Problem:** Shell hasn't picked up new Git path.

**Solution:**
```bash
source ~/.zshrc  # For Zsh
source ~/.bash_profile  # For Bash
```

Or restart terminal completely.

### "xcrun: error: invalid active developer path"

**Problem:** Xcode Command Line Tools issue.

**Solution:**
```bash
xcode-select --install
```

### "Git path points to old version"

**Problem:** System Git takes precedence.

**Solution:**
```bash
export PATH="$(brew --prefix)/bin:$PATH"
echo 'export PATH="$(brew --prefix)/bin:$PATH"' >> ~/.zshrc
```

## References

- Homebrew: https://brew.sh
- Git Installation: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
- Git Configuration: https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration
