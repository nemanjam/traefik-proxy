
# Iperf

- https://github.com/nerdalert/iperf3
- https://hub.docker.com/r/networkstatic/iperf3/tags


```bash
# set SITE_HOSTNAME for docker-compose.yml
cp .env.example .env

# run client
# iperf, works
iperf -c iperf3.local.nemanjamitic.com -p 80

# iperf3, fails
iperf3 -c iperf3.local.nemanjamitic.com --cport 80

```