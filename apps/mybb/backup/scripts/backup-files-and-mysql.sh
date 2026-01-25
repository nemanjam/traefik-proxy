#!/bin/bash

#  Remote backup folder structure:
# 
# mybb/
# └─ backup/
#    ├─ scripts/
#    │  ├─ backup-files-and-mysql.sh         - versioned
#    │  └─ backup-files-and-mysql-run.sh     - this script
#    └─ data/
#       ├─ mybb_files_and_mysql-daily-2026-01-20.zip
#       │  ├─ inc/
#       │  ├─ images/custom/
#       │  └─ mysql_database/
#       │     └─ mybb.sql
#       ├─ mybb_files_and_mysql-daily-2026-01-19.zip
#       ├─ mybb_files_and_mysql-weekly-2026-01-14.zip
#       └─ mybb_files_and_mysql-monthly-2026-01-01.zip

# ---------- Configuration ----------

# MySQL credentials
DB_CONTAINER_NAME="mybb-database"
DB_NAME="mybb"
DB_USER="mybbuser"
DB_PASS="password"

# Note: all commands run from script dir, NEVER call cd, for relative paths to work

# Dirs paths
# Local folder is root, all other paths are relative to it
# script located at ~/traefik-proxy/apps/mybb/backup/scripts
LOCAL_BACKUP_DIR="../data"

# File or directory
# Relative to script dir, ../../ returns to: apps/mybb/
declare -A SRC_CODE_DIRS=(
    ["inc"]="../../data/mybb-data/inc/config.php"
    ["images/custom"]="../../data/mybb-data/images/custom"
)

# Retention
MAX_RETENTION=6 # 6 months for monthly backups
BACKUP_RETENTION_DAILY=3
BACKUP_RETENTION_WEEKLY=2
BACKUP_RETENTION_MONTHLY=6

# ---------- Logging vars ----------

# Enable only when running from cron
# Cron has no TTY, interactive shell does
LOG_TO_FILE=false
[ -z "$PS1" ] && LOG_TO_FILE=true

# Log file
LOG_FILE="./log-backup-files-and-mysql.txt"

# Log size limits (MB, float allowed)
LOG_MAX_SIZE_MB=1.0   # truncate when log exceeds this
LOG_KEEP_SIZE_MB=0.5  # keep last N MB after truncation

# Timezone for log timestamps
LOG_TIMEZONE="Europe/Belgrade"

# ---------- Constants ----------

# Zip vars
# Both inside zip
MYSQL_ZIP_DIR_NAME="mysql_database" 
FILES_ZIP_DIR_NAME="source_code"

# Must match backup-rsync-local.sh
ZIP_PREFIX="mybb_files_and_mysql"
FREQ_PLACEHOLDER='frequency'

DATE=$(date +"%Y-%m-%d")
ZIP_PATH="$LOCAL_BACKUP_DIR/$ZIP_PREFIX-$FREQ_PLACEHOLDER-$DATE.zip"

# Current day and weekday
DAY_OF_MONTH=$(date +%d)
DAY_OF_WEEK=$(date +%u) # 1=Monday … 7=Sunday

# Must do it like this for booleans
BACKUP_DAILY=$([[ $BACKUP_RETENTION_DAILY -gt 0 ]] && echo true || echo false)
BACKUP_WEEKLY=$([[ $BACKUP_RETENTION_WEEKLY -gt 0 ]] && echo true || echo false)
BACKUP_MONTHLY=$([[ $BACKUP_RETENTION_MONTHLY -gt 0 ]] && echo true || echo false)

