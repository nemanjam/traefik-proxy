# MyBB

- URL: https://rpi.varalicar.rs
- PHP info: https://rpi.varalicar.rs/info.php
- Adminer: https://adminer.rpi.varalicar.rs

## References

- https://github.com/mybb/docker/tree/master
- https://github.com/GARIBALDOSSAURO/docker-mybb-nginx
- https://github.com/Steppenstreuner/mybb-docker
- https://github.com/mybb/mybb

## Build MyBB image

```bash
# build
docker compose build mybb
# build with logs, e.g. RUN ls -la
docker compose build --no-cache --progress=plain mybb


# tag
docker tag mybb:1.8.39 nemanjamitic/mybb:1.8.39

# push
docker login
docker push nemanjamitic/mybb:1.8.39
```

## Restore MySQL backup in Docker

```bash
# Run just MySQL container
# This creates new database by default
docker compose up -d database

# Import the dump into the new database
# -p pdb_password without space, intentionally
docker exec -i mybb-database mysql -u db_user -pdb_password new_db_name < .path/to/dump.sql

# Example
docker exec -i mybb-database mysql -u mybbuser -pmybbpass mybb < ./mybb.sql

# NO NEED, created by default
# Create a new database inside the container
# -p pdb_password without space, intentionally
docker exec -i mybb-database mysql -u db_user -pdb_password -e "CREATE DATABASE new_db_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Example
docker exec -i mybb-database mysql -u mybbuser -pmybbpass -e "CREATE DATABASE mybb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

## Cron

Edit cron:

```bash
crontab -e

# Edit ...

# Make scripts executable

# Remote
chmod +x /home/ubuntu/traefik-proxy/apps/mybb/backup/scripts/run-backup-files-and-mysql.sh

# Local
chmod +x /home/username/mybb-backup/scripts/run-backup-rsync-local.sh
```

Since cron has no environment, always use absolute paths for script paths (no `~/` for home dir).

Lines to add:

```bash
# Remote

# Important:
# Cron must run from local .../scripts folder for relative paths to work
# Cron must use bash for redirection to file to work
# Use exact /usr/bin/bash (which bash), because /bin/bash breaks relative paths

# Debug cron execution with every minute
# * * * * * cd /home/username/mybb-backup/scripts && /usr/bin/bash ./run-backup-rsync-local.sh

# Set Belgrade time zone for all crons
TZ=Europe/Belgrade

# Create backup every day at 23:30 Belgrade time
30 23 * * * cd /home/ubuntu/traefik-proxy/apps/mybb/backup/scripts && /usr/bin/bash ./run-backup-files-and-mysql.sh

# Local

# Set Belgrade time zone for all crons
TZ=Europe/Belgrade

# Sync backup every day at 23:45 Belgrade time
45 23 * * * cd /home/username/mybb-backup/scripts && /usr/bin/bash ./run-backup-rsync-local.sh
```
