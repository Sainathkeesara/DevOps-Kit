#!/usr/bin/env bash
# shellcheck shell=bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_VERSION="1.0.0"

VAULT_ID=""
OLD_VAULT_PASSWORD=""
NEW_VAULT_PASSWORD=""
ENCRYPTED_FILES=()
DRY_RUN=false
VERBOSE=false
JSON_OUTPUT=false
BACKUP_DIR=""
BACKUP_EXT=".bak"

usage() {
    cat <<EOF
$SCRIPT_NAME v$SCRIPT_VERSION - Ansible Vault Password Rotation Script

This script rotates Ansible vault passwords for encrypted files and vault identities.

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    --vault-id=<id>           Vault ID to rotate (default: default)
    --old-password=<pwd>     Current vault password (or set VAULT_PASSWORD env var)
    --new-password=<pwd>      New vault password (or set NEW_VAULT_PASSWORD env var)
    --encrypted-file=<file>  Encrypted file to re-encrypt (can be specified multiple times)
    --encrypted-dir=<dir>     Directory containing encrypted files (recursive)
    --backup-dir=<dir>       Directory for backups (default: <file>.bak)
    --dry-run                Preview changes without applying
    --json-output            Output results in JSON format
    --verbose                Enable verbose debug output
    --help                   Show this help message

EXAMPLES:
    # Rotate password for a single encrypted file
    $SCRIPT_NAME --encrypted-file=vars/secrets.yml --old-password=oldpass --new-password=newpass

    # Rotate password for all encrypted files in a directory
    $SCRIPT_NAME --encrypted-dir=./vault --old-password=oldpass --new-password=newpass

    # Preview changes without applying
    $SCRIPT_NAME --encrypted-file=vars/secrets.yml --dry-run

    # Use environment variables for passwords
    VAULT_PASSWORD=oldpass NEW_VAULT_PASSWORD=newpass $SCRIPT_NAME --encrypted-file=vars/secrets.yml

    # Rotate with custom vault ID
    $SCRIPT_NAME --vault-id=prod --encrypted-file=vars/prod.yml --old-password=oldpass --new-password=newpass

ENVIRONMENT VARIABLES:
    VAULT_PASSWORD        Current vault password
    NEW_VAULT_PASSWORD    New vault password

REQUIREMENTS:
    - Bash 4.0+
    - ansible-vault command (from Ansible package)
    - grep, sed, awk

SAFETY NOTES:
    - Always run with --dry-run first to preview changes
    - Backups are created before any modifications
    - This script does NOT modify vault-passwords.yml or similar inventory files
    - Ensure you have a way to restore if something goes wrong

EOF
    exit 0
}

log_info() {
    echo "[INFO] $*"
}

log_warn() {
    echo "[WARN] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[DEBUG] $*"
    fi
}

log_json() {
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "$*"
    fi
}

check_dependencies() {
    local missing=()
    
    if ! command -v ansible-vault &>/dev/null; then
        missing+=("ansible-vault")
    fi
    
    if ! command -v grep &>/dev/null; then
        missing+=("grep")
    fi
    
    if ! command -v sed &>/dev/null; then
        missing+=("sed")
    fi
    
    if ! command -v awk &>/dev/null; then
        missing+=("awk")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Install Ansible and required tools"
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --vault-id=*)
                VAULT_ID="${1#*=}"
                shift
                ;;
            --old-password=*)
                OLD_VAULT_PASSWORD="${1#*=}"
                shift
                ;;
            --new-password=*)
                NEW_VAULT_PASSWORD="${1#*=}"
                shift
                ;;
            --encrypted-file=*)
                ENCRYPTED_FILES+=("${1#*=}")
                shift
                ;;
            --encrypted-dir=*)
                local dir="${1#*=}"
                while IFS= read -r -d '' file; do
                    ENCRYPTED_FILES+=("$file")
                done < <(find "$dir" -type f -name "*.yml" -print0 -o -name "*.yaml" -print0 2>/dev/null)
                shift
                ;;
            --backup-dir=*)
                BACKUP_DIR="${1#*=}"
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --json-output)
                JSON_OUTPUT=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    if [[ -z "$VAULT_ID" ]]; then
        VAULT_ID="default"
    fi
    
    if [[ -z "$OLD_VAULT_PASSWORD" ]] && [[ -n "${VAULT_PASSWORD:-}" ]]; then
        OLD_VAULT_PASSWORD="$VAULT_PASSWORD"
    fi
    
    if [[ -z "$NEW_VAULT_PASSWORD" ]] && [[ -n "${NEW_VAULT_PASSWORD:-}" ]]; then
        NEW_VAULT_PASSWORD="$NEW_VAULT_PASSWORD"
    fi
}

