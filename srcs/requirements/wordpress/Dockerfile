FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y \
        php8.2-fpm \
        php8.2-mysql \
        php8.2-redis \
        mariadb-client \
        curl \
        && rm -rf /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
   && chmod +x /usr/local/bin/wp

COPY tools/start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh

RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf

ENTRYPOINT ["/usr/local/bin/start.sh"]