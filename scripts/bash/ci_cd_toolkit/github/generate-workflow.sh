#!/usr/bin/env bash
#
# Purpose: Generate a starter GitHub Actions workflow file
# Usage: ./generate-workflow.sh --type [ci|deploy|release] --name workflow.yml
# Requirements: None (pure bash)
# Safety: Creates new files only; errors if file exists

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Defaults
TYPE=""
OUTPUT=""
PROJECT_TYPE=""
FORCE=false

usage() {
    cat <<EOF
Usage: $(basename "$0") -t TYPE -o FILE [OPTIONS]

Generate a starter GitHub Actions workflow file.

OPTIONS:
    -t, --type TYPE                 Workflow type: ci, deploy, release, pr
    -o, --output FILE               Output file path
    -p, --project-type TYPE         Project type: node, python, go, docker
    -f, --force                     Overwrite existing file
    -h, --help                      Show this help message

EXAMPLES:
    $(basename "$0") -t ci -o .github/workflows/ci.yml -p node
    $(basename "$0") -t deploy -o .github/workflows/deploy.yml -p docker
    $(basename "$0") -t release -o .github/workflows/release.yml

WORKFLOW TYPES:
    ci          Continuous integration (test, lint, build)
    deploy      Deployment workflow
    release     Release publishing
    pr          Pull request checks
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    echo "[ERROR] $*" >&2
}

die() {
    error "$*"
    exit 1
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--type)
                TYPE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT="$2"
                shift 2
                ;;
            -p|--project-type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

validate_args() {
    [[ -z "$TYPE" ]] && die "Workflow type is required (-t)"
    [[ -z "$OUTPUT" ]] && die "Output file is required (-o)"

    if [[ -f "$OUTPUT" && "$FORCE" != true ]]; then
        die "File exists: $OUTPUT (use -f to overwrite)"
    fi

    case "$TYPE" in
        ci|deploy|release|pr) ;;
        *) die "Invalid type: $TYPE (use ci, deploy, release, or pr)" ;;
    esac
}

generate_ci_workflow() {
    local setup_step=""

    case "${PROJECT_TYPE:-}" in
        node)
            setup_step="      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build"
            ;;
        python)
            setup_step="      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
      - run: pip install -r requirements.txt
      - run: flake8 .
      - run: pytest"
            ;;
        go)
            setup_step="      - uses: actions/setup-go@v5
        with:
          go-version: '1.23'
          cache: true
      - run: go vet ./...
      - run: go test ./...
      - run: go build -v ./..."
            ;;
        docker)
            setup_step="      - uses: docker/setup-buildx-action@v3
      - name: Build Docker image
        run: docker build -t app:test ."
            ;;
        *)
            setup_step="      # Add your project setup steps here"
            ;;
    esac

    cat <<EOF
name: CI

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

concurrency:
  group: \${{ github.workflow }}-\${{ github.ref }}
  cancel-in-progress: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
$setup_step
EOF
}

generate_deploy_workflow() {
    cat <<EOF
name: Deploy

on:
  push:
    branches: [main, master]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

concurrency:
  group: deploy-\${{ github.ref }}
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: \${{ github.event.inputs.environment || 'staging' }}
    steps:
      - uses: actions/checkout@v4

      - name: Setup
        run: |
          echo "Deployment setup"

      - name: Deploy
        run: |
          echo "Deploying to \${{ github.event.inputs.environment || 'staging' }}"
        # Add your deployment commands

      - name: Verify
        run: |
          echo "Verifying deployment"
EOF
}

generate_release_workflow() {
    cat <<EOF
name: Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate Changelog
        id: changelog
        run: |
          echo "Generating changelog..."
          # Add changelog generation logic

      - name: Create Release
        uses: softprops/action-gh-release@v2
        if: startsWith(github.ref, 'refs/tags/')
        with:
          generate_release_notes: true
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
EOF
}

generate_pr_workflow() {
    cat <<EOF
name: PR Checks

on:
  pull_request:
    types: [opened, synchronize, reopened]

concurrency:
  group: pr-\${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run linters
        run: |
          echo "Running linters"
          # Add lint commands

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: |
          echo "Running tests"
          # Add test commands

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Security scan
        uses: github/codeql-action/init@v3
        with:
          languages: javascript
      - uses: github/codeql-action/analyze@v3
EOF
}

generate_workflow() {
    case "$TYPE" in
        ci) generate_ci_workflow ;;
        deploy) generate_deploy_workflow ;;
        release) generate_release_workflow ;;
        pr) generate_pr_workflow ;;
    esac
}

main() {
    parse_args "$@"
    validate_args

    # Ensure directory exists
    mkdir -p "$(dirname "$OUTPUT")"

    log "Generating $TYPE workflow: $OUTPUT"
    generate_workflow > "$OUTPUT"

    log "Workflow generated successfully"
    log "Review and customize: $OUTPUT"
}

main "$@"
