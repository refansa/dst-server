#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# backup.sh — DST world backup (runs inside the dst-backup container)
#
# Reads the world from /data/save/Cluster_1 (shared read-only volume),
# creates a timestamped ZIP in /data/backups/, validates it, and
# prunes old archives. Optionally triggers c_save() on the master
# before the snapshot via the Docker socket.
#
# Environment variables (all optional):
#   SKIP_C_SAVE=1       skip the pre-backup c_save() trigger
#   RETENTION_COUNT=30  max number of backup archives to keep
#   RETENTION_DAYS=14   max age in days (ignored when COUNT is set)
#   BACKUP_DIR=/data/backups
#   CLUSTER_DIR=/data/save/Cluster_1
# ──────────────────────────────────────────────────────────────
set -euo pipefail

# ── Config ────────────────────────────────────────────
SKIP_C_SAVE="${SKIP_C_SAVE:-0}"
RETENTION_COUNT="${RETENTION_COUNT:-30}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
BACKUP_DIR="${BACKUP_DIR:-/data/backups}"
CLUSTER_DIR="${CLUSTER_DIR:-/data/save/Cluster_1}"
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
ARCHIVE_NAME="Cluster_1-${TIMESTAMP}.zip"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"

# ── Pre-flight ────────────────────────────────────────
echo "[backup] $(date '+%Y-%m-%dT%H:%M:%S%z') — starting"
echo "[backup] Cluster: ${CLUSTER_DIR}"

if [ ! -d "$CLUSTER_DIR" ]; then
    echo "[backup] ERROR: Cluster directory does not exist: ${CLUSTER_DIR}"
    exit 1
fi

mkdir -p "$BACKUP_DIR"

# ── Step 1: c_save() via docker socket ────────────────
if [ "$SKIP_C_SAVE" != "1" ] && [ -S /var/run/docker.sock ]; then
    echo "[backup] Sending c_save() to dst-master ..."
    if docker exec -i dst-master sh -c 'echo "c_save()" > /proc/1/fd/0' 2>/dev/null; then
        echo "[backup] c_save() sent. Waiting 5s for flush ..."
        sleep 5
    else
        echo "[backup] WARNING: c_save() failed (container may not be running). Proceeding."
    fi
elif [ "$SKIP_C_SAVE" == "1" ]; then
    echo "[backup] Skipping c_save() (SKIP_C_SAVE=1)"
else
    echo "[backup] WARNING: Docker socket not available. Skipping c_save()."
fi

# ── Step 2: Stage a clean copy ────────────────────────
echo "[backup] Staging world data ..."

STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

STAGE_CLUSTER="${STAGING}/Cluster_1"
mkdir -p "$STAGE_CLUSTER"

# Copy into staging, excluding server-rotated logs and temp data
tar -cf - \
    --exclude='backup' \
    --exclude='server_temp' \
    --exclude='*.old' \
    -C "$CLUSTER_DIR" . | tar -xf - -C "$STAGE_CLUSTER"

# ── Step 3: Create ZIP ───────────────────────────────
echo "[backup] Compressing ..."

cd "$STAGING"
zip -qr "$ARCHIVE_PATH" Cluster_1
cd /data

ARCHIVE_SIZE=$(stat -c%s "$ARCHIVE_PATH" 2>/dev/null)
ARCHIVE_SIZE_MB=$(echo "scale=2; ${ARCHIVE_SIZE:-0} / 1048576" | bc 2>/dev/null || echo "unknown")
echo "[backup] Created: ${ARCHIVE_NAME} (${ARCHIVE_SIZE_MB} MB)"

# ── Step 4: Validate ZIP integrity ───────────────────
echo "[backup] Validating archive ..."
if unzip -t "$ARCHIVE_PATH" >/dev/null 2>&1; then
    ENTRY_COUNT=$(unzip -l "$ARCHIVE_PATH" 2>/dev/null | tail -1 | awk '{print $2}')
    echo "[backup] OK — ${ENTRY_COUNT} entries"
else
    echo "[backup] ERROR: Archive validation failed"
    rm -f "$ARCHIVE_PATH"
    exit 1
fi

# ── Step 5: Prune old backups ────────────────────────
echo "[backup] Pruning old backups (keep: ${RETENTION_COUNT}, max age: ${RETENTION_DAYS}d) ..."

# Keep the N most recent files regardless of age
COUNT=0
while IFS= read -r -d '' f; do
    COUNT=$((COUNT + 1))
    AGE_DAYS=$(( ( $(date +%s) - $(stat -c%Y "$f" 2>/dev/null) ) / 86400 ))

    DELETE=0
    if [ "$COUNT" -gt "$RETENTION_COUNT" ]; then
        DELETE=1
    elif [ "$AGE_DAYS" -gt "$RETENTION_DAYS" ]; then
        DELETE=1
    fi

    if [ "$DELETE" == "1" ]; then
        echo "[backup] Pruning: $(basename "$f") (age: ${AGE_DAYS}d)"
        rm -f "$f"
    fi
done < <(find "$BACKUP_DIR" -maxdepth 1 -name 'Cluster_1-*.zip' -print0 | sort -z)

REMAINING=$(find "$BACKUP_DIR" -maxdepth 1 -name 'Cluster_1-*.zip' | wc -l)
echo "[backup] Total backups on disk: ${REMAINING}"
echo "[backup] $(date '+%Y-%m-%dT%H:%M:%S%z') — done"
