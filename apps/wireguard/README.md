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

# Download client credentials

```bash
# run in LOCAL terminal

# config file
scp ubuntu@amd1:/opt/wireguard-server/config/peer1/peer1.conf  ~/Desktop/peer1.conf

# qr code for Android
scp ubuntu@amd1:/opt/wireguard-server/config/peer1/peer1.png   ~/Desktop/peer1.png

```