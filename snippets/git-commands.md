# Git CLI Commands Reference

A comprehensive reference for common Git operations for developers and system administrators.

## Repository Operations

### Initialize and Clone

```bash
git init                              # Initialize new repository
git init --bare                      # Create bare repository (for servers)
git clone <url>                      # Clone repository
git clone <url> <directory>          # Clone to specific directory
git clone --depth 1 <url>            # Shallow clone (latest commit only)
git clone --branch <branch> <url>    # Clone specific branch
```

### Configuration

```bash
git config --global user.name "Name"         # Set username
git config --global user.email "email"       # Set email
git config --global --list                    # List all config
git config --global core.editor vim          # Set default editor
git config --global init.defaultBranch main  # Set default branch name
```

### Basic Operations

```bash
git status                              # Show working tree status
git status -s                           # Short format status
git add <file>                          # Stage specific file
git add .                               # Stage all changes
git add -p                              # Stage interactively (patch)
git commit -m "message"                 # Commit staged changes
git commit -am "message"               # Stage and commit tracked files
git commit --amend                      # Modify last commit
git commit --amend --no-edit            # Amend without changing message
git diff                                 # Show unstaged changes
git diff --staged                        # Show staged changes
git diff HEAD~1 HEAD                    # Show changes between commits
git diff <branch1> <branch2>           # Compare branches
git restore <file>                     # Discard unstaged changes
git restore --staged <file>             # Unstage file
```

### Branching and Merging

```bash
git branch                              # List local branches
git branch -r                          # List remote branches
git branch -a                          # List all branches
git branch <name>                      # Create new branch
git branch -d <name>                    # Delete branch (merged)
git branch -D <name>                   # Force delete branch
git checkout <branch>                  # Switch to branch
git checkout -b <branch>               # Create and switch
git switch <branch>                     # Switch to branch (modern)
git switch -c <branch>                  # Create and switch (modern)
git merge <branch>                      # Merge branch into current
git merge --no-ff <branch>               # Merge with no fast-forward
git merge --abort                       # Abort merge in progress
git rebase <branch>                     # Rebase onto branch
git rebase -i HEAD~N                     # Interactive rebase (last N commits)
```

### Remote Operations

```bash
git remote -v                          # Show remotes
git remote add origin <url>             # Add remote
git remote remove origin                # Remove remote
git fetch origin                        # Fetch without merging
git pull origin <branch>                # Fetch and merge
git push origin <branch>                # Push to remote
git push -u origin <branch>              # Push and set upstream
git push origin --delete <branch>       # Delete remote branch
git push origin --tags                   # Push all tags
```

### Stashing

```bash
git stash                               # Stash unstaged changes
git stash -u                            # Stash including untracked
git stash list                          # List stashes
git stash pop                           # Apply and remove latest stash
git stash apply                        # Apply latest stash (keep stash)
git stash drop                          # Delete latest stash
git stash clear                         # Delete all stashes
```

### Tagging

```bash
git tag                                 # List tags
git tag <name>                          # Create lightweight tag
git tag -a <name> -m "message"          # Create annotated tag
git tag -a <name> <commit>             # Tag specific commit
git tag -d <name>                       # Delete local tag
git push origin <tag>                   # Push tag to remote
git push origin --delete <tag>          # Delete remote tag
```

### Viewing History

```bash
git log                                 # Show commit history
git log --oneline                       # One line per commit
git log --oneline -n <N>                # Last N commits
git log --graph --oneline               # Graph view
git log --author="name"                 # Filter by author
git log --since="2024-01-01"            # Filter by date
git log --grep="keyword"                # Filter by commit message
git log -p <file>                       # Show file history
git log --follow <file>                 # Follow file renames
git show <commit>                       # Show commit details
git show <commit>:path                  # Show file at commit
```

### Resetting and Reverting

```bash
git reset --soft HEAD~1                # Undo commit (keep changes staged)
git reset --mixed HEAD~1               # Undo commit (keep changes unstaged)
git reset --hard HEAD~1                # Undo commit (discard changes)
git reset <file>                        # Unstage file (keep changes)
git revert <commit>                     # Create new commit undoing changes
git revert --no-commit <commit>        # Stage revert without committing
```

### Working with Files

```bash
git rm <file>                          # Remove file from working tree and index
git rm --cached <file>                 # Remove from index only
git mv <old> <new>                     # Rename/move file
git checkout -- <file>                  # Discard changes to file
git checkout <commit> -- <file>        # Restore file from commit
git ls-files                            # List tracked files
```

### Cleanup

```bash
git clean                               # Remove untracked files (dry run)
git clean -f                            # Remove untracked files
git clean -fd                           # Remove untracked files and dirs
git gc                                  # Garbage collection
git prune                               # Prune unreachable objects
```

### Advanced

```bash
git bisect start                       # Start binary search
git bisect bad                          # Mark current commit as bad
git bisect good <commit>                # Mark known good commit
git bisect reset                       # End bisect
git cherry-pick <commit>               # Apply specific commit
git reflog                             # Show reference logs
git stash branch <name>                # Create branch from stash
```

### SSH Key Management

```bash
ssh-keygen -t ed25519 -C "email"       # Generate SSH key
ssh-agent -s                           # Start SSH agent
ssh-add ~/.ssh/id_ed25519               # Add key to agent
cat ~/.ssh/id_ed25519.pub               # Display public key
```

## One-Liners for Common Tasks

```bash
# Undo last commit, keep changes
git reset --soft HEAD~1

# Discard all local changes  
git checkout -- .

# List files changed in last N commits
git diff --name-only HEAD~N..HEAD

# Find commit that changed a file
git log --follow -p <file> | head -50

# Squash last N commits
git rebase -i HEAD~N  # change 'pick' to 'squash'

# Add forgotten files to last commit
git add <file> && git commit --amend --no-edit

# Change commit message
git commit --amend -m "new message"

# List contributors with commit count
git shortlog -sn

# Show what changed in last commit
git show --stat

# Pull with rebase instead of merge
git pull --rebase origin main

# Stage only modified files (not new)
git add -u

# Create archive of repository
git archive -o latest.zip HEAD
```
