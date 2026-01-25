#!/bin/bash

#  Local backup folder structure:
# 
# mybb/
# └─ backup/
#    ├─ scripts/
#    │  └─ backup-rsync-local.sh     - this script
#    └─ data/
#       ├─ .gitkeep
#       ├─ mybb_files_and_mysql-daily-2026-01-20.zip
#       │  ├─ inc/
#       │  ├─ images/custom/
#       │  └─ mysql_database/
#       │     └─ mybb.sql
#       ├─ mybb_files_and_mysql-daily-2026-01-19.zip
#       ├─ mybb_files_and_mysql-weekly-2026-01-14.zip
#       └─ mybb_files_and_mysql-monthly-2026-01-01.zip

# ---------- Configuration ----------

REMOTE_HOST="arm2"
# Full, absolute path - can't use ~/, used both locally and remote with ssh/rsync
REMOTE_BACKUP_DIR="/home/ubuntu/traefik-proxy/apps/mybb/backup/data"

# Note: all commands run from script dir, NEVER call cd, for relative LOCAL paths to work
LOCAL_BACKUP_DIR="../data"

# Minimum valid backup size, ZIP size, compressed
# Only db for blank forum, zip=158.2 KiB
# Float
MIN_BACKUP_SIZE_MB=0.1
# Integer
MIN_BACKUP_SIZE_BYTES=$(echo "$MIN_BACKUP_SIZE_MB * 1024 * 1024 / 1" | bc) # rounded to integer

# ---------- Logging vars ----------

# Enable only when running from cron
# Cron has no TTY, interactive shell does
# Todo: useless, always true, fix it
LOG_TO_FILE=false
[ -z "$PS1" ] && LOG_TO_FILE=true

# Log file
LOG_FILE="./log-backup-rsync-local.txt"

# Log size limits (MB, float allowed)
LOG_MAX_SIZE_MB=1.0   # truncate when log exceeds this
LOG_KEEP_SIZE_MB=0.5  # keep last N MB after truncation

# Timezone for log timestamps
LOG_TIMEZONE="Europe/Belgrade"

# ---------- Constants ----------

# Must match backup-files-and-mysql.sh
ZIP_PREFIX="mybb_files_and_mysql"

# Script dir absolute path, unused
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- Enable logging ----------

setup_logging() {
    local max_size keep_size

    # Convert MB -> bytes (rounded down)
    max_size=$(echo "$LOG_MAX_SIZE_MB * 1024 * 1024 / 1" | bc)
    keep_size=$(echo "$LOG_KEEP_SIZE_MB * 1024 * 1024 / 1" | bc)

    # Ensure log file exists (do not truncate)
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi

    # Truncate log if too big
    local size size_mb
    size=$(stat -c%s "$LOG_FILE")
    size_mb=$(awk "BEGIN {printf \"%.2f\", $size/1024/1024}")  # convert bytes -> MB

    if (( size > max_size )); then
        tail -c "$keep_size" "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"

        # Log truncation message happens before the exec redirection, so it needs its own timestamp
        echo "$(TZ="$LOG_TIMEZONE" date '+%Y-%m-%d %H:%M:%S') [INFO] Log truncated: original_size=${size_mb}MB, max_size=${LOG_MAX_SIZE_MB}MB, keep_size=${LOG_KEEP_SIZE_MB}MB" >> "$LOG_FILE"
    fi

    # Redirect stdout + stderr to log file with timestamps
    exec > >(while IFS= read -r line; do
        echo "$(TZ="$LOG_TIMEZONE" date '+%Y-%m-%d %H:%M:%S') $line"
    done >> "$LOG_FILE") 2>&1

    # Per-run separator — just echo, timestamps added automatically
    echo
    echo "========================================"
    echo "[INFO] Logging started"
    echo "[INFO] Log file: $LOG_FILE"
    echo "[INFO] Max size: ${LOG_MAX_SIZE_MB}MB, keep: ${LOG_KEEP_SIZE_MB}MB"
    echo "========================================"
    echo
}

if [ "$LOG_TO_FILE" = true ]; then
    setup_logging
fi

# ---------- Validate config ------------

is_valid_config() {
    echo "----------------------------------------"
    echo "[INFO] Validating configuration"

    # Check SSH connectivity to remote host
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_HOST" "true" >/dev/null 2>&1; then
        echo "[ERROR] Cannot connect to remote host via SSH: REMOTE_HOST=$REMOTE_HOST" >&2
        return 1
    fi
    echo "[INFO] SSH connection established: REMOTE_HOST=$REMOTE_HOST"

    # Check remote backup directory exists
    if ! ssh "$REMOTE_HOST" "[ -d \"$REMOTE_BACKUP_DIR\" ]" >/dev/null 2>&1; then
        echo "[ERROR] Remote backup directory does not exist: REMOTE_HOST=$REMOTE_HOST REMOTE_BACKUP_DIR=$REMOTE_BACKUP_DIR" >&2
        return 1
    fi
    echo "[INFO] Remote backup directory exists: $REMOTE_BACKUP_DIR"

    # Check local backup directory exists
    if [ ! -d "$LOCAL_BACKUP_DIR" ]; then
        echo "[ERROR] Local backup directory does not exist: path=$SCRIPT_DIR/$LOCAL_BACKUP_DIR" >&2
        return 1
    fi
    echo "[INFO] Local backup directory exists: $SCRIPT_DIR/$LOCAL_BACKUP_DIR"

    echo "[INFO] Configuration validation successful"
    echo "----------------------------------------"

    return 0
}

# ------------ Utils ------------

# Extract latest YYYY-MM-DD date from backup filenames
get_latest_date() {
    sed -E 's/.*-([0-9]{4}-[0-9]{2}-[0-9]{2})\.zip/\1/' \
        | sort | tail -n 1
}

# Split a list of filenames into daily/weekly/monthly assoc array
split_backup_types() {
    local files="$1"
    declare -n arr=$2  # pass assoc array by name

    while IFS= read -r file; do
        case "$file" in
            *-daily-*.zip)   arr[daily]+="$file"$'\n' ;;
            *-weekly-*.zip)  arr[weekly]+="$file"$'\n' ;;
            *-monthly-*.zip) arr[monthly]+="$file"$'\n' ;;
        esac
    done <<< "$files"
}

# Ensure remote has at least as many backups as local
check_count() {
    local remote_count="$1"
    local local_count="$2"
    local backup_type="$3"

    if (( remote_count < local_count )); then
        echo "ERROR: remote has fewer type=$backup_type backups than local, remote_count=$remote_count, local_count=$local_count"
        return 1
    fi
}

# Ensure remote backups are not older than local
check_date() {
    local remote_latest="$1"
    local local_latest="$2"
    local backup_type="$3"

    if [[ -n "$local_latest" && "$remote_latest" < "$local_latest" ]]; then
        echo "ERROR: remote type=$backup_type backup is older than local, remote_latest=$remote_latest, local_latest=$local_latest"
        return 1
    fi
}

# Convert bytes to human-readable format
bytes_to_human() {
    local size=$1
    if (( size < 1024 )); then
        echo "${size}B"
    elif (( size < 1024*1024 )); then
        echo "$((size/1024))KB"
    elif (( size < 1024*1024*1024 )); then
        echo "$((size/1024/1024))MB"
    else
        echo "$((size/1024/1024/1024))GB"
    fi
}

