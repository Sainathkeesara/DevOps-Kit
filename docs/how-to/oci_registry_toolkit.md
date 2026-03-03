# OCI Registry Toolkit (oci_registry_toolkit)

## Purpose

The oci_registry_toolkit provides safe, standardized scripts for interacting with OCI-compliant container registries. These tools enable listing repositories and tags, identifying stale artifacts, generating backup/keepalive plans, and diagnosing authentication issues.

## When to use

Use oci_registry_toolkit when you need to:
- Discover what repositories and tags exist in a registry
- Identify old or unused image tags for cleanup
- Generate a plan to pull artifacts for offline/air-gapped environments
- Diagnose registry authentication or connectivity problems
- Automate registry maintenance with consistent, safe operations

Do **not** use these for write operations (tag deletion) without thorough testing and backup. Always review generated plans before execution.

## Prerequisites

- `oras` CLI (v1.3+): https://oras.land/docs/installation/
- `jq` for JSON parsing (needed by `find-old-tags.sh`): https://jqlang.github.io/jq/
- Network access to target OCI registry
- Appropriate credentials (username/password, token) for authenticated registries
- Bash shell environment (Linux/macOS/WSL)

## Steps

### Installation

Clone the DevOps-Kit repository and ensure scripts are executable:

```bash
git clone <repo> devops-kit
cd devops-kit
chmod +x scripts/bash/oci_registry_toolkit/**/*.sh
```

Optionally add to your PATH:

```bash
export PATH="$PWD/scripts/bash/oci_registry_toolkit:$PATH"
```

### Authenticating to Registries

Before accessing private registries, authenticate:

```bash
oras login <registry>
# Enter username and password when prompted
```

For common registries:
- Docker Hub: `oras login docker.io`
- GitHub Container Registry: `oras login ghcr.io` (use a GitHub PAT with `read:packages`)
- AWS ECR: `aws ecr get-login-password | oras login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com`
- Azure Container Registry: `oras login <registry>.azurecr.io`
- GCP Artifact Registry: `gcloud auth print-access-token | oras login --username oauth2accesstoken --password-stdin <region>-docker.pkg.dev`

### list-repos.sh

List all repositories in a registry or namespace.

```bash
./scripts/bash/oci_registry_toolkit/registry/list-repos.sh <registry> [--namespace=<ns>] [--format=<fmt>] [--insecure] [--dry-run]
```

**Arguments:**
- `<registry>` - Registry host (e.g., `docker.io`, `ghcr.io`, `myregistry.com:5000`)

**Options:**
- `--namespace=<ns>` - Limit to a namespace (e.g., `library`)
- `--format=<fmt>` - Output format: `text` (default) or `json`
- `--insecure` - Allow insecure connections (self-signed certs)
- `--dry-run` - Show command without executing

**Example:**
```bash
./list-repos.sh ghcr.io/myorg --format=json
```

**Expected behavior:**
- Returns list of repository names, one per line (or JSON array if `--format=json`)
- Exit code 0 on success, non-zero on error

### list-tags.sh

List all tags for a specific repository.

```bash
./scripts/bash/oci_registry_toolkit/registry/list-tags.sh <repository> [--last=<tag>] [--exclude-digest] [--format=<fmt>] [--insecure] [--dry-run]
```

**Arguments:**
- `<repository>` - Full repository path (e.g., `docker.io/library/ubuntu`, `ghcr.io/myorg/app`)

**Options:**
- `--last=<tag>` - Show tags lexically after the specified tag
- `--exclude-digest` - Exclude digest references (only show named tags)
- `--format=<fmt>` - Output format: `text` (default) or `json`
- `--insecure` - Allow insecure connections
- `--dry-run` - Preview command without execution

**Example:**
```bash
./list-tags.sh docker.io/library/ubuntu --exclude-digest
```

### find-old-tags.sh

Find tags older than a threshold or matching a pattern. Useful for cleanup planning.

```bash
./scripts/bash/oci_registry_toolkit/tags/find-old-tags.sh <repository> [--days=<N>] [--pattern=<regex>] [--exclude-digest] [--insecure] [--dry-run] [--delete]
```

**Arguments:**
- `<repository>` - Full repository path

**Options:**
- `--days=<N>` - Age threshold in days (default: 90)
- `--pattern=<regex>` - Filter tags by regex pattern (e.g., `^test-.*`, `^v[0-9]+\.[0-9]+\.[0-9]+$`)
- `--exclude-digest` - Exclude digest tags
- `--insecure` - Allow insecure connections
- `--dry-run` - Show what would be processed without making changes
- `--delete` - Permanently delete matched tags (requires confirmation)

**Examples:**
```bash
# Find tags older than 120 days
./find-old-tags.sh myorg/app --days=120

# Find test tags older than 30 days
./find-old-tags.sh myorg/app --pattern="^test-.*" --days=30

# Preview deletion of old tags
./find-old-tags.sh myorg/app --days=365 --delete --dry-run
```

**How it works:**
1. Lists all tags (excluding digests if `--exclude-digest`)
2. For each tag, fetches manifest to extract `created` timestamp
3. Compares age against threshold
4. Outputs table of old tags with creation dates
5. With `--delete`, uses `oras manifest delete` to remove each tag (irreversible)

