#!/usr/bin/env bash
# shellcheck shell=bash

#
# PURPOSE: Rotate Ansible vault passwords across encrypted files and playbooks
# USAGE: ./vault-password-rotation.sh [--old-vault-id=<id>] [--new-vault-id=<id>] [--path=<dir>] [--dry-run] [--execute]
# REQUIREMENTS: bash 4+, ansible-vault, gpg (optional for keyring)
# SAFETY: Dry-run by default. Use --execute to apply changes.
#
# CVE-2025-9907: Ansible EDA credentials exposure in test mode
# This script helps rotate vault passwords to mitigate credential exposure risks
#
# EXAMPLES:
#   ./vault-password-rotation.sh --dry-run
#   ./vault-password-rotation.sh --path=/home/user/ansible --dry-run
#   ./vault-password-rotation.sh --execute --new-vault-id=ansible_vault
#   ./vault-password-rotation.sh --old-vault-id=main --new-vault-id=prod --execute
#

set -euo pipefail
IFS=$'\n\t'

DRY_RUN=1
EXECUTE=0
OLD_VAULT_ID="ansible_vault"
NEW_VAULT_ID="ansible_vault"
SCAN_PATH="."
BACKUP_DIR=""
VERBOSE=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_section() { echo -e "${BLUE}[SECTION]${NC} $*" >&2; }
log_verbose() { [[ $VERBOSE -eq 1 ]] && echo -e "${BLUE}[DEBUG]${NC} $*" >&2 || true; }

usage() {
    cat <<EOF
Ansible Vault Password Rotation Script

USAGE: $0 [OPTIONS]

OPTIONS:
    --old-vault-id=<id>     Current vault ID to rotate from (default: ansible_vault)
    --new-vault-id=<id>     New vault ID to rotate to (default: ansible_vault)
    --path=<dir>           Path to scan for encrypted files (default: current directory)
    --backup-dir=<dir>     Directory for backups (default: auto-generated)
    --dry-run              Preview operations without making changes (default)
    --execute              Apply changes (requires explicit confirmation)
    --verbose              Enable verbose debug output
    -h, --help             Show this help message

DESCRIPTION:
    This script rotates Ansible vault passwords across encrypted files.
    It supports:
    1. Identifying encrypted vault files
    2. Backing up original files before re-encryption
    3. Re-encrypting files with new vault password
    4. Updating vault-passwords file references

    SECURITY NOTES:
    - Always run with --dry-run first to preview changes
    - Backups are created before any modifications
    - Original files are preserved with .bak extension
    - Requires ansible-vault command available

EXAMPLES:
    # Preview what would be rotated
    ./vault-password-rotation.sh --dry-run

    # Rotate passwords in specific directory
    ./vault-password-rotation.sh --path=/home/user/ansible --dry-run

    # Execute the rotation (requires confirmation)
    ./vault-password-rotation.sh --execute --new-vault-id=prod_vault

    # Rotate from specific old ID to new ID
    ./vault-password-rotation.sh --old-vault-id=main --new-vault-id=prod --execute

EOF
    exit 0
}

check_dependencies() {
    local missing=()
    if ! command -v ansible-vault &>/dev/null; then
        missing+=("ansible-vault")
    fi
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_error "Install ansible-core or ansible-community package"
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --old-vault-id=*)
                OLD_VAULT_ID="${1#*=}"
                shift
                ;;
            --new-vault-id=*)
                NEW_VAULT_ID="${1#*=}"
                shift
                ;;
            --path=*)
                SCAN_PATH="${1#*=}"
                shift
                ;;
            --backup-dir=*)
                BACKUP_DIR="${1#*=}"
                shift
                ;;
            --dry-run)
                DRY_RUN=1
                EXECUTE=0
                shift
                ;;
            --execute)
                DRY_RUN=0
                EXECUTE=1
                shift
                ;;
            --verbose|-v)
                VERBOSE=1
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

