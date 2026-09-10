FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y \
        wget \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/portainer/portainer/releases/download/2.39.1/portainer-2.39.1-linux-amd64.tar.gz \
    -O /tmp/portainer.tar.gz && \
    mkdir -p /opt/portainer && \
    tar -xzf /tmp/portainer.tar.gz -C /opt/portainer --strip-components=1 && \
    rm /tmp/portainer.tar.gz


CMD ["/opt/portainer/portainer"]