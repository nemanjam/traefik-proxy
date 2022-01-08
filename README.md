# Reference

Forked from [rafrasenberg/docker-traefik-portainer](https://github.com/rafrasenberg/docker-traefik-portainer) and [dbartumeu/docker-traefik-portainer](https://github.com/dbartumeu/docker-traefik-portainer)


# Docker container management with Traefik v2 and Portainer

A configuration set-up for a Traefik v2 reverse proxy along with Portainer and Docker Compose.

This set-up makes container management & deployment a breeze and the reverse proxy allows for running multiple applications on one Docker host. Traefik will route all the incoming traffic to the appropriate docker containers and through the open-source app Portainer you can speed up software deployments, troubleshoot problems and simplify migrations.

## Prerequisites

### docker

```bash
apt update && apt upgrade
```

```bash
apt install apt-transport-https ca-certificates curl software-properties-common && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
```

Make sure we are installing it from docker:

```bash
apt-cache policy docker-ce
apt install docker-ce
```

Testing installation:

```bash
systemctl status docker
```

### docker compose

```bash
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
```

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

### Copy local `.env` file to server

```bash
scp ./core/.env ubuntu@amd1:/home/ubuntu/traefik-proxy/core

```

### III. Create the proxy network

```bash
docker network create proxy
```

### IV. Give the proper permissions to acme.json

```bash
sudo chmod 600 ~/traefik-proxy/core/traefik-data/acme.json
```

### V. Run the stack

```
sudo docker-compose up -d
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

---
---

# Docker container management with Traefik v2 and Portainer

A configuration set-up for a Traefik v2 reverse proxy along with Portainer and Docker Compose.

This set-up makes container management & deployment a breeze and the reverse proxy allows for running multiple applications on one Docker host. Traefik will route all the incoming traffic to the appropriate docker containers and through the open-source app Portainer you can speed up software deployments, troubleshoot problems and simplify migrations.

Detailed explanation how to use this in my blog post:
[Docker container management with Traefik v2 and Portainer](https://rafrasenberg.com/posts/docker-container-management-with-traefik-v2-and-portainer/)

## How to run it?

```
$ git clone https://github.com/rafrasenberg/docker-traefik-portainer ./src
$ cd src/core
$ docker-compose up -d
```
