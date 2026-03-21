# Git Version Control Architecture and Mental Model

## Purpose

This document explains the mental model behind Git version control, helping developers understand how Git works internally and how to use it effectively in DevOps workflows.

## When to use

- Onboarding new team members to Git-based workflows
- Understanding Git internals for better troubleshooting
- Designing branching strategies for projects
- Integrating Git with CI/CD pipelines

## Prerequisites

- Basic command-line knowledge
- Git installed locally (`git --version`)
- Understanding of file systems

## Architecture

### The Three States

Git has three main states where your files can reside:

1. **Modified** — file changed but not marked for commit
2. **Staged** — modified file marked for commit
3. **Committed** — file safely stored in local database

### The Three Sections

A Git project consists of three sections:

1. **Working Directory** — single checkout of one version
2. **Staging Area (Index)** — file list for next commit
3. **Git Directory (Repository)** — where Git stores metadata and object database

### Object Model

Git is a content-addressable filesystem with four object types:

- **Blob** — file data
- **Tree** — directory listing (pointers to blobs and other trees)
- **Commit** — pointer to tree + parent commits + author info
- **Tag** — named pointer to commit (often for releases)

```
┌─────────────────────────────────────────────────────┐
│                   Git Directory                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐  │
│  │  Blob   │  │  Tree   │  │ Commit  │  │  Tag   │  │
│  └─────────┘  └─────────┘  └─────────┘  └────────┘  │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │              Staging Area                     │    │
│  │         (Index - file list for commit)        │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
                        ▲
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│               Working Directory                       │
│              (your files on disk)                    │
└─────────────────────────────────────────────────────┘
```

### SHA-1 Hashing

Every object is identified by a 40-character SHA-1 hash:
- Unique to content
- Deterministic (same content = same hash)
- Enables content-addressable storage
- Allows efficient delta compression

Example: `e69de29bb2d1d6434b8b29ae775ad8c2e48c5391`

## Repositories

### Local Repository

A local `.git` directory contains:
- Objects (blobs, trees, commits)
- References (branches, tags)
- Configuration
- Hooks directory

```
my-project/
├── .git/
│   ├── HEAD
│   ├── config
│   ├── hooks/
│   ├── objects/
│   │   ├── info/
│   │   └── pack/
│   └── refs/
│       ├── heads/
│       └── tags/
├── src/
└── tests/
```

### Remote Repository

A shared repository on a server (GitHub, GitLab, Bitbucket):

- Central collaboration point
- Acts as "remote" in Git terminology
- Standard protocol: HTTPS or SSH

### Remote Operations

Common remote commands:

```bash
# Clone remote repository
git clone https://github.com/user/repo.git

# List remotes
git remote -v

# Add remote
git remote add origin https://github.com/user/repo.git

# Fetch changes (download, don't merge)
git fetch origin

# Pull (fetch + merge)
git pull origin main

# Push (upload commits)
git push origin main
```

## Branching

### What is a Branch?

A branch is a movable pointer to a commit. Default branch is typically `main` or `master`.

```
main:    A---B---C---D
                  │
feature:          E---F
```

### Branching Strategies

#### Feature Branch Workflow

```
main:    A---B---C---D---G---H
              │           │
feature1:    E---F       │
                      │
feature2:            I---J
```

#### Git Flow

- `main` — production-ready commits
- `develop` — integration branch
- `feature/*` — new features
- `release/*` — release preparation
- `hotfix/*` — emergency fixes

#### Trunk-Based Development

- Short-lived branches (hours/days)
- Direct commits to main with feature flags

### Branch Commands

```bash
# List branches
git branch

# Create branch (doesn't switch)
git branch feature-login

# Create and switch
git checkout -b feature-login

# Switch branch
git checkout feature-login

# Delete branch (merged)
git branch -d feature-login

# Force delete
git branch -D feature-login

# Rename branch
git branch -m old-name new-name
```

## Remote Operations

### Synchronization Flow

```
┌──────────┐     fetch      ┌──────────┐
│  Local   │ ◄───────────── │  Remote  │
│ Repo     │               │  Repo    │
└──────────┘               └──────────┘
       │                        │
       │ merge/rebase           │ push
       ▼                        ▼
┌──────────┐               ┌──────────┐
│ Working  │               │  Remote  │
│ Directory│               │  Server  │
└──────────┘               └──────────┘
```

### Push and Pull

```bash
# Push branch to remote
git push origin feature-login

# Push and set upstream
git push -u origin feature-login

# Push all branches
git push --all origin

# Pull with rebase
git pull --rebase origin main

# Force push (use with caution)
git push --force origin feature-login
```

### Tracking Branches

A local branch that has a direct relationship with a remote branch:

```bash
# Set upstream tracking
git branch -u origin/feature feature

# See tracking info
git branch -vv

# Check remote tracking
git status
```

## Verify

```bash
# Check repository status
git status

# View commit history
git log --oneline --graph --all

# View branches
git branch -a

# Check remote connections
git remote -v

# Verify object integrity
git fsck
```

## Rollback

### Undo Working Directory Changes

```bash
# Discard unstaged changes
git checkout -- file.txt

# Or using restore (Git 2.23+)
git restore file.txt
```

### Undo Staged Changes

```bash
# Unstage file
git reset HEAD file.txt

# Or using restore
git restore --staged file.txt
```

### Undo Commits

```bash
# Undo commit (keep changes staged)
git reset --soft HEAD~1

# Undo commit (keep changes unstaged)
git reset HEAD~1

# Undo commit (discard changes)
git reset --hard HEAD~1
```

### Revert vs Reset

- **Revert** — creates new commit that undoes previous
- **Reset** — moves branch pointer backward

```bash
# Revert (safe for shared history)
git revert abc123

# Reset (rewrites history - use carefully)
git reset --hard abc123
```

## Common Errors

### Merge Conflicts

```
<<<<<<< HEAD
const x = 1;
=======
const x = 2;
>>>>>>> feature-branch
```

Resolution:
1. Edit file to desired state
2. `git add <file>`
3. `git commit`

### Detached HEAD

```
Note: checking out 'abc123'.
You are in 'detached HEAD' state.
```

Solution:
```bash
# Create branch from current position
git checkout -b new-branch-name

# Or go back to main
git checkout main
```

### Push Rejected

```
! [rejected] main -> main (fetch first)
```

Solution:
```bash
# Pull and merge first
git pull origin main

# Or rebase
git pull --rebase origin main
```

### Large File Push

```
remote: error: file is 100.00 MB (max 50.00 MB)
```

Solution:
```bash
# Remove from history
git filter-branch --tree-filter 'rm -f large-file.zip' HEAD

# Or use BFG Repo-Cleaner
bfg --delete-files large-file.zip
```

## References

- Pro Git Book: https://git-scm.com/book/en/v2
- Git Internals: https://git-scm.com/book/en/v2/Git-Internals
- Atlassian Git Tutorial: https://www.atlassian.com/git
- GitHub Flow: https://docs.github.com/en/get-started/using-github/github-flow
- Git Cheat Sheet: https://education.github.com/git-cheat-sheet-education.pdf
