#!/bin/bash

set -e

echo "starting WordPress container..."

mkdir -p /var/www/html


if [ ! -f /var/www/html/wp-load.php ]; then
    echo "downloading WordPress..."

    wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz

    tar -xzf /tmp/wordpress.tar.gz -C /tmp

    cp -a /tmp/wordpress/. /var/www/html/

    rm -rf /tmp/wordpress /tmp/wordpress.tar.gz
fi
echo " wordPress files are ready."

until mysqladmin ping -h"mariadb" --silent; do
    echo "waiting for mariaDB database to be ready..."
    sleep 3
done

if [ ! -f /var/www/html/wp-config.php ]; then

    echo "creating wp-config.php"

    wp config create \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$MYSQL_PASSWORD" \
    --dbhost="$DB_HOST" \
    --allow-root \
    --path=/var/www/html
    else
        echo "wp-confiq.php is already exist"     
fi

if ! wp core is-installed --allow-root --path=/var/www/html; then

    echo "installing wordpress"

    wp core install \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --allow-root \
    --path=/var/www/html

    echo "create a second user ..."

    wp user create "$WP_AU_USER" "$WP_AU_EMAIL_USER" \
    --user_pass="$WP_AU_PASSWORD" \
    --role="author" \
    --allow-root \
    --path=/var/www/html

    echo "Installing Redis Object Cache..."

    wp plugin install redis-cache \
        --activate \
        --allow-root \
        --path=/var/www/html

    wp config set WP_REDIS_HOST redis \
        --type=constant \
        --allow-root \
        --path=/var/www/html

    wp config set WP_REDIS_PORT 6379 \
        --raw \
        --type=constant \
        --allow-root \
        --path=/var/www/html

    wp redis enable \
        --allow-root \
        --path=/var/www/html


else
    echo "WordPress is already installed"
fi


exec php-fpm8.2 -F
