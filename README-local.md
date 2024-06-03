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
