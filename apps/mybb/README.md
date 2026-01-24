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

## Crons

```bash
# Remote

# Local sync

```
