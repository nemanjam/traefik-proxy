# Traefik proxy

Traefik v2 reverse proxy that enables hosting multuple Docker containers on a single server mapped to different subdomains with Let's Encrypt ssl certificate.

## References

#### Forked from:

- original repo with Traefik configuration, Portainer: [rafrasenberg/docker-traefik-portainer](https://github.com/rafrasenberg/docker-traefik-portainer) and [tutorial](https://rafrasenberg.com/docker-compose-traefik-v2)
- fork with added env variables and Readme: [dbartumeu/docker-traefik-portainer](https://github.com/dbartumeu/docker-traefik-portainer)

## Related projects

- [nemanjam/nextjs-prisma-boilerplate](https://github.com/nemanjam/nextjs-prisma-boilerplate)

## Installed containers

#### core:

- Traefik `traefik:v2.5.6`
- Portainer `portainer/portainer-ce:2.9.3`

#### apps:

- Uptime kuma `louislam/uptime-kuma` - measure website uptime
- Adminer `adminer:4.8.1-standalone` - administer Postgres databases
- Postgres external `postgres:14.3-bullseye` - db container independant from Traefik, configured to accept remote connections on port `5433`
- Nextjs Prisma boilerplate `nemanjamitic/nextjs-prisma-boilerplate:latest` - full stack Next.js application with `postgres:14.3-bullseye` internal database

## Installation (core containers)

Environment variables needed for `core/docker-compose.yml`.

```bash
# core/.env

TRAEFIK_LETSENCRYPT_EMAIL=myemail@gmail.com
SERVER_HOSTNAME=localhost3000.live
TRAEFIK_AUTH=
```

Copy local .env files to server.

```bash
# core .env
scp ./core/.env ubuntu@amd1:/home/ubuntu/traefik-proxy/core
# uptime-kuma .env
scp ./apps/uptime-kuma/.env ubuntu@amd1:/home/ubuntu/traefik-proxy/apps/uptime-kuma
```

#### Main Traefik setup.

```bash
# server terminal

# get src
git clone https://github.com/nemanjam/traefik-proxy

# create credentials
echo $(htpasswd -nb <username> <password>)

# if htpasswd not defined
sudo apt-get install apache2-utils

# create proxy network
docker network create proxy

# create acme.json
touch ~/traefik-proxy/core/traefik-data/acme.json

# give proper permissions to acme.json
sudo chmod 600 ~/traefik-proxy/core/traefik-data/acme.json
# backup file
cp ~/traefik-proxy/core/traefik-data/acme.json ~/acme.json.bak

```

#### Run `core/docker-compose.yml`

```bash
docker-compose up -d
docker-compose down
docker-compose start
docker-compose stop
```

#### Renew Let's Encrypt certificate manually

[tutorial](https://traefik.io/blog/how-to-force-update-lets-encrypt-certificates/)

```bash
# -rw------- 1 ubuntu ubuntu 42335 May 15 10:45 acme.json

# download acme.json
scp ubuntu@amd1:/home/ubuntu/traefik-proxy/core/traefik-data/acme.json ./core/traefik-data/acme.json

# remove all from array
"Certificates": []

# push back edited to server
# chmod stays same 600
# -rw------- 1 ubuntu ubuntu 3533 Jul 10 15:27 acme.json
scp ./core/traefik-data/acme.json ubuntu@amd1:/home/ubuntu/traefik-proxy/core/traefik-data/acme.json

# restart traefik
docker-compose down
docker-compose up -d

# backup on server
scp ./core/traefik-data/acme.json ubuntu@amd1:/home/ubuntu/acme.json.back
```

## Run Next.js Prisma Boilerplate

Set in `~/.bashrc` and reload terminal.

```bash
# ~/.bashrc
export MY_UID=$(id -u)
export MY_GID=$(id -g)

# check with
printenv MY_UID
```

Variables for `apps/nextjs-prisma-boilerplate/.env`.

```bash
# apps/nextjs-prisma-boilerplate/.env

# alternative 1 - all in a single .env file forwarded by docker-compose.yml

# public vars (app container) -----------------------------------------------

APP_ENV=live

# http node server in live, Traefik handles https
SITE_PROTOCOL=http

# real full production public domain (with subdomain), used in app and Traefik
SITE_HOSTNAME=nextjs-prisma-boilerplate.localhost3000.live
PORT=3001

# real url is https and doesn't have port, Traefik handles https and port
NEXTAUTH_URL=https://${SITE_HOSTNAME}

# private vars (postgres and app containers) ----------------------------------

# db container
POSTGRES_HOSTNAME=npb-db-live
POSTGRES_PORT=5432
POSTGRES_USER=postgres_user
POSTGRES_PASSWORD=
POSTGRES_DB=npb-db-live

# app container, used in schema.prisma, expand it immediately
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOSTNAME}:${POSTGRES_PORT}/${POSTGRES_DB}?schema=public

# current host user as non-root user in db container, set it here
MY_UID=1001
MY_GID=1001

# or better globally in ~/.bashrc
# export MY_UID=$(id -u)
# export MY_GID=$(id -g)

# -------
# app container, next-auth vars

# jwt secret
SECRET=RANDOM_STRING

# Facebook
FACEBOOK_CLIENT_ID=
FACEBOOK_CLIENT_SECRET=

# Google
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
```

#### Copy local `.env` file

```bash
scp ./apps/nextjs-prisma-boilerplate/.env ubuntu@amd1:~/traefik-proxy/apps/nextjs-prisma-boilerplate
```

#### Manual redeployment

```bash
cd /home/ubuntu/traefik-proxy/apps/nextjs-prisma-boilerplate && \
docker-compose down && \
docker image rm nemanjamitic/nextjs-prisma-boilerplate:latest && \
docker-compose up -d
```

Update `docker-compose.yml` itself `git pull`, `git checkout .`...

## Run Postgres external

#### Copy local `.env.local` file to server

```bash
# postgres-external .env.local
scp ./apps/postgres-external/.env.local ubuntu@amd1:/home/ubuntu/traefik-proxy/apps/postgres-external
```

On host data folder will be at `apps/postgres-external/pg-data/data-external`. With `postgres:14.3-bullseye` and `user: '${MY_UID}:${MY_GID}'` it will be created as current user, and not as root.

#### Enable remote hosts

```yml
# override config
command: postgres -p 5433 -c config_file=/etc/postgresql.conf
volumes:
  - ./pg-config/postgresql.conf:/etc/postgresql.conf
  - ./pg-config/pg_hba.conf:/etc/pg_hba.conf
```

Detailed explanation...

## Adding a new app container

Adminer example. Traefik only needs `subdomain.domain.com` and `port`, that's it.

```yml
# apps/adminer/docker-compose.yml

# adminer.${SERVER_HOSTNAME} - subdomain.domain.com
# 8080 - port

services:
  adminer:
    image: 'adminer:4.8.1-standalone'
    container_name: adminer
    networks:
      - proxy
    labels:
      - 'traefik.enable=true'
      - 'traefik.docker.network=proxy'
      - 'traefik.http.routers.adminer-https.rule=Host(`adminer.${SERVER_HOSTNAME}`)'
      - 'traefik.http.routers.adminer-https.entrypoints=websecure'
      - 'traefik.http.services.adminer-svc.loadbalancer.server.port=8080'

networks:
  proxy:
    external: true
```
