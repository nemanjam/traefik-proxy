# MERN Boilerplate

- 2 images, client and server

#### Copy local `.env` file to server

```bash
# run from traefik-proxy folder
scp ./apps/mern-boilerplate/.env ubuntu@arm1:~/traefik-proxy/apps/mern-boilerplate
```

#### Troubleshooting MongoDB connection running in a container

##### Error 1: `MongoError: Authentication failed`

- Solution: append `?authSource=admin` to connection string
- **Important:** must delete files in `server/docker/mongo-data` volume

```bash
sudo rm -rf ./server/docker/mongo-data/* # doesn't delete files with .
sudo rm -rf ./server/docker/mongo-data/.mongodb
```

- example of a working MongoDB url:

```bash
MONGO_URI_PROD=mongodb://username:$password@mongo-service:27017/db-name?authSource=admin
```

##### Error 2: `MongooseServerSelectionError: getaddrinfo EAI_AGAIN mdp-mongo`

- Solution 1: add default network in `docker-compose.yml` mongo and server services

```yml
networks:
  - default
```

- Solution 2: append `&directConnection=true` to connection string

### Traefik routes

```yml
# this doesnt work
- 'traefik.http.routers.mb-server-secure.rule=Host(`${SITE_HOSTNAME}`) && PathPrefix(`/(api|public/images)/`)'

# must do it like this
- 'traefik.http.routers.mb-client-secure.rule=Host(`${SITE_HOSTNAME}`) && !(PathPrefix(`/api`) || PathPrefix(`/auth`) || PathPrefix(`/public/images`))'
- 'traefik.http.routers.mb-server-secure.rule=Host(`${SITE_HOSTNAME}`) && (PathPrefix(`/api`) || PathPrefix(`/auth`) || PathPrefix(`/public/images`))'
```

- update readme
- update redirect urls in google and facebook
- buy new domain
