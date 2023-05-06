FROM dokku/dokku:0.30.3

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get -qq -y --no-install-recommends install curl apparmor

RUN (curl -sSL "https://github.com/buildpacks/pack/releases/download/v0.28.0/pack-v0.28.0-linux-arm64.tgz" | sudo tar -C /usr/local/bin/ --no-same-owner -xzv pack)

RUN pack trust-builder gliderlabs/herokuish:latest-20


