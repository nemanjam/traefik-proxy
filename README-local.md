1. clone
2. set public key and token in `rathole.client.toml`
3. create `.env` file and fill in vars

```bash
cp .env.example .env

```

4. acme.json create and chmod

```bash
touch ~/homelab/traefik-proxy/core/traefik-data/acme.json

sudo chmod 600 ~/homelab/traefik-proxy/core/traefik-data/acme.json
```

5. create proxy network

```bash
docker network create proxy
```
6. run containers

```bash
# up must be at end

docker compose -f docker-compose.local.yml up -d
```

6. uncomment staging certificate, must clear contents of old acme.json

```bash
truncate -s 0 acme.json
```

## For OrangePi, the only difference

```yaml
# docker-compose.local.yml

# doesn't exist image for arm, build it
rathole:
    # image: rapiz1/rathole:v0.5.0
    build: https://github.com/rapiz1/rathole.git#main
    platform: linux/arm64

# set platform, not necessary
traefik:
    image: 'traefik:v2.9.8'
    platform: linux/arm64

portainer:
    image: 'portainer/portainer-ce'
    platform: linux/arm64

```
#### Always start with staging Acme server and change on success

```yaml
# core/traefik-data/traefik.yml

certificatesResolvers:
  letsencrypt:
    acme:
      # always start with staging certificate
      caServer: "https://acme-staging-v02.api.letsencrypt.org/directory"
      # caServer: 'https://acme-v02.api.letsencrypt.org/directory'
```

