#!/bin/bash

set -e

echo "Starting MariaDB temporarily..."

service mariadb start

echo "Creating WordPress database..."


if [ ! -f /var/lib/mysql/.root_password_set ]; then

mariadb -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
EOF
touch /var/lib/mysql/.root_password_set
fi  

mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" << EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
SHUTDOWN;
EOF


echo "WordPress database configured."

echo "Starting MariaDB..."

exec mariadbd --user=mysql