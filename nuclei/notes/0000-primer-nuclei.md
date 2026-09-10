---
last_verified: 2026-09-10
tool_version: n/a
sources: []
---

# Nuclei — quick primer

> First-day notes for someone who's never used Nuclei. Personal voice, plain language.

I just learned about Nuclei. It's a vulnerability scanner from ProjectDiscovery that uses templates — YAML files defining what to check — instead of crawling a site interactively. Think of it like a giant library of vulnerability checks. Someone finds a new CVE, a template gets written, and you can run it immediately. Kinda like how Snort rules work for network IDS, but for web and infrastructure scanning.

It supports scanning web apps, network services, DNS, cloud APIs, stuff like that. Each template sends a request and checks the response — status codes, body content, headers. If it matches, you get a finding with severity and details. Output can be JSON, SARIF, or plain text, so it plugs into CI or SIEMs or just your terminal.

## What does it do?

The main flow is: give it a target (URL, IP, CIDR range), pick which templates to run, and it sends requests and reports findings. You can filter by severity, tag, or template ID. There's rate limiting so you don't hose the target.

What I found interesting is the template format — it's just YAML. You define an HTTP request, add matchers for what counts as a hit, and optionally extract data from the response. Pretty straightforward to write your own.

## Why does it exist?

Before this, you'd either use heavy scanners like Nessus (need agents, licenses, overhead) or write custom scripts for each check. Nuclei splits the difference — lightweight enough for CI, powerful enough for real scanning, and the community templates mean you don't start from scratch.

Day-to-day it's used for quick assessments of new assets, CI gates before deploy, continuous monitoring of external services, and incident response when a new CVE drops and you need to know if you're affected.

## Key terminology

- **Template** — A YAML file defining one vulnerability check. Has an HTTP request, matchers, extractors. Example: sends `GET /wp-login.php` and checks for WordPress indicators.
- **Matcher** — Condition that determines if the target is vulnerable. Checks status codes, body, headers, DNS. Example: `matcher: status(200)`.
- **Extractor** — Pulls specific data from the response when matched. Like grabbing a version number from a `Server` header.
- **Severity** — How bad the finding is (info, low, medium, high, critical). You filter scans by this.
- **Tag** — Label on templates for grouping (`cve`, `wordpress`, `misconfig`). Run only what matters.
- **Rate limit** — Controls request speed. Important for not getting banned or causing outages.

## A tiny example

```bash
nuclei -u https://example.com -severity high,critical
```

Runs all high/critical templates against that URL. First run downloads the template cache.

To run a specific template:

```bash
nuclei -u https://example.com -t http/cves/2024/CVE-2024-1234.yaml
```

## What I'll cover next

I'll install it, run it against a test target, and see what it catches. Then try writing a custom template for something the community templates don't cover.