### keepalive-pull-plan.sh

Generate a bash script that pulls selected artifacts to a local OCI layout directory for offline/keepalive usage.

```bash
./scripts/bash/oci_registry_toolkit/tools/keepalive-pull-plan.sh <repository> [--output=<script-path>] [--pattern=<regex>] [--min-age-days=<N>] [--max-age-days=<N>] [--target-dir=<path>] [--insecure] [--dry-run]
```

**Arguments:**
- `<repository>` - Full repository path

**Options:**
- `--output=<script-path>` - Write plan to file (default: stdout)
- `--pattern=<regex>` - Only include tags matching regex (e.g., semantic versioning)
- `--min-age-days=<N>` - Minimum age in days (e.g., pull only mature releases)
- `--max-age-days=<N>` - Maximum age in days (e.g., keep recent N days of backups)
- `--target-dir=<path>` - Directory where artifacts will be pulled (default: `./oci-layout`)
- `--insecure` - Allow insecure connections in generated script
- `--dry-run` - Preview plan without writing file

**Examples:**
```bash
# Generate pull script for all tags
./keepalive-pull-plan.sh myorg/app --output=pull-all.sh --target-dir=./backup

# Pull only stable versions (vX.Y.Z) not older than 2 years
./keepalive-pull-plan.sh myorg/app --pattern="^v[0-9]+\.[0-9]+\.[0-9]+$" --max-age-days=730 --output=pull-stable.sh
```

**Generated script features:**
- Shebang and safety comments
- Creates target directory if missing
- Streams pull operations with progress feedback
- Logs failures but continues

**Executing the plan:**
```bash
bash pull-stable.sh
```

The pulled artifacts reside in `TARGET_DIR` as an OCI Image Layout that can be served by a local registry or used with `oras` copy commands.

### check-auth.sh

Diagnose authentication and connectivity to a registry.

```bash
./scripts/bash/oci_registry_toolkit/auth/check-auth.sh <registry> [--verbose] [--insecure]
```

**Arguments:**
- `<registry>` - Registry host (e.g., `docker.io`, `myregistry.com:5000`)

**Options:**
- `--verbose` - Show detailed diagnostic info (config file locations, oras version)
- `--insecure` - Test with insecure connection (self-signed certs)

**Examples:**
```bash
./check-auth.sh ghcr.io
./check-auth.sh myregistry.com --verbose --insecure
```

**Output:**
- If accessible: `[INFO] Registry accessible. Repositories found: X`
- If inaccessible: error classification with remediation steps (authentication, network, URL)

**Common error categories:**
- Unauthorized (401/403): Need to login or refresh credentials
- Connection refused/timeout: Network or firewall issue
- Not found (404): Registry URL incorrect or service down

## Verify

After running any tool:
- **list-repos**: Exit code 0; output contains repository names or valid JSON. Spot-check a repository: `oras manifest fetch <repo:tag>` should work.
- **list-tags**: Exit code 0; output lists tags. Verify a sample tag exists: `kubectl oras manifest fetch <repo:tag>` returns manifest.
- **find-old-tags**: Table shows tags with dates; ensure ages match expectations. Cross-check with `list-tags` to confirm no missing tags.
- **keepalive-pull-plan**: Generated script exists and is executable (`chmod +x`). Run with `bash --dry-run` to preview before actual pull.
- **check-auth**: Returns `[INFO] Registry accessible` or provides specific error guidance.
- For authenticated operations: After `oras login`, run `oras whoami` to confirm identity.

## Rollback

- **list-repos/list-tags/check-auth**: Read-only; no rollback needed.
- **find-old-tags --delete**: Irreversible deletion. If deletion was unintended, you must retag from a backup or another replica if available.
- **keepalive-pull-plan**: Generated script is non-destructive; only pulls artifacts. To rollback, simply delete the pulled OCI layout directory.

Always test with `--dry-run` first and backup critical artifacts before deletion.

## Common errors

### oras: command not found

Install oras CLI: https://oras.land/docs/installation/

### jq: command not found

Install jq: https://jqlang.github.io/jq/ (required by find-old-tags.sh)

### Unable to connect to the server

Check network connectivity, firewall rules, and registry hostname. For self-signed certificates, use `--insecure` or configure trust.

### Authentication failed (401/403)

Login again with correct credentials. For token-based auth, ensure token has not expired. For GHCR, use a classic PAT with `read:packages` scope (fine-grained PATs not yet supported by oras).

### Manifest fetch failed during age check

Some tags may be corrupted or incomplete. The script ignores such tags and continues. Verify problematic tags manually: `oras manifest fetch <repo:tag>`.

### Permission denied when deleting tags

The authenticated user lacks delete permissions. Contact registry administrator or use an account with write access.

### SSL/TLS error

For registries with self-signed certificates, use `--insecure` flag in all commands. Better: import the CA certificate into your system trust store.

## References

- ORAS CLI documentation: https://oras.land/docs/
- OCI Distribution Specification: https://github.com/opencontainers/distribution-spec
- Docker credential helper: https://github.com/docker/docker-credential-helpers
- GitHub Container Registry authentication: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- AWS ECR authentication: https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html
- Azure Container Registry authentication: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication
