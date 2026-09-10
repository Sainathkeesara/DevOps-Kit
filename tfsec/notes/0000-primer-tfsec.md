---
last_verified: 2026-09-10
tool_version: n/a
sources: []
---

# tfsec — quick primer

> First-day notes for someone who's never used tfsec. Personal voice, plain language.

I just learned about tfsec. It's a static analysis tool that scans Terraform code for security misconfigurations before you apply it. Built by Aqua Security. Think of it as a linter that cares about security instead of code style — checks your `.tf` files against a library of rules covering open security groups, unencrypted databases, public S3 buckets, missing logging, that sort of thing.

The interesting part: it uses the HCL parser to understand your config without needing `terraform plan`. So it catches issues at write time, not apply time. Way cheaper to fix.

## What does it does?

It parses your Terraform files, builds an internal representation, and checks each resource against its rule set. Rules cover AWS, Azure, GCP, and generic providers. When it finds something, it reports the file, line, resource, which check failed, and severity.

You can exclude checks with inline comments (`tfsec:ignore[check_id]`) or via config file. Output formats include JSON, SARIF, and formatted text for CI. There's a baseline feature for legacy codebases — save a scan result, future scans only flag new issues.

## Why does it exist?

Terraform makes it easy to provision infrastructure, but defaults are often insecure. An EC2 security group allowing `0.0.0.0/0` on port 22 works in dev — but if that same config ends up in a live environment, you've got an open SSH door. tfsec catches this before it hits your cloud.

Day-to-day: pre-commit hooks for local catches, CI gates on PRs, IaC review processes. The inline ignore comments are important — documenting accepted risks ("yes, this bucket is public, here's why") instead of just silencing warnings.

## Key terminology

- **Check** — A single security rule evaluating a resource attribute. Example: `aws-s3-enable-bucket-logging` checks S3 buckets have access logging.
- **Severity** — CRITICAL, HIGH, MEDIUM, LOW, INFO. Most CI gates fail on HIGH and CRITICAL.
- **`tfsec:ignore`** — Inline comment suppressing a check. Format: `# tfsec:ignore[aws-s3-enable-bucket-logging]`.
- **Baseline** — Saved scan result for comparison. Only new issues flagged. Good for legacy code.
- **Workspace** — Set of Terraform files to scan together. Defaults to current directory.
- **Module** — tfsec follows module calls to scan nested modules. Disable with `--module-depth=0`.

## A tiny example

```bash
tfsec .
```

Scans all `.tf` files in current directory, prints findings. Downloads ruleset on first run.

SARIF output for GitHub code scanning:

```bash
tfsec . --format sarif --out results.sarif
```

Inline ignore:

```hcl
resource "aws_s3_bucket" "data" {
  # tfsec:ignore[aws-s3-enable-bucket-logging]
  bucket = "my-data-bucket"
}
```

## What I'll cover next

I'll install it, run against a sample Terraform config with intentional misconfigs, and see what it catches. Then try writing a custom check and setting up a baseline.
