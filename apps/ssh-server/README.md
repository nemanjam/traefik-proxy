- https://hub.docker.com/r/linuxserver/openssh-server

```bash
cp .env.example .env

ssh -R 1081:localhost:3000 amd1c

curl https://preview.amd1.nemanjamitic.com

```

- Enable port forwarding in ssh config

```bash
sudo nano /etc/ssh/sshd_config

AllowTcpForwarding yes
GatewayPorts yes

sudo systemctl restart sshd

```