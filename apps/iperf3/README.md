
# Iperf

- https://github.com/nerdalert/iperf3
- https://hub.docker.com/r/networkstatic/iperf3/tags


```bash
# set SITE_HOSTNAME for docker-compose.yml
cp .env.example .env

# run client
iperf3 -c iperf.local.nemanjamitic.com -p 443

```