# Script dir absolute path, unused
# mybb/backup/scripts
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
    local non_zero_found=0

    echo "[INFO] Validating configuration..."

    # Check that MySQL container is running
    if ! docker inspect -f '{{.State.Running}}' "$DB_CONTAINER_NAME" 2>/dev/null | grep -q true; then
        echo "[ERROR] MySQL container not running or not found: DB_CONTAINER_NAME=$DB_CONTAINER_NAME" >&2
        return 1
    fi

    # Check MySQL connectivity inside container
    if ! docker exec "$DB_CONTAINER_NAME" \
        mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
        echo "[ERROR] MySQL connection failed: container=$DB_CONTAINER_NAME user=$DB_USER db=$DB_NAME" >&2
        return 1
    fi

    # Check local backup directory variable is set, dir exists, and is not root
    if [ -z "$LOCAL_BACKUP_DIR" ] || [ ! -d "$LOCAL_BACKUP_DIR" ] || [ "$LOCAL_BACKUP_DIR" = "/" ]; then
        echo "[ERROR] Local backup directory invalid: path=$LOCAL_BACKUP_DIR" >&2
        return 1
    fi

    # Check source code paths exist (file or directory)
    for path in "${SRC_CODE_DIRS[@]}"; do
        if [ ! -e "$path" ]; then
            echo "[ERROR] Source path missing: path=$SCRIPT_DIR/$path" >&2
            return 1
        fi
    done

    # Validate retention values
    for var in BACKUP_RETENTION_DAILY BACKUP_RETENTION_WEEKLY BACKUP_RETENTION_MONTHLY; do
        value="${!var}"

        if [[ ! "$value" =~ ^[0-9]+$ ]]; then
            echo "[ERROR] Retention value is not a number: $var=$value" >&2
            return 1
        fi

        if (( value > MAX_RETENTION )); then
            echo "[ERROR] Retention value too large: $var=$value max=$MAX_RETENTION" >&2
            return 1
        fi

        (( value > 0 )) && non_zero_found=1
    done

    if (( non_zero_found == 0 )); then
        echo "[ERROR] All retention values are zero: daily=$BACKUP_RETENTION_DAILY weekly=$BACKUP_RETENTION_WEEKLY monthly=$BACKUP_RETENTION_MONTHLY" >&2
        return 1
    fi

    # Delete existing temp backup file for this day (idempotent, can run on same day)
    if [[ -f "$ZIP_PATH" ]]; then
        rm -f "$ZIP_PATH"
        echo "[WARN] Existing temporary backup file deleted: $ZIP_PATH"
    fi

    echo "[INFO] Configuration is valid. Creating backup..."

    return 0
}

# ------------- Logic ---------------

create_backup() {
    # Note: use staging dir with relative paths to have nice overview in GUI archive utility

    # Local scope
    # staging dir: mybb/backup/data/staging_dir
    # temp db dir: mybb/backup/data/staging_dir/mysql_database
    # working dir: mybb/backup/scripts
    local STAGING_DIR="$LOCAL_BACKUP_DIR/staging_dir"
    local TEMP_DB_DIR="$STAGING_DIR/$MYSQL_ZIP_DIR_NAME"
    local FILES_DIR="$STAGING_DIR/$FILES_ZIP_DIR_NAME"

    # Reset staging dir from previous broken state 
    rm -rf "$STAGING_DIR"
    mkdir -p "$TEMP_DB_DIR"  # Will recreate staging dir
    mkdir -p "$FILES_DIR"    # Folder to group all source code

    echo "[INFO] Created staging directory: $STAGING_DIR"
    echo "[INFO] Created temporary DB directory: $TEMP_DB_DIR"
    echo "[INFO] Created files directory: $FILES_DIR"

    # Dump MySQL as plain UTF-8 .sql
    docker exec "$DB_CONTAINER_NAME" sh -c \
        'mysqldump --no-tablespaces -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"' \
        > "$TEMP_DB_DIR/$DB_NAME.sql"

    echo "[INFO] MySQL database dumped: db_name=$DB_NAME -> path=$TEMP_DB_DIR/$DB_NAME.sql"

    # Copy source code folders grouped into FILES_DIR dir
    for SRC_CODE_DIR in "${!SRC_CODE_DIRS[@]}"; do
        SRC_CODE_DIR_PATH="${SRC_CODE_DIRS[$SRC_CODE_DIR]}"
        cp -a "$SRC_CODE_DIR_PATH" "$FILES_DIR/"
        echo "[INFO] Added to staging: $SRC_CODE_DIR_PATH -> $FILES_ZIP_DIR_NAME/"
    done

    # Remove FILES_DIR if empty
    if [ -d "$FILES_DIR" ] && [ -z "$(ls -A "$FILES_DIR")" ]; then
        rm -rf "$FILES_DIR"
        echo "[INFO] Removed empty files directory: $FILES_DIR"
    fi

    # Create zip with clean relative paths
    # ( ... ) - subshell, cd wont affect working dir of the main script
    (
        cd "$STAGING_DIR" || {
            echo "[ERROR] Failed to cd into staging directory: $STAGING_DIR" >&2
            exit 1
        }

        # There was cd in subshell
        # Adjust zip path relative to staging_dir
        zip -r "../$ZIP_PATH" .
    ) || {
        echo "[ERROR] Zip creation failed: $ZIP_PATH" >&2
        rm -rf "$STAGING_DIR"
        exit 1
    }

    echo "[INFO] Created zip archive: $ZIP_PATH"

    # Cleanup
    rm -rf "$STAGING_DIR"
    echo "[INFO] Removed staging directory: $STAGING_DIR"
    echo "[INFO] Backup file created successfully: $ZIP_PATH"
}

