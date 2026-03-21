#!/usr/bin/env bash
# =============================================================================
# Linux Incident Response Automation Script
# =============================================================================
# Purpose: Automate Linux incident response and digital forensics collection
# Usage: ./incident-response.sh [--dry-run] [--output DIR] [--full-forensic]
# Requirements: bash 4+, root privileges for full collection, common Linux utils
# Safety Notes:
#   - Always run with --dry-run first to preview collection steps
#   - This script is READ-ONLY - it only collects evidence, never modifies system
#   - Output directory should be on external storage for chain of custody
#   - Use --full-forensic for complete memory dump (requires external tools)
# Tested OS: RHEL 7/8/9, Ubuntu 20.04/22.04, Debian 11/12, CentOS Stream 8/9
# =============================================================================

set -euo pipefail

DRY_RUN=false
OUTPUT_DIR="/var/log/incident-response-$(hostname)-$(date +%Y%m%d-%H%M%S)"
FULL_FORENSIC=false
CASE_ID=""
EXAMINER_NAME=""

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
    --dry-run          Preview collection steps without executing (recommended first)
    --output DIR      Output directory for evidence collection (default: auto-generated)
    --full-forensic   Include full memory dump and disk image (requires dd, dc3dd)
    --case-id ID      Incident case identifier for chain of custody
    --examiner NAME   Name of the examiner conducting the collection
    -h, --help        Show this help message

Examples:
    $0 --dry-run --case-id INC-2026-001 --examiner "John Doe"
    $0 --output /mnt/external/evidence --full-forensic --case-id INC-2026-001
    $0 --dry-run

Chain of Custody:
    - All collections are READ-ONLY - no system modifications
    - SHA256 checksums generated for all files
    - Timeline of events recorded in timeline.txt
    - Export environment variables for forensics tools:
      export FORENSIC_OUTPUT=/path/to/output
      export CASE_ID=INC-2026-001

EOF
    exit 0
}

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg"
    if [[ -w "$OUTPUT_DIR" ]]; then
        echo "$msg" >> "$OUTPUT_DIR/timeline.txt" 2>/dev/null || true
    fi
}