confirm_execution() {
    if [[ $EXECUTE -eq 0 ]]; then
        return 0
    fi

    log_warn "This operation will modify encrypted vault files!"
    log_warn "Old vault ID: $OLD_VAULT_ID"
    log_warn "New vault ID: $NEW_VAULT_ID"
    log_warn "Scan path: $SCAN_PATH"
    echo ""
    read -r -p "Are you sure you want to proceed? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Operation cancelled by user"
        exit 0
    fi
}

find_encrypted_files() {
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$SCAN_PATH" -type f \( -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null || true)

    printf '%s\n' "${files[@]}"
}

check_vault_encrypted() {
    local file="$1"
    if head -n 5 "$file" 2>/dev/null | grep -q '\$ANSIBLE_VAULT'; then
        return 0
    fi
    return 1
}

backup_file() {
    local file="$1"
    local backup_path
    local timestamp
    timestamp=$(date +%Y%m%d%H%M%S)
    backup_path="${file}.bak.${timestamp}"

    if [[ -n "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        backup_path="$BACKUP_DIR/$(basename "$file").bak.${timestamp}"
    fi

    log_verbose "Creating backup: $backup_path"
    cp "$file" "$backup_path"
    echo "$backup_path"
}

rotate_vault_password() {
    local file="$1"
    local backup_file

    if ! check_vault_encrypted "$file"; then
        log_verbose "Skipping non-encrypted file: $file"
        return 0
    fi

    log_section "Processing: $file"

    if [[ $DRY_RUN -eq 1 ]]; then
        log_info "[DRY-RUN] Would rotate vault password in: $file"
        log_info "[DRY-RUN] Old vault ID: $OLD_VAULT_ID -> New vault ID: $NEW_VAULT_ID"
        return 0
    fi

    backup_file=$(backup_file "$file")
    log_info "Backup created: $backup_file"

    if ansible-vault rekey "$file" --new-vault-id="$NEW_VAULT_ID" 2>/dev/null; then
        log_info "Successfully rotated vault password: $file"
    else
        log_error "Failed to rotate vault password: $file"
        log_warn "Restoring backup..."
        mv "$backup_file" "$file"
        return 1
    fi
}

scan_and_rotate() {
    local file_count=0
    local encrypted_count=0
    local success_count=0
    local fail_count=0

    log_section "Scanning for encrypted vault files in: $SCAN_PATH"

    while IFS= read -r -d '' file; do
        ((file_count++))

        if check_vault_encrypted "$file"; then
            ((encrypted_count++))
            log_verbose "Found encrypted file: $file"

            if rotate_vault_password "$file"; then
                ((success_count++))
            else
                ((fail_count++))
            fi
        fi
    done < <(find "$SCAN_PATH" -type f \( -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null || true)

    echo ""
    log_section "Summary"
    echo "  Total files scanned: $file_count"
    echo "  Encrypted files found: $encrypted_count"
    echo "  Successfully rotated: $success_count"
    echo "  Failed: $fail_count"

    if [[ $DRY_RUN -eq 1 ]]; then
        echo ""
        log_info "DRY-RUN complete. Use --execute to apply changes."
    fi
}

main() {
    parse_args "$@"

    if [[ $VERBOSE -eq 1 ]]; then
        log_info "Vault Password Rotation Script"
        log_info "Old vault ID: $OLD_VAULT_ID"
        log_info "New vault ID: $NEW_VAULT_ID"
        log_info "Scan path: $SCAN_PATH"
        log_info "Mode: $([[ $DRY_RUN -eq 1 ]] && echo "DRY-RUN" || echo "EXECUTE")"
        echo ""
    fi

    check_dependencies

    if [[ ! -d "$SCAN_PATH" ]]; then
        log_error "Path does not exist: $SCAN_PATH"
        exit 1
    fi

    confirm_execution

    scan_and_rotate
}

main "$@"
