### Copy local `.env.local` file to server

```bash
# make volume data dir
mkdir -p ~/traefik-proxy/apps/nextjs-prisma-boilerplate/prisma/pg-data

# make volumes writable for others
# cant load schema.prisma...?
sudo chmod 777 -R prisma uploads

-rw-rw-r--  1 ubuntu ubuntu 2545 Jan 14 13:43 schema.prisma
-rw-rw-r--  1 ubuntu ubuntu 4301 Jan 14 13:43 seed.js


# clean pg-data
rm -r pg-data/*

# .env.local and .env.production - for container variables
# .env for docker-compose.yml

# .env.local
scp ./apps/nextjs-prisma-boilerplate/.env.local ubuntu@amd1:~/traefik-proxy/apps/nextjs-prisma-boilerplate

# .env for docker-compose.yml
scp ./apps/nextjs-prisma-boilerplate/.env ubuntu@amd1:~/traefik-proxy/apps/nextjs-prisma-boilerplate

```
