#!/bin/bash

set -e

echo "Starting MariaDB temporarily..."

service mariadb start

echo "Creating WordPress database..."

mariadb -u root << EOF

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

echo "WordPress database configured."

service mariadb stop

echo "Starting MariaDB..."

exec mariadbd --user=mysql
