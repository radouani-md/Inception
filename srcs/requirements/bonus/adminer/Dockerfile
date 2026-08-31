FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y \
        php8.2-fpm \
        php8.2-mysql \
        wget \
        && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html

RUN wget -O /var/www/html/index.php \
    https://www.adminer.org/latest.php

RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf

CMD ["php-fpm8.2", "-F"]