# Ensure all remote backups are larger than minimum size
check_file_size() {
    local bad_file bad_file_size
    local remote_file size
    local remote_files_info

    # Store SSH output in a variable
    remote_files_info=$(ssh "$REMOTE_HOST" "
        for f in $REMOTE_BACKUP_DIR/${ZIP_PREFIX}-*.zip; do
            [ -f \"\$f\" ] || continue
            stat -c '%n %s' \"\$f\"
        done
    ")

    # Iterate over each line in the variable
    while read -r remote_file size; do
        echo "[INFO] Remote file: $remote_file, size=$(bytes_to_human $size)"

        if (( size < MIN_BACKUP_SIZE_BYTES )); then
            bad_file="$remote_file"
            bad_file_size="$size"
            break
        fi
    done <<< "$remote_files_info"

    if [[ -n "$bad_file" ]]; then
        echo "ERROR: remote backup file too small: $bad_file, size=$(bytes_to_human $bad_file_size), min=$(bytes_to_human $MIN_BACKUP_SIZE_BYTES)"
        return 1
    fi

    echo "[INFO] All remote backup files meet minimum size, min=$(bytes_to_human $MIN_BACKUP_SIZE_BYTES)"
    return 0
}

# ---------- Validation ----------

is_valid_backup() {
    echo "----------------------------------------"
    echo "[INFO] Validating backups"

    # Local variables
    local -A remote_lists local_lists
    local remote_all_files local_all_files

    # Loop variables
    local backup_type
    local remote_list local_list
    local remote_count local_count
    local remote_latest local_latest

    # Global size validation (run once)
    if ! check_file_size; then
        echo "ERROR: remote backup contains file(s) smaller than minimum size, min=$(bytes_to_human $MIN_BACKUP_SIZE_BYTES)"
        return 1
    fi
    echo "[INFO] Remote backup file sizes validated, min=$(bytes_to_human $MIN_BACKUP_SIZE_BYTES)"

    # Store remote backup filenames in a variable and split, ignores .gitkeep
    remote_all_files=$(ssh "$REMOTE_HOST" "ls -1 $REMOTE_BACKUP_DIR/${ZIP_PREFIX}-*.zip 2>/dev/null")
    split_backup_types "$remote_all_files" remote_lists
	echo "[INFO] Remote backup file list loaded for type(s):"
	echo "$remote_all_files"

    # Store local backup filenames in a variable and split
    local_all_files=$(ls -1 "$LOCAL_BACKUP_DIR/${ZIP_PREFIX}-*.zip" 2>/dev/null)
    split_backup_types "$local_all_files" local_lists
	echo "[INFO] Local backup file list loaded:"
	echo "$local_all_files"

    for backup_type in daily weekly monthly; do
        echo "[INFO] Checking backup type: $backup_type"

        # Set filename lists
        remote_list="${remote_lists[$backup_type]}"
        local_list="${local_lists[$backup_type]}"

        # Check counts
        remote_count=$(echo "$remote_list" | grep -c . || true)
        local_count=$(echo "$local_list" | grep -c . || true)
        if ! check_count "$remote_count" "$local_count" "$backup_type"; then
            echo "ERROR: backup count mismatch for type=$backup_type: remote=$remote_count is less than local=$local_count"
            return 1
        fi
        echo "[INFO] Backup count valid: type=$backup_type remote=$remote_count local=$local_count"

        # Check latest dates
        remote_latest=$(echo "$remote_list" | get_latest_date)
        local_latest=$(echo "$local_list" | get_latest_date)
        if ! check_date "$remote_latest" "$local_latest" "$backup_type"; then
            echo "ERROR: latest backup date mismatch for type=$backup_type: remote=$remote_latest is older than local=$local_latest"
            return 1
        fi
        echo "[INFO] Latest backup date valid: type=$backup_type date=$remote_latest"
    done

    echo "[INFO] Backup validation successful"
    echo "----------------------------------------"

    return 0
}

# ---------- Sync ----------

if ! is_valid_config; then
    echo "[ERROR] Configuration validation failed. Aborting script." >&2
    exit 1
fi

# Exit early if remote backup is not valid
if ! is_valid_backup; then
    echo "ERROR: Backup validation failed - aborting"
    exit 1
fi

# Note: no fallback logic for now

echo "[INFO] Remote backup valid - syncing data"

# Mirror remote data directory locally
rsync -ah --progress --delete "$REMOTE_HOST:$REMOTE_BACKUP_DIR/" "$LOCAL_BACKUP_DIR/"

echo "[INFO] Backup sync completed successfully."
