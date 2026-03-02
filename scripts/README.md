# Scripts

Reusable automation scripts organized by language. Each script follows the [Script Standard](00_index/glossary.md#script-standard).

## Directory Structure

- `bash/` – Shell scripts for Linux/macOS environments
- `python/` – Cross-platform Python utilities
- `powershell/` – Windows PowerShell modules and scripts
- `lib/` – Shared helper libraries (logging, retry logic, config parsing)
- `examples/` – Interactive examples demonstrating script usage

## Usage Guidelines

1. Check the individual script's header for purpose, requirements, and usage
2. Most scripts support `--dry-run` for safe testing
3. Shared functions are in `scripts/lib/` – source them in bash scripts as needed
4. Python scripts use `argparse` and return appropriate exit codes

## Toolkits

Active toolkits (see [quick links](../00_index/quick-links.md)):
- **k8s_toolkit** – Safe kubectl helpers for common operations
