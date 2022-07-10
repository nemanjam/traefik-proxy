### Copy local `.env.local` file to server

```bash
# postgres-external .env.local
scp ./apps/postgres-external/.env.local ubuntu@amd1:/home/ubuntu/traefik-proxy/apps/postgres-external
```

On host data folder will be at `apps/postgres-external/pg-data/data-external`.

This is not needed with `postgres:14.3-bullseye` and `user: '${MY_UID}:${MY_GID}'`.

```bash

# make volume data dir
mkdir -p ~/traefik-proxy/apps/postgres-external/pg-data

# make volumes writable for others
sudo chmod 777 -R pg-data pg-config

# clean pg-data
rm -r pg-data/*
```
