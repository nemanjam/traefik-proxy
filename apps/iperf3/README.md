
# Iperf

- https://github.com/nerdalert/iperf3
- https://hub.docker.com/r/networkstatic/iperf3/tags


```bash
# set SITE_HOSTNAME for docker-compose.yml
cp .env.example .env

# run client
# iperf, works...
iperf -c iperf3.local.nemanjamitic.com -p 80

# iperf3, fails
iperf3 -c iperf3.local.nemanjamitic.com --cport 80

```

- **iperf cant run through Traefik, must use separate port on Rathole, it's tcp, not http or https**
- maybe this https://github.com/librespeed/speedtest
- examples iperf3 calls with frp here https://github.com/rapiz1/rathole/blob/main/docs/benchmark.md and here https://blog.mni.li/posts/tailscale-vs-rathole-speed/