#!/bin/bash

set -e

echo "Starting WordPress container..."

mkdir -p /var/www/html

until mysqladmin ping -h"mariadb" --silent; do
    echo "[INFO] waiting for mariaDB database to be ready..."
    sleep 3
done

if [ ! -f /var/www/html/wp-load.php ]; then
    echo "Downloading WordPress..."

    wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz

    tar -xzf /tmp/wordpress.tar.gz -C /tmp

    cp -a /tmp/wordpress/. /var/www/html/

    rm -rf /tmp/wordpress /tmp/wordpress.tar.gz
fi

echo "WordPress files are ready."

exec php-fpm8.2 -F
