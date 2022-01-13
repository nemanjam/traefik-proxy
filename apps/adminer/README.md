### Copy local `.env` files to server

```bash
# adminer .env
scp ./apps/adminer/.env ubuntu@amd1:/home/ubuntu/traefik-proxy/apps/adminer

```

# Adminer custom port

- set e.g. localhost:5432 in the server field
