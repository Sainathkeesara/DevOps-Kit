# Scripts Repository

This directory contains production-ready scripts for DevOps workflows. Scripts are organized by language and include comprehensive documentation, safety features, and error handling.

## Organization

```
scripts/
├── bash/          # Shell scripts (Linux/macOS)
├── python/        # Python utilities (cross-platform)
├── powershell/    # PowerShell scripts (Windows)
├── lib/           # Shared helper libraries
└── examples/      # Example usage and demonstration scripts
```

## Standards

All scripts in this repository MUST include:

1. **Header documentation**: purpose, usage, requirements, safety notes
2. **Safe defaults**: Conservative defaults that prevent accidental harm
3. **Error handling**: Clear error messages and exit codes
4. **Dry-run mode**: For any operation that modifies state
5. **Logging**: Consistent output format (info/warn/error)
6. **Validation**: Input validation and pre-flight checks

### Bash Standards
```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'        # Proper field splitting
```

### Python Standards
```python
#!/usr/bin/env python3
import argparse
import sys
# Clear error messages, proper exit codes
```

### PowerShell Standards
```powershell
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
```

## Shared Libraries

Common functionality is extracted to `scripts/lib/`:

- **logging.sh** / **logging.py** - Unified logging functions
- **retry.sh** / **retry.py** - Retry logic with backoff
- **config.sh** / **config.py** - Configuration parsing
- **k8s-common.sh** - Kubernetes command wrappers

## Safety Policy

- **No destructive operations without explicit confirmation**
- **Dry-run must be supported for any state-changing operation**
- **Clear preconditions and assumptions documented**
- **Graceful degradation when optional dependencies missing**

## Usage

Make scripts executable:
```bash
chmod +x scripts/bash/<tool_name>/*.sh
```

Run with `--help` to see options:
```bash
./scripts/bash/k8s_toolkit/node/drain-node.sh --help
```
