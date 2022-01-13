### Copy local `.env.local` file to server

```bash
# make volume data dir
mkdir -p ~/traefik-proxy/apps/postgres-external/pg-data

# postgres-external .env.local
scp ./apps/postgres-external/.env.local ubuntu@amd1:/home/ubuntu/traefik-proxy/apps/postgres-external

```
