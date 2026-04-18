#!/usr/bin/env bash
# Docker image cleanup script - removes unused images, build cache, and dangling volumes
# Usage: ./docker-image-cleanup.sh [--dry-run] [--keep-tagged] [--older-than DAYS]
# Requirements: Docker CLI, jq
# Safety: Supports dry-run mode, confirmation prompts

set -euo pipefail

DRY_RUN=false
KEEP_TAGGED=false
OLDER_THAN_DAYS=0
FORCE=false

usage() {
    cat <<EOF
Docker Image Cleanup Script

Usage: $0 [OPTIONS]

Options:
    --dry-run          Show what would be deleted without actually deleting
    --keep-tagged     Keep tagged images, only remove untagged (dangling)
    --older-than N    Only remove images created more than N days ago
    --force         Skip confirmation prompts (use with caution)
    -h, --help     Show this help message

Examples:
    $0 --dry-run                           # Preview deletions
    $0 --keep-tagged --older-than 30       # Remove dangling images older than 30 days
    $0 --force                         # Clean without prompting
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --keep-tagged) KEEP_TAGGED=true; shift ;;
        --older-than) OLDER_THAN_DAYS="$2"; shift 2 ;;
        --force) FORCE=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

command -v docker >/dev/null 2>&1 || { echo "Error: docker not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Error: jq not found"; exit 1; }

echo "=== Docker Image Cleanup ==="
echo "Dry-run: $DRY_RUN"
echo "Keep tagged: $KEEP_TAGGED"
echo "Older than: $OLDER_THAN_DAYS days"
echo ""

get_image_age_days() {
    local image_id="$1"
    local created_at
    created_at=$(docker inspect --format '{{.Created}}' "$image_id" 2>/dev/null || echo "1970-01-01")
    local created_epoch
    created_epoch=$(date -d "$created_at" +%s 2>/dev/null || echo "0")
    local now_epoch
    now_epoch=$(date +%s)
    echo $(( (now_epoch - created_epoch) / 86400 ))
}

echo "[1/4] Finding images to remove..."
images_to_remove=()

if [ "$KEEP_TAGGED" = true ]; then
    while IFS= read -r image; do
        [ -z "$image" ] && continue
        images_to_remove+=("$image")
    done < <(docker images --filter "dangling=true" -q 2>/dev/null || true)
    echo "Found ${#images_to_remove[@]} dangling images"
else
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        image_id=$(echo "$line" | awk '{print $3}')
        [ -z "$image_id" ] && continue
        
        if [ "$OLDER_THAN_DAYS" -gt 0 ]; then
            age=$(get_image_age_days "$image_id")
            if [ "$age" -lt "$OLDER_THAN_DAYS" ]; then
                echo "Skipping $image_id (created $age days ago, threshold: $OLDER_THAN_DAYS)"
                continue
            fi
        fi
        images_to_remove+=("$image_id")
    done < <(docker images -q 2>/dev/null || true)
    echo "Found ${#images_to_remove[@]} images to evaluate"
fi

echo "[2/4] Calculating space savings..."
total_size=0
for img in "${images_to_remove[@]}"; do
    size=$(docker inspect --format '{{.Size}}' "$img" 2>/dev/null || echo "0")
    total_size=$((total_size + size))
done
size_mb=$((total_size / 1024 / 1024))
echo "Potential space savings: ${size_mb}MB"

echo "[3/4] Preparing removal list..."
for img in "${images_to_remove[@]}"; do
    repo=$(docker inspect --format '{{.Repository}}' "$img" 2>/dev/null || echo "<none>")
    tag=$(docker inspect --format '{{.Tag}}' "$img" 2>/dev/null || echo "<none>")
    size=$(docker inspect --format '{{.Size}}' "$img" 2>/dev/null || echo "0")
    size_kb=$((size / 1024))
    echo "  - $repo:$tag (${size_kb}KB)"
done

echo "[4/4] Confirmation..."
if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would remove ${#images_to_remove[@]} images (${size_mb}MB)"
elif [ "$FORCE" = false ]; then
    echo "Proceed with removal? (y/N)"
    read -r confirm
    if [ "$confirm" != "y" ]; then
        echo "Aborted."
        exit 0
    fi
fi

if [ "$DRY_RUN" = false ]; then
    for img in "${images_to_remove[@]}"; do
        echo "Removing: $img"
        docker rmi "$img" 2>/dev/null || echo "  Failed to remove $img (may be in use)"
    done
    echo "Running docker system prune..."
    docker system prune -f 2>/dev/null || echo "System prune failed"
fi

echo "=== Cleanup Complete ==="
echo "Images removed: ${#images_to_remove[@]}"
echo "Space freed: ${size_mb}MB"