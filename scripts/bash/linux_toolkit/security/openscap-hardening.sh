#!/usr/bin/env bash
# =============================================================================
# OpenSCAP Hardening Automation Script
# =============================================================================
# Purpose: Automate OpenSCAP security compliance scanning and remediation
# Usage: ./openscap-hardening.sh [--dry-run] [--profile PROFILE] [--report]
# Requirements: openscap-scanner, bash 4+, root privileges for remediation
# Safety Notes:
#   - Always run with --dry-run first to preview changes
#   - Backup /etc before applying remediation
#   - Review generated remediation scripts before applying
# Tested OS: RHEL 8/9, CentOS Stream 8/9, Fedora 38+
# =============================================================================

set -euo pipefail

DRY_RUN=false
PROFILE="xccdf_org.ssgproject.content_profile_stig-rhel8-draft"
REPORT_DIR="/var/log/openscap"
AUTO_REMEDIATE=false
BACKUP_DIR="/var/backup/openscap-$(date +%Y%m%d-%H%M%S)"

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    --dry-run          Preview changes without applying (recommended first)
    --profile PROFILE  OpenSCAP profile to use (default: stig-rhel8-draft)
    --auto-remediate   Automatically apply fixes when safe
    --report           Generate HTML report
    -h, --help        Show this help message

Examples:
    $0 --dry-run --profile xccdf_org.ssgproject.content_profile_cis
    $0 --dry-run --report
    $0 --auto-remediate --dry-run

Profiles:
    xccdf_org.ssgproject.content_profile_stig-rhel8-draft
    xccdf_org.ssgproject.content_profile_cis
    xccdf_org.ssgproject.content_profile_ospp
    xccdf_org.ssgproject.content_profile_pci-dss

EOF
    exit 0
}

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg"
    logger -t openscap-hardening "$level: $*"
}

check_dependencies() {
    log "INFO" "Checking dependencies..."
    
    local deps=("oscap" "date" "mkdir" "cp" "tar")
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR" "Required command '$cmd' not found"
            exit 1
        fi
    done
    
    if ! command -v openscap-scanner >/dev/null 2>&1; then
        log "WARN" "openscap-scanner not found, installing..."
        if command -v dnf >/dev/null 2>&1; then
            $DRY_RUN || sudo dnf install -y openscap-scanner
        elif command -v apt >/dev/null 2>&1; then
            $DRY_RUN || sudo apt-get install -y openscap-scanner
        else
            log "ERROR" "Cannot install openscap-scanner - unsupported package manager"
            exit 1
        fi
    fi
    
    log "INFO" "Dependencies OK"
}

create_backup() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create backup directory: $BACKUP_DIR"
        return 0
    fi
    
    log "INFO" "Creating system backup before remediation..."
    sudo mkdir -p "$BACKUP_DIR"
    
    local dirs_to_backup=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/ssh/sshd_config"
        "/etc/sysctl.conf"
        "/etc/audit/audit.rules"
        "/etc/modprobe.d"
    )
    
    for item in "${dirs_to_backup[@]}"; do
        if [[ -e "$item" ]]; then
            sudo cp -rp "$item" "$BACKUP_DIR/" 2>/dev/null || true
            log "INFO" "Backed up: $item"
        fi
    done
    
    sudo tar -czf "$BACKUP_DIR/etc-config.tar.gz" -C / etc 2>/dev/null || true
    log "INFO" "Backup created at: $BACKUP_DIR"
}

list_available_profiles() {
    log "INFO" "Fetching available OpenSCAP profiles..."
    
    local ds_path="/usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml"
    [[ ! -f "$ds_path" ]] && ds_path="/usr/share/xml/scap/ssg/content/ssg-fedora-ds.xml"
    
    if [[ ! -f "$ds_path" ]]; then
        log "WARN" "No SCAP datastream found, skipping profile list"
        return
    fi
    
    echo "Available profiles:"
    oscap info "$ds_path" 2>/dev/null | grep -E "Profile.*id:" | head -20 || true
}

download_scap_content() {
    local content_dir="/var/lib/openscap/content"
    local ds_file="$content_dir/ssg-rhel8-ds.xml"
    
    if [[ -f "$ds_file" ]]; then
        log "INFO" "Using existing SCAP content: $ds_file"
        echo "$ds_file"
        return
    fi
    
    $DRY_RUN && { echo "$ds_file"; return; }
    
    sudo mkdir -p "$content_dir"
    
    log "INFO" "Downloading SCAP content..."
    local scap_url="https://access.redhat.com/security/data/ scap/v2/RHEL8/rhel-8.8-oscap-latest.zip"
    
    if command -v curl >/dev/null 2>&1; then
        sudo curl -fsSL "$scap_url" -o "/tmp/scap.zip" || true
    elif command -v wget >/dev/null 2>&1; then
        sudo wget -q "$scap_url" -O "/tmp/scap.zip" || true
    fi
    
    if [[ -f "/tmp/scap.zip" ]]; then
        sudo unzip -o "/tmp/scap.zip" -d "$content_dir" 2>/dev/null || true
        rm -f "/tmp/scap.zip"
    fi
    
    echo "$ds_file"
}

