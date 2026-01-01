
# MyBB

- URL: https://rpi.varalicar.rs
- PHP info: https://rpi.varalicar.rs/info.php
- Adminer: https://adminer.rpi.varalicar.rs

## References

- https://github.com/mybb/docker/tree/master
- https://github.com/GARIBALDOSSAURO/docker-mybb-nginx
- https://github.com/Steppenstreuner/mybb-docker
- https://github.com/mybb/mybb

## Build MyBB image

```bash
# build
docker compose build mybb
# build with logs, e.g. RUN ls -la
docker compose build --no-cache --progress=plain mybb


# tag
docker tag mybb:1.8.39 nemanjamitic/mybb:1.8.39

# push
docker login
docker push nemanjamitic/mybb:1.8.39

```