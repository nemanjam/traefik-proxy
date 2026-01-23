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
# Relative to script dir
declare -A SRC_CODE_DIRS=(
    ["inc"]="../../data/mybb-data/inc/config.php"
    ["images/custom"]="../../data/mybb-data/images/custom"
)

# Retention
MAX_RETENTION=5
BACKUP_RETENTION_DAILY=3
BACKUP_RETENTION_WEEKLY=2
BACKUP_RETENTION_MONTHLY=2

# ---------- Constants ----------

# Zip vars
MYSQL_ZIP_DIR="mysql_database"
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

    # Check local backup directory exists
    if [ ! -d "$LOCAL_BACKUP_DIR" ]; then
        echo "[ERROR] Local backup directory missing: path=$SCRIPT_DIR/$LOCAL_BACKUP_DIR" >&2
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

        if (( value >= MAX_RETENTION )); then
            echo "[ERROR] Retention value too large: $var=$value (max=$((MAX_RETENTION - 1)))" >&2
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
    ZIP_SOURCES=()

    TEMP_DB_DIR="$LOCAL_BACKUP_DIR/$MYSQL_ZIP_DIR"
    mkdir -p "$TEMP_DB_DIR"
    echo "[INFO] Created temporary DB directory: $TEMP_DB_DIR"

    # Dump MySQL as plain .sql, path is on host
    docker exec "$DB_CONTAINER_NAME" sh -c 'mysqldump --no-tablespaces -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"' > "$TEMP_DB_DIR/$DB_NAME.sql"
    echo "[INFO] MySQL database dumped: $DB_NAME -> $TEMP_DB_DIR/$DB_NAME.sql"

    # Add database to zip sources
    ZIP_SOURCES+=("$TEMP_DB_DIR")

    # Add source code folders
    for SRC_CODE_DIR in "${!SRC_CODE_DIRS[@]}"; do
        SRC_CODE_DIR_PATH="${SRC_CODE_DIRS[$SRC_CODE_DIR]}"
        ZIP_SOURCES+=("$SRC_CODE_DIR_PATH")
        echo "[INFO] Added folder or file to zip sources: $SRC_CODE_DIR_PATH"
    done

    # Create zip archive
    zip -r "$ZIP_PATH" "${ZIP_SOURCES[@]}"
    echo "[INFO] Created temp zip archive: $ZIP_PATH"

    # Cleanup temp DB dir
    rm -rf "$TEMP_DB_DIR"
    echo "[INFO] Removed temporary DB directory: $TEMP_DB_DIR"

    echo "[INFO] Temporary backup file created successfully: $ZIP_PATH"
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

    rm -rf "$ZIP_PATH"
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
