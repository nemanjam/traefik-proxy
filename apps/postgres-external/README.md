### Copy local `.env.local` file to server

```bash
# make volume data dir
mkdir -p ~/traefik-proxy/apps/postgres-external/pg-data

# make volumes writable for others
sudo chmod 777 -R pg-data pg-config

# postgres-external .env.local
scp ./apps/postgres-external/.env.local ubuntu@amd1:/home/ubuntu/traefik-proxy/apps/postgres-external

```
