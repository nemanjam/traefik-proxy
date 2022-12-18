# MERN Boilerplate

- 2 images, client and server

### Copy local `.env` to server

```bash
# run from traefik-proxy folder
scp ./apps/mern-boilerplate/.env ubuntu@amd1:~/traefik-proxy/apps/mern-boilerplate
```

### Connect to Mongo docker-compose

- append `?authSource=admin`
- **Important: must delete files in `server/docker/mongo-data` volume to reconnect**

```bash
# MongoError: Authentication failed
# from mern-boilerplate folder
sudo rm -rf ./server/docker/mongo-data/*

MONGO_URI_PROD=mongodb://username:$password@mongo-service:27017/db-name?authSource=admin
```