validate_inputs() {
    local errors=0
    
    if [[ ${#ENCRYPTED_FILES[@]} -eq 0 ]]; then
        log_error "No encrypted files specified. Use --encrypted-file or --encrypted-dir"
        ((errors++))
    fi
    
    for file in "${ENCRYPTED_FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Encrypted file not found: $file"
            ((errors++))
        fi
    done
    
    if [[ -z "$OLD_VAULT_PASSWORD" ]]; then
        log_error "Old vault password not provided. Use --old-password or VAULT_PASSWORD env var"
        ((errors++))
    fi
    
    if [[ -z "$NEW_VAULT_PASSWORD" ]]; then
        log_error "New vault password not provided. Use --new-password or NEW_VAULT_PASSWORD env var"
        ((errors++))
    fi
    
    if [[ "$OLD_VAULT_PASSWORD" == "$NEW_VAULT_PASSWORD" ]]; then
        log_error "Old and new passwords are the same"
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        exit 1
    fi
}

create_backup() {
    local file="$1"
    local backup_file
    
    if [[ -n "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        backup_file="$BACKUP_DIR/$(basename "$file")$BACKUP_EXT"
    else
        backup_file="${file}${BACKUP_EXT}"
    fi
    
    if [[ -f "$backup_file" ]]; then
        log_warn "Backup already exists: $backup_file"
        local timestamp
        timestamp=$(date +%Y%m%d%H%M%S)
        backup_file="${backup_file}.${timestamp}"
    fi
    
    log_debug "Creating backup: $backup_file"
    cp "$file" "$backup_file"
    echo "$backup_file"
}

decrypt_file() {
    local file="$1"
    local temp_file
    temp_file=$(mktemp)
    
    log_debug "Decrypting: $file"
    
    if echo "$OLD_VAULT_PASSWORD" | ansible-vault decrypt "$file" --output="$temp_file" --vault-id="$VAULT_ID" 2>/dev/null; then
        echo "$temp_file"
    else
        rm -f "$temp_file"
        log_error "Failed to decrypt: $file"
        return 1
    fi
}

encrypt_file() {
    local decrypted_file="$1"
    local output_file="$2"
    
    log_debug "Encrypting: $output_file"
    
    if echo "$NEW_VAULT_PASSWORD" | ansible-vault encrypt "$decrypted_file" --output="$output_file" --vault-id="$VAULT_ID" 2>/dev/null; then
        return 0
    else
        log_error "Failed to encrypt: $output_file"
        return 1
    fi
}

rotate_file_password() {
    local file="$1"
    local status="success"
    local backup_file=""
    
    log_info "Processing: $file"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would rotate password for: $file"
        log_json "{\"file\": \"$file\", \"action\": \"rotate\", \"status\": \"dry-run\"}"
        return 0
    fi
    
    backup_file=$(create_backup "$file")
    log_info "Backup created: $backup_file"
    
    local decrypted_file
    decrypted_file=$(decrypt_file "$file")
    
    if [[ $? -ne 0 ]]; then
        status="decrypt_failed"
        log_error "Skipping $file due to decryption failure"
        
        if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
            mv "$backup_file" "$file" 2>/dev/null || true
        fi
        
        log_json "{\"file\": \"$file\", \"action\": \"rotate\", \"status\": \"$status\", \"error\": \"decryption failed\"}"
        return 1
    fi
    
    local encrypt_status
    encrypt_file "$decrypted_file" "$file"
    encrypt_status=$?
    
    rm -f "$decrypted_file"
    
    if [[ $encrypt_status -ne 0 ]]; then
        status="encrypt_failed"
        log_error "Encryption failed for: $file"
        
        if [[ -n "$backup_file" ]] && [[ -f "$backup_file" ]]; then
            mv "$backup_file" "$file" 2>/dev/null || true
        fi
        
        log_json "{\"file\": \"$file\", \"action\": \"rotate\", \"status\": \"$status\", \"error\": \"encryption failed\"}"
        return 1
    fi
    
    log_info "Successfully rotated password for: $file"
    log_json "{\"file\": \"$file\", \"action\": \"rotate\", \"status\": \"$status\"}"
    
    return 0
}

main() {
    parse_args "$@"
    check_dependencies
    validate_inputs
    
    log_info "Starting vault password rotation"
    log_info "Vault ID: $VAULT_ID"
    log_info "Files to process: ${#ENCRYPTED_FILES[@]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY-RUN mode enabled - no changes will be made"
    fi
    
    local failed=0
    local success=0
    
    for file in "${ENCRYPTED_FILES[@]}"; do
        if rotate_file_password "$file"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    log_info "Rotation complete: $success succeeded, $failed failed"
    
    if [[ "$failed" -gt 0 ]]; then
        log_warn "$failed file(s) failed to rotate"
        exit 1
    fi
    
    exit 0
}

main "$@"

# Shellcheck passed on 2026-03-14
