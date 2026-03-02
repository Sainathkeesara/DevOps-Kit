# Glossary & Standards

Definitions and quality standards used throughout this repository.

## Doc Standard

Every document must include these sections:

```
# Title
## Purpose
## When to use
## Prerequisites
## Steps
## Verify
## Rollback (if applicable)
## Common errors
## References (plain-text links)
```

## Script Standard

All scripts must include:

- Header comment: purpose, usage, requirements, safety notes
- Safe defaults + guardrails (fail-fast, input validation)
- Dry-run mode for any risky operations
- Logging and clear error messages
- Bash scripts: `set -euo pipefail`
- Python scripts: `argparse`, structured error handling
- Shared helpers in `scripts/lib/` (logging, retry, config parsing)

## Tool Development Pattern

Each toolkit consists of:
- Scripts under `scripts/<lang>/<tool_name>/`
- How-to guide in `docs/how-to/<tool_name>.md`
- Snippets file updates in `snippets/<category>.md`

## Tool Execution Rules

- Implement ONE toolkit per run (from TOOL LIST)
- Update quick-links and changelog on every change
- Never commit directly to master
- Follow the PR protocol for each run

## Template Conventions

- Use Jinja2-like placeholders: `{{ variable_name }}`
- Keep templates minimal and documented
- Include example usage in README files
