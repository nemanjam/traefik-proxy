### Dokku routed through Traefik

- Dokku dns setup [docs](https://dokku.com/docs/networking/dns/)
- `docker-compose.yml` [example1](https://gist.github.com/GegeDesembri/9e5a49b4c49f6136e2b5b3e7af373c8e), [example2](https://gist.github.com/joshghent/39fa894630b55bd32aabf2bd09544ba3)
- generate ssh keys [tutorial](https://linuxize.com/post/how-to-set-up-ssh-keys-on-ubuntu-20-04/)
- Dokku Docker installation [docs](https://dokku.com/docs/getting-started/install/docker/)
- Dokku install on host [freecodecamp](https://www.freecodecamp.org/news/how-to-build-your-on-heroku-with-dokku/)

### Generate key at /home/username/.ssh/id_rsa (on Desktop, for Git)

```bash

ssh-keygen -t rsa -b 4096 -C "your_email@domain.com"

# move to (chmod 600):
~/.ssh/oracle_amd1/dokku_docker_amd1__id_rsa
~/.ssh/oracle_amd1/dokku_docker_amd1__id_rsa.pub
```

#### add to ~/.ssh/config

```bash
# Dokku docker amd1
Host dokku.localhost3000.live
    HostName dokku.localhost3000.live
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/oracle_amd1/dokku_docker_amd1__id_rsa
    Port 3022
```

- open 3022 (as destination port) on server

### Add public key to dokku container (on server)

```bash
# on desktop
# temp copy pub key to server to home folder
scp ~/.ssh/oracle_amd1/dokku_docker_amd1__id_rsa.pub ubuntu@amd1:/home/ubuntu/dokku_docker_amd1__id_rsa.pub

# on server
# prefix to exec commands in container (no need to enter container)
docker exec -it dokku bash

# list keys
docker exec -it dokku bash dokku ssh-keys:list

# copy key in /tmp in container (maybe add shared volume)
# container id changes every time
docker cp /home/ubuntu/dokku_docker_amd1__id_rsa.pub d0b2477737d5:/tmp/


# check if copied
# enter container
docker exec -it dokku bash
# list /tmp/
ls -la

# add SSH key from container to Dokku
docker exec -it dokku bash dokku ssh-keys:add admin /tmp/dokku_docker_amd1__id_rsa.pub

# list keys
docker exec -it dokku bash dokku ssh-keys:list

# delete temp key
docker exec -it dokku bash
rm -rf ./dokku_docker_amd1__id_rsa.pub
ls -la

```

### Deploy an app from src (this builds image on server - needs RAM)

- deploy app [docs](https://dokku.com/docs/deployment/application-deployment/)

```bash
# 1. without database

# on server (in dokku container)
# for url: lure-shop-react.dokku.localhost3000.live
docker exec -it dokku bash dokku apps:create lure-shop-react

# add remote (in local app git repo)
git remote add dokku dokku@dokku.localhost3000.live:lure-shop-react
git push dokku master:master


```

### Deploy app from Docker image

- [docs](https://dokku.com/docs/deployment/methods/git/#initializing-an-app-repository-from-a-docker-image)

---

#### Aliases

```
nano ~/.bashrc

# exec dokku in container
alias dokkuc="docker exec -it dokku bash dokku"

# docker compose up/down
alias dcdown="docker compose down"
alias dcup="docker compose up -d"

# reload shell to apply
source ~/.bashrc
```

## Add public key to dokku container (on server) - simpler way

### Reset Dokku container

```bash
# remove dokku container
ssh ubuntu@arm1 "
cd ~/traefik-proxy/apps/dokku &&
docker compose down
"

# delete dokku volume
ssh ubuntu@arm1 "
sudo rm -rf ~/traefik-proxy/apps/dokku/dokku-data &&
ls -la ~/traefik-proxy/apps/dokku
"

# start dokku container
ssh ubuntu@arm1 "
cd ~/traefik-proxy/apps/dokku &&
docker compose up -d
"
```

#### Oneliner set local key to remote container

```bash
# set key, works multiline
scp ~/.ssh/oracle/dokku_docker__id_rsa.pub ubuntu@arm1:/tmp/ && \
ssh ubuntu@arm1 " \
  docker exec -i dokku bash dokku ssh-keys:add admin < /tmp/dokku_docker__id_rsa.pub && \
  rm /tmp/dokku_docker__id_rsa.pub \
"

# remove key
ssh ubuntu@arm1 "docker exec dokku bash dokku ssh-keys:remove admin"

# list keys
ssh ubuntu@arm1 "docker exec dokku bash dokku ssh-keys:list"

```

# Prepare ARM server for buildpacks - IMPORTANT

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
```

# Attach all app containers to traefik and dokku external network - IMPORTANT

```bash
dokku network:set --global initial-network proxy
```

### Add remote, create app and push

```bash
# add remote
git remote add dokku dokku@dokku.arm1.localhost3002.live:nextjs-app

# create app
dokku apps:create nextjs-app

# list all apps
dokku apps:list

# check app networks
dokku network:report nextjs-app

# list all networks
dokku network:list

# push
git push dokku main:main
```

### Setup Lets Encrypt

```bash
# lista all installed plugins
dokku plugin:list

# check if letsencrypt is installed
# it is included in apps/dokku/dokku-data/plugin-list
dokku plugin:installed letsencrypt

# if not installed already
dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git

# set global email for all apps
# cant be set per app...
dokku config:set --global DOKKU_LETSENCRYPT_EMAIL= miroljub.petrovic.acc@gmail.com

# enable for app
dokku letsencrypt:enable nextjs-app

# check for app
dokku letsencrypt:active nextjs-app

# enable auto-renewal
dokku letsencrypt:cron-job --add
```

### Start, stop, rebuild app

```bash
# debug all config
dokku config:show nextjs-app

# debug processes
dokku ps:report

# debug ports
dokku proxy:ports nextjs-app

# stop
dokku ps:stop nextjs-app

# start
dokku ps:start nextjs-app

# rebuild, redeploy app
dokku ps:rebuild nextjs-app

# test https, -v
curl http://nextjs-app.dokku.arm1.localhost3002.live
curl https://nextjs-app.dokku.arm1.localhost3002.live

# disable hsts nginx
dokku nginx:set --global hsts false

# debug domains
dokku domains:report --global
dokku domains:report nextjs-app

# debug nginx - default proxy
dokku nginx:show-config
```

### Volume and env var must match - ${PWD}/dokku-data

```yaml
environment:
  - DOKKU_HOST_ROOT=${PWD}/dokku-data/home/dokku
volumes:
  - ${PWD}/dokku-data:/mnt/dokku
```

### Set custom buildpacks

```bash
# pack installed in Dockerfile

# report
dokku buildpacks:report

# set globally
dokku buildpacks:set-property --global stack paketobuildpacks/builder:base

# unset globally, reset to default gliderlabs/herokuish:latest
dokku buildpacks:set-property --global stack

# possible buildpack options
# must run in js app folder
ubuntu@arm1:~/NODE-JS-APP$ pack builder suggest
Suggested builders:
Google:                gcr.io/buildpacks/builder:v1
Heroku:                heroku/builder:22
Heroku:                heroku/buildpacks:20
Paketo Buildpacks:     paketobuildpacks/builder:base
Paketo Buildpacks:     paketobuildpacks/builder:full
Paketo Buildpacks:     paketobuildpacks/builder:tiny
```
