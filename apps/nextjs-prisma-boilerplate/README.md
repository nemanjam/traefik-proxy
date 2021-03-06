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

### to reflect NEXTAUTH_URL in `.env.production` change you must rebuild container

- gateway timeout error, nextjs should be only on a single network (proxy external)

- git restore . // discard git changes
- git pull
-
- cd traefik-proxy/apps/nextjs-prisma-boilerplate/
- docker-compose down
- docker image rm nemanjamitic/nextjs-prisma-boilerplate:latest
- docker-compose up -d // will do pull

### New deployment

- add global env vars to `~/.bashrc` and restart terminal, ssh

```bash
# UID and GID env vars for Docker volumes permissions
export MY_UID=$(id -u)
export MY_GID=$(id -g)
```

- check with `printenv MY_UID`

- copy single `.env` file, alternative 1

```bash
# .env for docker-compose.yml
scp ./apps/nextjs-prisma-boilerplate/.env ubuntu@amd1:~/traefik-proxy/apps/nextjs-prisma-boilerplate
```

- must remove image, or pass some arg or up

```bash
# ssh action...
cd /home/ubuntu/traefik-proxy/apps/nextjs-prisma-boilerplate
# stop and remove containers
docker-compose down
# remove image
docker image rm nemanjamitic/nextjs-prisma-boilerplate:latest
# pull and run
docker-compose up -d # will do pull
# ----
# this pulls new image but also leaves old image to take space, dont use it
docker-compose pull
```

- single line sh Github Action

```bash
cd /home/ubuntu/traefik-proxy/apps/nextjs-prisma-boilerplate && \
docker-compose down && \
docker image rm nemanjamitic/nextjs-prisma-boilerplate:latest && \
docker-compose up -d
```
