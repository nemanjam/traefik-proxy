# Wireguard Docker setup

### Tutorials

- Create your own VPN server with WireGuard in Docker - The Digital Life [Youtube](https://www.youtube.com/watch?v=GZRTnP4lyuo), [Github](https://github.com/xcad2k/videos/tree/main/wireguard-docker)
- How to add/install Wireguard on Oracle Cloud to create your own VPN - Sauber-Lab UK [Youtube](https://www.youtube.com/watch?v=ocsVUGjVSpI)
- Run WireGuard VPN Server in Docker Container with Docker Compose [tutorial](https://techviewleo.com/run-wireguard-server-in-docker-container)

### Get IP into env var

- get public IP command [stackexchange](https://unix.stackexchange.com/questions/22615/how-can-i-get-my-external-ip-address-in-a-shell-script)

**~/.bashrc**

```bash
# export server public IP v4
export MY_PUBLIC_SERVER_IP_V4=$(dig @resolver4.opendns.com myip.opendns.com +short)
```

**reload shell and check var**

```bash
source ~/.bashrc
printenv MY_PUBLIC_SERVER_IP_V4
```

### Open port in firewall

- add `UDP 51820` as destination port in server firewall

### Create config folder

```bash
sudo mkdir /opt/wireguard-server
```

### Run and check Wireguard

```bash
# check if running and peers
docker exec -it wireguard wg

# cd config folder
cd /opt/wireguard-server/config
ls

```

### Download client credentials

```bash
# run in LOCAL terminal

# config file for Ubuntu client
scp ubuntu@amd1:/opt/wireguard-server/config/peer1/peer1.conf  ~/Desktop/peer1.conf

# qr code for Android
scp ubuntu@amd1:/opt/wireguard-server/config/peer1/peer1.png   ~/Desktop/peer1.png

# copy config folder
scp -r ubuntu@152.70.160.21:/opt/wireguard-server/config   ~/Desktop/wireguard-config
scp -r ~/Desktop/wireguard-config username@192.168.1.77:~/Desktop/wireguard-config
```

### Display QR code for a client

- better just copy png with scp above

```bash
# for peer2 ie
docker exec -it wireguard /app/show-peer 2
```

### Install and run client on Ubuntu

```bash
# install client and dns for wg-quick
sudo apt install wireguard resolvconf

# copy as wg0.conf to client (run this from client terminal)
scp ubuntu@amd1:/opt/wireguard-server/config/peer1/peer1.conf  /etc/wireguard/wg0.conf

# run Wireguard on client
wg-quick up wg0

# shut down
wg-quick down wg0

# check if client is connected
sudo wg

# check on server
docker exec -it wireguard wg
```

### Restart and recreate if `docker-compose.yml` is edited (peers number)

```bash
docker-compose up -d --force-recreate
```

#### Exclude LAN from tunnel

```bash
# peer1.conf

AllowedIPs = 0.0.0.0/0, ::/0, !192.168.1.0/24

```
