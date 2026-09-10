---
last_verified: 2026-09-10
tool_version: n/a
sources: []
---

# Gitleaks — quick primer

> First-day notes for someone who's never used Gitleaks. Personal voice, plain language.

I just learned about Gitleaks. It scans git repos for secrets — API keys, passwords, tokens, that sort of thing. It's like TruffleHog but takes a different approach: pattern matching with configurable rules instead of entropy-based detection and live verification. Single Go binary, no dependencies, easy to drop into CI.

The core idea: scan every file in every commit (or just the working directory) and flag anything matching a secret pattern. Ships with built-in rules for common stuff (AWS keys, GitHub tokens, private keys) and lets you add custom rules via TOML config.

## What does it do?

Main use cases: pre-commit hook to catch secrets before they enter history, CI check on PRs to catch them before merge, or full repo audit for legacy codebases. The `protect` mode runs as a pre-push hook and blocks pushes with secrets.

When it finds a match, it reports the file, line, matched rule, and a redacted version of the secret. You get JSON output for CI integration, or just terminal output for quick checks.

## Why does it exist?

Secrets leaking into git history is one of the most common security incidents. Developers commit `.env` files, paste API keys into config, or include credentials in code snippets. Once committed, even deleting the file doesn't help — the secret is still in every previous commit.

Gitleaks catches these at the earliest moment. Pre-commit catches before commit, CI catches before merge, full scan catches in old repos. The allowlist is key — you need to tell it about test credentials, placeholder values, and known false positives or it'll flood you with noise.

## Key terminology

- **Rule** — TOML-defined pattern matching a specific secret type. Has a regex, description, tags, severity. Example: AWS access keys matching `AKIA[0-9A-Z]{16}`.
- **Allowlist** — Patterns or files Gitleaks skips. Essential for test files, docs examples, known false positives. Configured in `.gitleaks.toml`.
- **Entropy** — Randomness score. Filters out low-entropy strings that match a regex but aren't real secrets.
- **`gitleaks detect`** — Main scan command. Scans git history by default, filesystem with `--source`.
- **`gitleaks protect`** — Pre-commit/pre-push mode. Scans staged changes, blocks if secrets found.
- **Baseline** — Previous scan output that new scans compare against. Only new findings get reported.

## A tiny example

```bash
gitleaks detect --source ./my-repo --report-path results.json
```

Scans entire git history of `./my-repo`, writes findings to `results.json`. Downloads default ruleset on first run.

Pre-commit hook:

```bash
gitleaks protect --staged
```

Scans staged changes, exits non-zero if secret found, blocks the commit.

## What I'll cover next

I'll install it, run it against a test repo with planted secrets, and see the output. Then try custom rules and allowlist config for a realistic project.