run_compliance_scan() {
    local ds_file="$1"
    local output_xml="$REPORT_DIR/scan-results-$(date +%Y%m%d-%H%M%S).xml"
    local output_html="$REPORT_DIR/scan-report-$(date +%Y%m%d-%H%M%S).html"
    
    $DRY_RUN && {
        log "INFO" "[DRY-RUN] Would run OpenSCAP scan with profile: $PROFILE"
        log "INFO" "[DRY-RUN] Would save results to: $output_xml"
        return 0
    }
    
    sudo mkdir -p "$REPORT_DIR"
    
    log "INFO" "Starting compliance scan with profile: $PROFILE"
    log "INFO" "This may take several minutes..."
    
    if sudo oscap xccdf eval \
        --profile "$PROFILE" \
        --results "$output_xml" \
        --report "$output_html" \
        "$ds_file" 2>&1 | tee /tmp/oscap-output.log; then
        log "INFO" "Scan completed successfully"
    else
        local exit_code=$?
        log "WARN" "Scan completed with exit code: $exit_code"
    fi
    
    local pass_count
    local fail_count
    local notapplicable_count
    local fixed_count
    
    pass_count=$(grep -c 'result="pass"' "$output_xml" 2>/dev/null || echo "0")
    fail_count=$(grep -c 'result="fail"' "$output_xml" 2>/dev/null || echo "0")
    notapplicable_count=$(grep -c 'result="notapplicable"' "$output_xml" 2>/dev/null || echo "0")
    fixed_count=$(grep -c 'result="fixed"' "$output_xml" 2>/dev/null || echo "0")
    
    log "INFO" "Scan Results:"
    log "INFO" "  Pass: $pass_count"
    log "INFO" "  Fail: $fail_count"
    log "INFO" "  Not Applicable: $notapplicable_count"
    log "INFO" "  Fixed: $fixed_count"
    log "INFO" "Full report: $output_html"
    
    if [[ "$fail_count" -gt 0 ]]; then
        log "WARN" "Found $fail_count failing controls - remediation may be needed"
    fi
}

generate_remediation_script() {
    local ds_file="$1"
    local output_script="$REPORT_DIR/remediation-script-$(date +%Y%m%d-%H%M%S).sh"
    
    $DRY_RUN && {
        log "INFO" "[DRY-RUN] Would generate remediation script"
        return 0
    }
    
    log "INFO" "Generating remediation script..."
    
    if sudo oscap xccdf generate fix \
        --profile "$PROFILE" \
        --fix-type bash \
        "$ds_file" | sudo tee "$output_script" >/dev/null; then
        log "INFO" "Remediation script generated: $output_script"
        
        sudo chmod +x "$output_script"
        
        if command -v shellcheck >/dev/null 2>&1; then
            shellcheck -S warning "$output_script" || true
        fi
        
        echo "$output_script"
    else
        log "ERROR" "Failed to generate remediation script"
        return 1
    fi
}

apply_remediation() {
    local script="$1"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would apply remediation from: $script"
        log "INFO" "[DRY-RUN] Script contents preview (first 50 lines):"
        head -50 "$script" | sed 's/^/    /'
        return 0
    fi
    
    log "INFO" "Applying remediation from: $script"
    log "WARN" "This will modify system settings. Press Ctrl+C to abort in 10 seconds..."
    sleep 10
    
    log "INFO" "Applying fixes..."
    if sudo bash "$script"; then
        log "INFO" "Remediation applied successfully"
        
        log "INFO" "Running post-remediation verification scan..."
        sleep 2
        
        local ds_file
        ds_file=$(download_scap_content)
        run_compliance_scan "$ds_file"
    else
        log "ERROR" "Remediation failed - check backup at: $BACKUP_DIR"
        log "ERROR" "To restore: sudo cp -rp $BACKUP_DIR/* /"
        return 1
    fi
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --auto-remediate)
                AUTO_REMEDIATE=true
                shift
                ;;
            --report)
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    log "INFO" "OpenSCAP Hardening Automation Starting..."
    log "INFO" "Dry-run mode: $DRY_RUN"
    log "INFO" "Profile: $PROFILE"
    
    check_dependencies
    
    if [[ "$AUTO_REMEDIATE" == "true" ]] && [[ "$DRY_RUN" == "false" ]]; then
        create_backup
    fi
    
    local ds_file
    ds_file=$(download_scap_content)
    
    if [[ -f "$ds_file" ]]; then
        run_compliance_scan "$ds_file"
        
        local remediation_script
        remediation_script=$(generate_remediation_script "$ds_file")
        
        if [[ "$AUTO_REMEDIATE" == "true" ]] && [[ -n "$remediation_script" ]]; then
            apply_remediation "$remediation_script"
        fi
    else
        log "ERROR" "SCAP content not available"
        
        log "INFO" "Listing available profiles from system..."
        list_available_profiles
        
        exit 1
    fi
    
    log "INFO" "OpenSCAP Hardening Complete"
    log "INFO" "Reports saved to: $REPORT_DIR"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "Run without --dry-run to apply changes"
    fi
}

main "$@"