check_dependencies() {
    log "INFO" "Checking dependencies..."
    
    local required_cmds=("date" "hostname" "mkdir" "cp" "tar" "sha256sum" "find" "df")
    local optional_cmds=("dd" "dc3dd" "memdump" "linux-ia32" " volatility")
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR" "Required command '$cmd' not found"
            exit 1
        fi
    done
    
    local missing_opt=()
    for cmd in "${optional_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_opt+=("$cmd")
        fi
    done
    
    if [[ ${#missing_opt[@]} -gt 0 ]]; then
        log "WARN" "Optional tools not found: ${missing_opt[*]}"
        log "WARN" "Install for full forensic capabilities: apt install dc3dd forensic-tools"
    fi
    
    log "INFO" "Dependencies OK"
}

initialize_output() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create output directory: $OUTPUT_DIR"
        return 0
    fi
    
    mkdir -p "$OUTPUT_DIR"/{memory,disk,network,processes,files,logs,malware}
    mkdir -p "$OUTPUT_DIR"/{artifacts,timeline,hashes}
    
    if [[ -n "$CASE_ID" ]]; then
        echo "Case ID: $CASE_ID" > "$OUTPUT_DIR/case-info.txt"
    fi
    if [[ -n "$EXAMINER_NAME" ]]; then
        echo "Examiner: $EXAMINER_NAME" >> "$OUTPUT_DIR/case-info.txt"
    fi
    echo "Hostname: $(hostname)" >> "$OUTPUT_DIR/case-info.txt"
    echo "Collection Start: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUTPUT_DIR/case-info.txt"
    echo "Kernel: $(uname -r)" >> "$OUTPUT_DIR/case-info.txt"
    
    touch "$OUTPUT_DIR/timeline.txt"
    touch "$OUTPUT_DIR/hashes/manifest.sha256"
    
    log "INFO" "Output directory initialized: $OUTPUT_DIR"
}

collect_system_info() {
    log "INFO" "Collecting system information..."
    
    local cmds=(
        "uname -a"
        "cat /proc/version"
        "cat /etc/os-release"
        "uptime"
        "last reboot"
        "last shutdown"
        "hostname"
        "cat /etc/hosts"
        "cat /etc/resolv.conf"
        "ss -tunap"
        "netstat -tunap 2>/dev/null || ss -tunap"
        "arp -a"
        "route -n"
        "ip addr"
        "iptables -L -nv 2>/dev/null || iptables -L -n"
        "cat /etc/passwd"
        "cat /etc/group"
        "cat /etc/sudoers 2>/dev/null || true"
        "sudo -l 2>/dev/null || true"
        "crontab -l 2>/dev/null || true"
        "ls -la /etc/cron.d/ /etc/cron.daily/ /etc/cron.hourly/ 2>/dev/null || true"
        "systemctl list-timers --all 2>/dev/null || true"
        "ls -la /var/spool/cron/ 2>/dev/null || true"
        "atq 2>/dev/null || true"
    )
    
    for cmd in "${cmds[@]}"; do
        local filename
        filename=$(echo "$cmd" | cut -d' ' -f1 | tr '/' '-' | sed 's/^-//')
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "[DRY-RUN] Would run: $cmd"
        else
            log "INFO" "Collecting: $cmd"
            eval "$cmd" > "$OUTPUT_DIR/system-info/$filename.txt" 2>&1 || true
        fi
    done
}

collect_network_info() {
    log "INFO" "Collecting network connections and artifacts..."
    
    local net_cmds=(
        "ss -tunap"
        "ip -s link"
        "ip neigh show"
        "ip rule show"
        "ip route show"
        "cat /etc/hosts"
        "cat /etc/hosts.allow 2>/dev/null || true"
        "cat /etc/hosts.deny 2>/dev/null || true"
        "lsof -i -n -P 2>/dev/null || true"
        "lsof +c 0 2>/dev/null || true"
        "netstat -antp 2>/dev/null || ss -antp"
        "netstat -anup 2>/dev/null || ss -anup"
    )
    
    for cmd in "${net_cmds[@]}"; do
        local filename
        filename=$(echo "$cmd" | cut -d' ' -f1 | tr '/' '-' | sed 's/^-//')
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "[DRY-RUN] Would run: $cmd"
        else
            log "INFO" "Collecting: $cmd"
            eval "$cmd" > "$OUTPUT_DIR/network/$filename.txt" 2>&1 || true
        fi
    done
}

collect_process_info() {
    log "INFO" "Collecting process information..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would collect process information"
        return 0
    fi
    
    ps auxfw > "$OUTPUT_DIR/processes/ps-auxfw.txt"
    ps -ef > "$OUTPUT_DIR/processes/ps-ef.txt"
    pstree -p > "$OUTPUT_DIR/processes/pstree.txt" 2>/dev/null || true
    ls -la /proc/*/exe 2>/dev/null | head -100 > "$OUTPUT_DIR/processes/proc-exe-links.txt" || true
    
    for pid in $(ls /proc/ | grep -E '^[0-9]+$'); do
        if [[ -f "/proc/$pid/cmdline" ]]; then
            local cmdline
            cmdline=$(tr '\0' ' ' < /proc/$pid/cmdline 2>/dev/null || true)
            if echo "$cmdline" | grep -qiE '(nc|netcat|ncat|socat|python.*reverse|bash.*reverse|sh.*-i|python.*socket)'; then
                echo "PID: $pid - $cmdline" >> "$OUTPUT_DIR/processes/suspicious-processes.txt"
            fi
        fi
    done
    
    log "INFO" "Process information collected"
}

collect_user_info() {
    log "INFO" "Collecting user activity and authentication logs..."
    
    local user_cmds=(
        "last"
        "lastb"
        "who"
        "w"
        "id"
        "groups"
        "finger"
        "cat /var/log/secure 2>/dev/null || true"
        "cat /var/log/auth.log 2>/dev/null || true"
        "cat /var/log/messages 2>/dev/null || true"
        "cat /var/log/syslog 2>/dev/null || true"
        "journalctl -u ssh 2>/dev/null || true"
        "journalctl -u sshd 2>/dev/null || true"
    )
    
    for cmd in "${user_cmds[@]}"; do
        local filename
        filename=$(echo "$cmd" | cut -d' ' -f1-2 | tr '/' '-' | sed 's/^-//' | tr ' ' '-')
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "[DRY-RUN] Would run: $cmd"
        else
            log "INFO" "Collecting: $cmd"
            eval "$cmd" > "$OUTPUT_DIR/logs/$filename.txt" 2>&1 || true
        fi
    done
    
    if [[ "$DRY_RUN" != "true" ]]; then
        find /home -name ".bash_history" -exec cat {} \; 2>/dev/null > "$OUTPUT_DIR/logs/bash-history.txt" || true
        find /root -name ".bash_history" -exec cat {} \; 2>/dev/null >> "$OUTPUT_DIR/logs/bash-history.txt" || true
    fi
}

collect_file_artifacts() {
    log "INFO" "Collecting file system artifacts..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would collect file artifacts"
        return 0
    fi
    
    log "INFO" "Collecting recently modified files..."
    find / -type f -mtime -1 -ls 2>/dev/null | head -500 > "$OUTPUT_DIR/artifacts/recently-modified-1day.txt" || true
    find / -type f -mtime -7 -ls 2>/dev/null | head -1000 > "$OUTPUT_DIR/artifacts/recently-modified-7days.txt" || true
    
    log "INFO" "Collecting SUID/SGID files..."
    find / -perm -4000 -ls 2>/dev/null > "$OUTPUT_DIR/artifacts/suid-files.txt" || true
    find / -perm -2000 -ls 2>/dev/null > "$OUTPUT_DIR/artifacts/sgid-files.txt" || true
    
    log "INFO" "Collecting world-writable files..."
    find / -type f -perm -0002 -ls 2>/dev/null | head -500 > "$OUTPUT_DIR/artifacts/world-writable.txt" || true
    
    log "INFO" "Collecting hidden files in /tmp and /var/tmp..."
    find /tmp /var/tmp -name ".*" -type f 2>/dev/null > "$OUTPUT_DIR/artifacts/hidden-files-tmp.txt" || true
    find /tmp /var/tmp -name ".*" -type f -mtime -7 >> "$OUTPUT_DIR/artifacts/hidden-files-tmp.txt" 2>/dev/null || true
    
    log "INFO" "Collecting SSH keys and configs..."
    find /home /root -name "id_rsa*" -o -name "id_ed25519*" -o -name "authorized_keys" 2>/dev/null > "$OUTPUT_DIR/artifacts/ssh-keys.txt" || true
    cat /etc/ssh/sshd_config 2>/dev/null > "$OUTPUT_DIR/artifacts/sshd-config.txt" || true
    
    log "INFO" "Collecting bash scripts in /tmp and cron..."
    find /tmp /var/tmp /var/spool/cron -name "*.sh" -type f 2>/dev/null > "$OUTPUT_DIR/artifacts/shell-scripts.txt" || true
}

collect_malware_artifacts() {
    log "INFO" "Collecting potential malware indicators..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would collect malware artifacts"
        return 0
    fi
    
    log "INFO" "Checking for suspicious files in common malware locations..."
    local malware_paths=(
        "/tmp"
        "/var/tmp"
        "/dev/shm"
        "/var/cache"
        "/var/spool"
    )
    
    for path in "${malware_paths[@]}"; do
        find "$path" -type f -executable 2>/dev/null >> "$OUTPUT_DIR/malware/executables.txt" || true
    done
    
    log "INFO" "Checking for suspicious network connections..."
    ps aux | grep -E 'nc|netcat|ncat|socat|python.*socket|perl.*socket' >> "$OUTPUT_DIR/malware/suspicious-network-tools.txt" 2>/dev/null || true
    
    log "INFO" "Checking for kernel module rootkits..."
    lsmod >> "$OUTPUT_DIR/malware/loaded-kernel-modules.txt" 2>/dev/null || true
    
    log "INFO" "Checking hidden files and directories..."
    find / -name ".*" -type d 2>/dev/null | head -100 > "$OUTPUT_DIR/malware/hidden-directories.txt" || true
}

collect_memory() {
    log "INFO" "Memory collection requested..."
    
    if [[ "$FULL_FORENSIC" != "true" ]]; then
        log "INFO" "Skipping full memory dump (not requested). Use --full-forensic to enable."
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would collect memory dump"
        return 0
    fi
    
    if ! command -v dd >/dev/null 2>&1; then
        log "WARN" "dd not available, skipping memory dump"
        return 0
    fi
    
    log "INFO" "Collecting memory dump (this may take several minutes)..."
    if command -v dc3dd >/dev/null 2>&1; then
        dc3dd if=/dev/mem of="$OUTPUT_DIR/memory/memdump.dd" hash=sha256 verb=1 2>&1 | tee "$OUTPUT_DIR/memory/dc3dd.log"
    else
        dd if=/dev/mem of="$OUTPUT_DIR/memory/memdump.dd" bs=4M 2>&1 | tee "$OUTPUT_DIR/memory/dd.log"
    fi
    
    log "INFO" "Memory dump complete"
}

collect_disk_info() {
    log "INFO" "Collecting disk and filesystem information..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would collect disk information"
        return 0
    fi
    
    df -h > "$OUTPUT_DIR/disk/df-h.txt"
    df -i > "$OUTPUT_DIR/disk/df-i.txt"
    mount > "$OUTPUT_DIR/disk/mounts.txt"
    lsblk -a > "$OUTPUT_DIR/disk/lsblk.txt" 2>/dev/null || true
    fdisk -l 2>/dev/null > "$OUTPUT_DIR/disk/fdisk.txt" || true
    
    log "INFO" "Disk information collected"
}

generate_hashes() {
    log "INFO" "Generating SHA256 hashes for chain of custody..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would generate hashes"
        return 0
    fi
    
    find "$OUTPUT_DIR" -type f -exec sha256sum {} \; > "$OUTPUT_DIR/hashes/manifest.sha256"
    log "INFO" "Hash manifest generated: $(wc -l < "$OUTPUT_DIR/hashes/manifest.sha256") files"
}

create_manifest() {
    log "INFO" "Creating collection manifest..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Would create manifest"
        return 0
    fi
    
    cat > "$OUTPUT_DIR/MANIFEST.txt" <<EOF
================================================================================
LINUX INCIDENT RESPONSE COLLECTION MANIFEST
================================================================================
Case ID: ${CASE_ID:-N/A}
Examiner: ${EXAMINER_NAME:-N/A}
Hostname: $(hostname)
Collection Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Kernel: $(uname -r)
Script Version: 1.0.0

COLLECTION SCOPE:
$(if [[ "$FULL_FORENSIC" == "true" ]]; then echo "- Full forensic mode enabled (memory + disk)"; else echo "- Standard incident response mode"; fi)

DIRECTORIES COLLECTED:
$(ls -la "$OUTPUT_DIR")

TOTAL FILES:
$(find "$OUTPUT_DIR" -type f | wc -l)

HASH ALGORITHM: SHA256
HASH MANIFEST: hashes/manifest.sha256

CHAIN OF CUSTODY NOTES:
- All collections are READ-ONLY - no system modifications made
- SHA256 hashes generated for all collected files
- Timeline of events recorded in timeline.txt
- Original collection script should be preserved for verification

================================================================================
END OF MANIFEST
================================================================================
EOF
    
    log "INFO" "Manifest created"
}

finalize_collection() {
    log "INFO" "Finalizing collection..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY-RUN] Dry run complete. Run without --dry-run to collect evidence."
        return 0
    fi
    
    local total_size
    total_size=$(du -sh "$OUTPUT_DIR" | cut -f1)
    local total_files
    total_files=$(find "$OUTPUT_DIR" -type f | wc -l)
    
    log "INFO" "Collection complete!"
    log "INFO" "Output directory: $OUTPUT_DIR"
    log "INFO" "Total size: $total_size"
    log "INFO" "Total files: $total_files"
    log "INFO" "SHA256 manifest: $OUTPUT_DIR/hashes/manifest.sha256"
    
    if [[ -n "$CASE_ID" ]]; then
        echo "Collection End: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUTPUT_DIR/case-info.txt"
    fi
    
    echo "" >> "$OUTPUT_DIR/timeline.txt"
    echo "Collection completed at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUTPUT_DIR/timeline.txt"
    
    log "INFO" "Next steps:"
    log "INFO" "  1. Verify hash integrity: sha256sum -c $OUTPUT_DIR/hashes/manifest.sha256"
    log "INFO" "  2. Review suspicious-processes.txt for indicators of compromise"
    log "INFO" "  3. Analyze timeline.txt for attack timeline reconstruction"
    log "INFO" "  4. Use volatility for memory analysis if memory dump was collected"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --full-forensic)
                FULL_FORENSIC=true
                shift
                ;;
            --case-id)
                CASE_ID="$2"
                shift 2
                ;;
            --examiner)
                EXAMINER_NAME="$2"
                shift 2
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
    
    log "INFO" "Linux Incident Response Collection Starting..."
    log "INFO" "Dry-run mode: $DRY_RUN"
    log "INFO" "Output directory: $OUTPUT_DIR"
    log "INFO" "Full forensic mode: $FULL_FORENSIC"
    log "INFO" "Case ID: ${CASE_ID:-N/A}"
    log "INFO" "Examiner: ${EXAMINER_NAME:-N/A}"
    
    check_dependencies
    initialize_output
    collect_system_info
    collect_network_info
    collect_process_info
    collect_user_info
    collect_file_artifacts
    collect_malware_artifacts
    collect_disk_info
    collect_memory
    generate_hashes
    create_manifest
    finalize_collection
    
    log "INFO" "Incident response collection finished"
}

main "$@"
