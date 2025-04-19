- https://hub.docker.com/r/linuxserver/openssh-server

```bash
cp .env.example .env

# MUST have *: before, important
ssh -R *:1081:localhost:3000 amd1c


curl https://preview1.amd1.nemanjamitic.com

```

- Enable port forwarding in ssh config

```bash
sudo nano /etc/ssh/sshd_config

AllowTcpForwarding yes
GatewayPorts yes

sudo systemctl restart sshd

```
ssh 1080 -> 2222 // ssh channel
http 1081 for traefik
localhost:3000 -> tunnel:1081 -> traefik // tunnel1

https://github.com/linuxserver/docker-openssh-server/issues/22

https://github.com/linuxserver/docker-mods/tree/openssh-server-ssh-tunnel

enable prod letsencrypt url in traefik.yml

Multiple tunnels:

```bash
ssh \
  -R *:1081:localhost:3000 \
  -R *:1082:localhost:3000 \
  amd1c
```