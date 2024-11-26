

### Copy seeded dev database and rename to prod

```bash
# scp seeded dev and rename to prod
scp ./data/database/hn-new-jobs-database-dev.sqlite3 ubuntu@arm1:/home/ubuntu/traefik-proxy/apps/hn-new-jobs/data/database/hn-new-jobs-database-prod.sqlite3

```