create_retention_copies() {
    local IS_WEEKLY=$(( DAY_OF_WEEK == 7 )) # Sunday
    local IS_MONTHLY=$(( DAY_OF_MONTH == 1 )) # First day of month

    if [[ ! -f "$ZIP_PATH" ]]; then
        echo "[ERROR] Backup file does not exist: $ZIP_PATH"
        return 1
    fi

    for FREQ in daily weekly monthly; do
        case "$FREQ" in
            daily)
                [[ "$BACKUP_DAILY" == true ]] || continue
                ;;
            weekly)
                [[ "$IS_WEEKLY" -eq 1 && "$BACKUP_WEEKLY" == true ]] || continue
                ;;
            monthly)
                [[ "$IS_MONTHLY" -eq 1 && "$BACKUP_MONTHLY" == true ]] || continue
                ;;
        esac

        TARGET_FILE="${ZIP_PATH/frequency/$FREQ}"

        # Delete existing backup for this frequency (idempotent, can run on same day)
        if [[ -f "$TARGET_FILE" ]]; then
            rm -f "$TARGET_FILE"
            echo "[WARN] Existing $FREQ backup removed: $TARGET_FILE"
        fi

        cp "$ZIP_PATH" "$TARGET_FILE"
        echo "[INFO] $FREQ backup copied successfully: $TARGET_FILE"
    done

    rm -f "$ZIP_PATH"
    echo "[INFO] Removed temporary backup file: $ZIP_PATH"
}

prune_old_backups() {
    for FREQ in daily weekly monthly; do
        # Determine retention variable dynamically
        RETENTION_VAR="BACKUP_RETENTION_${FREQ^^}"  # uppercase: daily -> DAILY
        RETENTION="${!RETENTION_VAR}"

        # Skip if retention is zero or unset
        [[ -z "$RETENTION" || "$RETENTION" -le 0 ]] && continue

        # Find old backups and delete them
        ls -t "$LOCAL_BACKUP_DIR" \
            | grep "$ZIP_PREFIX" \
            | grep "$FREQ" \
            | sed -e 1,"$RETENTION"d \
            | xargs -d '\n' -I{} rm -R "$LOCAL_BACKUP_DIR/{}" > /dev/null 2>&1

        echo "[INFO] Pruned $FREQ backups, keeping last $RETENTION"
    done
}

# ---------- Main script ----------

if ! is_valid_config; then
    echo "[ERROR] Configuration validation failed. Aborting backup." >&2
    exit 1
fi

create_backup

create_retention_copies

prune_old_backups

echo "[INFO] Backup completed successfully."