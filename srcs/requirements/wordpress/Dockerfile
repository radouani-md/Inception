FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y \
        php-fpm \
        php-mysql \
        php-curl \
        php-gd \
        php-mbstring \
        php-xml \
        php-zip \
        wget \
        mariadb-client \
        && rm -rf /var/lib/apt/lists/*

COPY tools/start.sh /usr/local/bin/start.sh

RUN chmod +x /usr/local/bin/start.sh

RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf

ENTRYPOINT ["/usr/local/bin/start.sh"]