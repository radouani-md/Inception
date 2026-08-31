FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y redis-server && \
    rm -rf /var/lib/apt/lists/*

CMD ["redis-server", "--bind", "0.0.0.0", "--protected-mode", "no"]