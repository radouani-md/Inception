#!/bin/bash

# If a command fails, immediately stop the script
set -e

echo "Starting MariaDB temporarily..."

service mariadb start

echo "Creating WordPress database..."

# Send everything until the next EOF to this command as input.
# '%' any host => MariaDB needs to allow the WordPress container to connect. 

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
