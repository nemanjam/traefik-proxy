
# MyBB

URL: https://mybb.rpi.nemanjamitic.com

## References

https://github.com/mybb/docker/tree/master
https://github.com/GARIBALDOSSAURO/docker-mybb-nginx
https://github.com/Steppenstreuner/mybb-docker
https://github.com/mybb/mybb

## Build MyBB image

```bash
# build
docker compose build mybb

# tag
docker tag mybb:1.8.39 nemanjamitic/mybb:1.8.39

# push
docker login
docker push nemanjamitic/mybb:1.8.39

```