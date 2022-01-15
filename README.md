# Traefik proxy

Traefik v2 reverse proxy that enables hosting multuple Docker containers on a single server mapped to different subdomains with Let's Encrypt certificate.

## References

**Forked from:**

- original repo with Traefik configuration, Portainer: [rafrasenberg/docker-traefik-portainer](https://github.com/rafrasenberg/docker-traefik-portainer) and tutorial: [here](https://rafrasenberg.hashnode.dev/docker-container-management-with-traefik-v2-and-portainer)
- fork with added env variables and Readme: [dbartumeu/docker-traefik-portainer](https://github.com/dbartumeu/docker-traefik-portainer)

## Installed containers

**core:**

- Traefik `traefik:v2.5.6`
- Portainer `portainer/portainer-ce:2.9.3`

**apps:**

- Uptime kuma `louislam/uptime-kuma` - measure website uptime
- Adminer `adminer:4.8.1-standalone` - administer Postgres databases
- Postgres external `postgres:14-alpine` - db container independant from Traefik, configured to accept remote connections on port 5433
- Nextjs Prisma boilerplate `nemanjamitic/nextjs-prisma-boilerplate:latest` - full stack Next.js application with `postgres:14-alpine` internal database

## Installation and running

## Install Nextjs Prisma boilerplate

## Configure Postgres container for remote connections

## Adding a new app container

---

---

---

---

## How to run it?

### I. Clone the repo

```bash
git clone https://github.com/dbartumeu/docker-traefik-portainer ./src && cd src/core
```

### II. Create credentials

Make sure your server has htpasswd installed. If it doesn’t you can do so with the following command:

```bash
sudo apt-get install apache2-utils
```

Then run the below command, replacing the `username` and `password` with the one you want to use.

```bash
echo $(htpasswd -nb <username> <password>)
```

### Copy local `.env` files to server

```bash
# core .env
scp ./core/.env ubuntu@amd1:/home/ubuntu/traefik-proxy/core

# uptime-kuma .env
scp ./apps/uptime-kuma/.env ubuntu@amd1:/home/ubuntu/traefik-proxy/apps/uptime-kuma

```

### III. Create the proxy network

```bash
docker network create proxy
```

### IV. Give the proper permissions to acme.json

```bash
sudo chmod 600 ~/traefik-proxy/core/traefik-data/acme.json

# backup
cp ~/traefik-proxy/core/traefik-data/acme.json ~/acme.json.bak
```

### V. Run the stack

```
docker-compose up -d

docker-compose down

docker-compose start

docker-compose stop
```

## Adding services

Using Create stack in portainer copy and paste the dockerfile and make sure to include in the dockerfile:

```yml
services:
    ...
    networks:
      - proxy
      - default
    labels:
        - "traefik.enable=true"
        - "traefik.docker.network=proxy"
        - "traefik.http.routers.myservice.entrypoints=websecure"
        - "traefik.http.routers.myservice.rule=Host(`myservice.yourdomain.com`)"
        - "traefik.http.services.myservice.loadBalancer.server.port=myserviceport"

networks:
  proxy:
    external: true
  default:
```

Make sure to change `myservice`, `myservice.yourdomain.com` and `myserviceport` for meaningful values.
