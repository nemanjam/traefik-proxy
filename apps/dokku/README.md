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
