# OCI Registry Cheatsheet

Quick reference for common OCI registry operations using `oras` CLI.

## Installation

```bash
# macOS
brew install oras

# Linux (download binary)
curl -LO https://github.com/oras-project/oras/releases/download/v1.3.0/oras_1.3.0_linux_amd64.tar.gz
tar -xzf oras_1.3.0_*.tar.gz
sudo mv oras /usr/local/bin/

# Verify
oras version
```

## Authentication

```bash
# Login (interactive)
oras login docker.io
# Username: <your-username>
# Password: <your-password>

# Login with environment variables (CI/CD)
export ORAS_USERNAME=myuser
export ORAS_PASSWORD=mypassword
oras login docker.io

# Login using password from stdin (ECR example)
aws ecr get-login-password | oras login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
```

## Listing Repositories

```bash
# All repositories in a registry
oras repo ls docker.io

# Under a namespace
oras repo ls docker.io/library

# JSON output
oras repo ls ghcr.io/myorg --format json

# Insecure (self-signed certs)
oras repo ls myregistry.com:5000 --insecure
```

## Listing Tags

```bash
# All tags (including digests)
oras repo tags docker.io/library/ubuntu

# Exclude digest tags
oras repo tags docker.io/library/ubuntu --exclude-digest-tag

# Start after a specific tag (pagination)
oras repo tags docker.io/library/ubuntu --last "22.04"

# JSON output
oras repo tags ghcr.io/myorg/app --format json
```

## Pulling Artifacts

```bash
# Pull to local OCI layout directory
oras pull -o ./backup docker.io/library/ubuntu:22.04

# Insecure
oras pull --insecure -o ./backup myregistry.com:5000/repo:tag
```

## Pushing Artifacts

```bash
# Push a file as an artifact
echo "Hello" > hello.txt
oras push docker.io/myuser/hello:latest ./hello.txt

# Push with custom media type
oras push --media-type "application/vnd.oci.image.config.v1+json" myrepo:tag ./config.json
```

## Deleting Manifests (Tags)

```bash
# Delete a specific tag (irreversible)
oras manifest delete docker.io/library/ubuntu:old-tag

# With insecure flag
oras manifest delete --insecure myregistry.com:5000/repo:tag
```

## Fetching Manifest

```bash
# View manifest metadata
oras manifest fetch docker.io/library/ubuntu:22.04

# JSON output
oras manifest fetch docker.io/library/ubuntu:22.04 --format json

# Extract config digest and creation time
oras manifest fetch docker.io/library/ubuntu:22.04 --format json | jq '.config'
```

## Copying Between Registries

```bash
# Copy an artifact
oras cp docker.io/library/ubuntu:22.04 ghcr.io/myorg/ubuntu:22.04

# With insecure on source or target
oras cp --insecure myregistry.com:5000/src:tag docker.io/dest:tag
```

## Discovering Referrers

```bash
# List artifacts that refer to a manifest (e.g., signatures, SBOMs)
oras discover docker.io/library/ubuntu:22.04
```

## Useful jq One-Liners

```bash
# Extract config created timestamp
oras manifest fetch repo:tag --format json | jq -r '.config.created'

# Count tags
oras repo tags repo | wc -l

# Get newest tag (lexical sort)
oras repo tags repo | tail -n 1

# Filter tags by pattern
oras repo tags repo | grep '^v[0-9]'
```

## Troubleshooting

```bash
# Enable debug logging
oras --debug repo ls docker.io

# Check current authentication
oras whoami

# Logout
oras logout docker.io
```

## Common Registries

| Registry | Host URL | Notes |
|----------|----------|-------|
| Docker Hub | `docker.io` | Public by default; login for rate limits |
| GitHub Container Registry | `ghcr.io` | Use GitHub PAT with `read:packages` (and `write:packages` to push) |
| Google Container Registry | `gcr.io` | Use `gcloud auth print-access-token` |
| AWS ECR | `<account>.dkr.ecr.<region>.amazonaws.com` | Use `aws ecr get-login-password` |
| Azure Container Registry | `<name>.azurecr.io` | Use `az acr login` or `oras login` |
| Red Hat Quay | `quay.io` | Login with Quay credentials |
| Harbor | `myharbor.com` | May require `--insecure` for self-signed certs |

## Media Types

Common OCI media types you may encounter:

- `application/vnd.oci.image.manifest.v1+json` - OCI image manifest
- `application/vnd.oci.image.config.v1+json` - OCI image config
- `application/vnd.oci.image.layer.v1.tar+gzip` - Image layer
- `application/vnd.oci.artifact.manifest.v1+json` - Generic artifact manifest
- `application/vnd.cncf.helm.config.v1+json` - Helm chart config

## Environment Variables

- `ORAS_USERNAME` - Username for authentication
- `ORAS_PASSWORD` - Password or token for authentication
- `ORAS_INSECURE` - Set to `true` to disable TLS verification
- `ORAS_DEBUG` - Set to `true` for debug output
- `HOME` - Used to locate `~/.oras/config.json`

## References

- ORAS CLI docs: https://oras.land/docs/
- OCI Distribution Spec: https://github.com/opencontainers/distribution-spec
- Helm OCI support: https://helm.sh/docs/topics/oci/
