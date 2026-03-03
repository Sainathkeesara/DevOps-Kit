# DevOps-Kit

A local library of setup guides, troubleshooting docs, concepts, reusable scripts, and templates for DevOps and SRE workflows.

## Purpose

This repository serves as a personal knowledge base and toolset for:
- **Setup guides**: Step-by-step instructions for new environments and tools
- **Troubleshooting docs**: Symptom → cause → fix patterns
- **Concepts**: Deep dives into how things work
- **Scripts**: Reusable bash, Python, and PowerShell utilities
- **Templates**: Starter configurations and snippets

## Structure

- `00_index/` - Quick links and topic navigation
- `docs/` - Main documentation organized by category
- `scripts/` - Production-ready scripts with safety guards
- `snippets/` - Copy-paste code snippets by technology
- `templates/` - Starter configurations (Docker, k8s, Terraform, projects)
- `lab/` - Mini-projects and sandbox experiments
- `assets/` - Images and diagrams for docs
- `.github/` - GitHub workflows and PR templates

## Getting Started

See `00_index/quick-links.md` for curated links to the most useful resources in this kit.

## Maintenance

This repository is maintained using a systematic approach:
- Each tool implementation includes scripts, documentation, and snippets
- All changes are tracked in `CHANGELOG.md`
- PRs are created for every update
- Scripts follow safety-first design with dry-run modes
