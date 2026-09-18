FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=755 tools/mariadb_scr.sh /mariadb_scr.sh


ENTRYPOINT ["/mariadb_scr.sh"]
