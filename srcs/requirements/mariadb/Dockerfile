FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY --chmod=755 tools/mariadb_scr.sh /usr/local/bin/mariadb_scr.sh


ENTRYPOINT ["usr/local/bin/mariadb_scr.sh"]
