# CI/CD Cheatsheet

## GitHub Actions

### Workflow Structure
```yaml
name: Workflow Name

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  job-name:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "Hello"
```

### Triggers
```yaml
# Push to branches
on:
  push:
    branches: [main, develop]
    paths: ['src/**']

# Pull requests
on:
  pull_request:
    types: [opened, synchronize, closed]

# Scheduled (cron)
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

# Manual trigger
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment'
        required: true
        type: choice
        options: [staging, production]
```

### Contexts and Expressions
```yaml
# Github context
${{ github.repository }}
${{ github.ref }}
${{ github.sha }}
${{ github.actor }}

# Env and vars
${{ env.NAME }}
${{ vars.ORG_VARIABLE }}

# Secrets
${{ secrets.GITHUB_TOKEN }}
${{ secrets.SECRET_NAME }}

# Job outputs
${{ needs.job-name.outputs.output-name }}

# Conditional
if: github.ref == 'refs/heads/main'
if: contains(github.event.head_commit.message, 'deploy')
```

### Common Actions
```yaml
# Checkout
git checkout
  - uses: actions/checkout@v4
    with:
      fetch-depth: 0

# Setup Node.js
  - uses: actions/setup-node@v4
    with:
      node-version: '20'
      cache: 'npm'

# Setup Python
  - uses: actions/setup-python@v5
    with:
      python-version: '3.12'
      cache: 'pip'

# Setup Go
  - uses: actions/setup-go@v5
    with:
      go-version: '1.23'

# Docker Buildx
  - uses: docker/setup-buildx-action@v3

# Login to Docker Hub
  - uses: docker/login-action@v3
    with:
      username: ${{ secrets.DOCKER_USERNAME }}
      password: ${{ secrets.DOCKER_PASSWORD }}

# Upload artifact
  - uses: actions/upload-artifact@v4
    with:
      name: build-files
      path: dist/

# Download artifact
  - uses: actions/download-artifact@v4
    with:
      name: build-files
      path: dist/
```

### Reusable Workflows
```yaml
# Reusable workflow definition (.github/workflows/reusable.yml)
on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
    secrets:
      token:
        required: true
    outputs:
      result:
        description: "Build result"
        value: ${{ jobs.build.outputs.status }}

jobs:
  build:
    outputs:
      status: ${{ steps.build.outcome }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}

# Call reusable workflow
jobs:
  ci:
    uses: ./.github/workflows/reusable.yml
    with:
      node-version: '20'
    secrets:
      token: ${{ secrets.TOKEN }}
```

### Matrix Strategy
```yaml
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        node: [18, 20, 22]
        exclude:
          - os: windows-latest
            node: 18
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
```

### Concurrency and Cancellation
```yaml
# Cancel previous runs on new push
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# For deployments - don't cancel
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: false
```

### Job Dependencies
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building"

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing"

  deploy:
    needs: [build, test]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying"
```

### Permissions
```yaml
permissions:
  contents: read
  issues: write
  pull-requests: write
  id-token: write  # For OIDC

# Or at job level
jobs:
  job-name:
    permissions:
      contents: write
```

### Caching
```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      ~/.m2
    key: ${{ runner.os }}-build-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-build-
```

### Environment and Secrets
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://api.example.com
    steps:
      - run: deploy.sh
        env:
          API_KEY: ${{ secrets.API_KEY }}
```

## GitLab CI

### Basic Structure
```yaml
stages:
  - build
  - test
  - deploy

variables:
  NODE_VERSION: "20"

build:
  stage: build
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/

test:
  stage: test
  script:
    - npm test

deploy:
  stage: deploy
  script:
    - deploy.sh
  only:
    - main
```

### Rules (GitLab 12.8+)
```yaml
job:
  script: echo "Hello"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: always
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
    - when: never
```

### Caching
```yaml
.npm-cache:
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
    policy: pull-push
```

## CLI Tools

### actionlint (GitHub Actions Linter)
```bash
# Install
brew install actionlint

# Lint all workflows
actionlint

# Lint specific file
actionlint .github/workflows/ci.yml

# Ignore patterns
actionlint -ignore 'shellcheck SC2086'
```

### gh CLI
```bash
# Login
gh auth login

# List workflow runs
gh run list

# Watch run
gh run watch

# View logs
gh run view --log

# Re-run failed
gh run rerun --failed

# List workflows
gh workflow list

# Trigger workflow
gh workflow run ci.yml
```

## Best Practices

### Security
- Pin actions to SHAs or full version tags
- Use `permissions` to limit token scope
- Never hardcode secrets
- Use environments for protection rules
- Enable branch protection

### Performance
- Use caching for dependencies
- Cancel redundant runs with concurrency
- Use matrix for parallel jobs
- Use artifact upload/download between jobs

### Maintenance
- Use reusable workflows for common patterns
- Document workflow inputs/outputs
- Keep actions updated (monthly)
- Test workflows in forks

## References

- https://docs.github.com/en/actions
- https://docs.gitlab.com/ee/ci/
- https://github.com/rhysd/actionlint
- https://cli.github.com/
