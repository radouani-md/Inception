# Wordpress

## 1. CONFIG

### Why do we use it?

NONE

### COMMANDS

NONE

## 2. Dockerfile

## `RUN` — Installing Dependencies

```dockerfile
RUN apt-get update && \
    apt-get install -y \
        php8.2-fpm \
        php8.2-mysql \
        php8.2-redis \
        mariadb-client \
        curl \
    && rm -rf /var/lib/apt/lists/*
```

This command installs everything needed for the WordPress container.

---

## 1. `php8.2-fpm`

### What is it?

**PHP-FPM** means **PHP FastCGI Process Manager**.

WordPress is written mainly in PHP. NGINX cannot execute PHP code by itself, so we need PHP-FPM to execute WordPress's PHP files.

The flow is:

```text
Browser
   ↓
NGINX
   ↓
WordPress PHP file
   ↓
PHP-FPM
   ↓
HTML response
   ↓
Browser
```

### Why do we need it?

We install `php8.2-fpm` because this container is responsible for executing WordPress's PHP code.

---

## 2. `php8.2-mysql`

### What is it?

This is the PHP extension that allows PHP applications to communicate with **MySQL/MariaDB**.

WordPress uses the database to store:

- Users
- Posts
- Pages
- Settings
- Plugins
- Comments

The architecture is:

```text
WordPress
   │
   │ PHP
   ▼
php8.2-mysql
   │
   │ SQL
   ▼
MariaDB
```

### Why do we need it?

Without this extension, PHP/WordPress would not have the required MySQL/MariaDB driver to communicate with the database.

---

## 3. `php8.2-redis`

### What is it?

This is the PHP Redis extension. It allows PHP applications to communicate with a Redis server.

We use Redis as a bonus service for WordPress object caching.

The architecture is:

```text
WordPress
    ↓
PHP-FPM
    ↓
PHP Redis extension
    ↓
Redis container
```

### Why do we need it?

Our WordPress Redis plugin uses PHP to communicate with the Redis server.

---

## 4. `mariadb-client`

### What is it?

`mariadb-client` provides client programs such as:

```bash
mariadb
```

The client is used to connect to a MariaDB server.

### Server vs Client

```text
mariadb-server
      ↓
Runs the database server

mariadb-client
      ↓
Connects to a database server
```

In our project:

```text
WordPress container
        │
        │ MariaDB client
        ▼
MariaDB container
        │
        └── mariadbd
```

### Why do we need it?

Our WordPress startup script can use the MariaDB client to check whether the database is available or perform database-related operations.

Example:

```bash
mariadb -h mariadb -u "$MYSQL_USER" -p"$MYSQL_PASSWORD"
```

Here:

```text
mariadb
    → MariaDB client program

-h mariadb
    → Connect to the MariaDB service/container

-u
    → Username

-p
    → Password
```

---

## 5. `curl`

### What is it?

`curl` is a command-line tool used to make network requests.

Example:

```bash
curl https://wordpress.org
```

### Why do we need it?

Our WordPress startup script can use curl to download WordPress files.

For example:

```bash
curl -O https://wordpress.org/latest.tar.gz
```

It can also be used to test HTTP connections.

---

## 6. `apt-get update`

```bash
apt-get update
```

Updates the local APT package lists from the Debian repositories.

We need it before installing the dependencies so APT knows which packages and versions are available.

---

## 7. `rm -rf /var/lib/apt/lists/*`

```bash
rm -rf /var/lib/apt/lists/*
```

Removes the APT package lists after installation.

They are no longer needed, so removing them helps reduce the size of the Docker image.

---

# Complete Flow

```text
Debian
   ↓
apt-get update
   ↓
Install dependencies
   │
   ├── php8.2-fpm
   ├── php8.2-mysql
   ├── php8.2-redis
   ├── mariadb-client
   └── curl
   ↓
WordPress environment is ready
```

```
RUN curl URL -o /usr/local/bin/wp \
&& chmod +x /usr/local/bin/wp
```

means:

During the Docker image build, download WP-CLI into /usr/local/bin/wp, then give it permission to execute.


---

# Defense Answer

> We install PHP-FPM because WordPress is written in PHP and NGINX needs PHP-FPM to execute PHP files. We install the MySQL extension so PHP can communicate with MariaDB, and the Redis extension so WordPress can communicate with Redis. We install the MariaDB client for database connections and administrative checks from the WordPress container. Finally, we install curl because our startup process uses it for downloading files and making HTTP requests.

## 3. SCRIPT

### if [ ! -f /var/www/html/wp-load.php ]; then

means:

If WordPress's wp-load.php file does not exist, download WordPress.

### wp core download --allow-root --path=/var/www/html

`core download` tells WP-CLI:

Download the WordPress core files.

It downloads files such as:

wp-admin/
wp-content/
wp-includes/
index.php
wp-load.php
...

`--path=/var/www/html`  tells WP-CLI where to put the WordPress files.

Download WordPress into /var/www/html.

`--allow-root` Normally, WP-CLI doesn't want to be executed as the Linux root user because running applications as root can be a security risk.
               But during your Docker container startup, your script may be running as root.

tells WP-CLI:

I know I'm running as root; allow me to execute anyway.

### mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent


Use the MariaDB administration tool to ping the MariaDB server located at the Docker host mariadb,
and do it silently so that we can use the command's success/failure status.


`ping` is a command provided by mysqladmin.

It sends a request to the MySQL/MariaDB server to check whether the server is alive and responding.

`-h mariadb` Check the MariaDB server at the host named mariadb

`--silent` This tells mysqladmin to reduce/suppress normal output.

We don't need:

mysqld is alive

### wp config create

wp is WP-CLI, the command-line interface for WordPress.
config create tells WP-CLI:

Create a new wp-config.php file for this WordPress installation.

### wp core is-installed

`wp core is-installed` checks whether WordPress itself is installed and connected to its database.

### wp plugin install redis-cache --activate --allow-root --path=/var/www/html

`wp` → The WP-CLI command-line tool used to manage WordPress.

`plugin install` → Tells WP-CLI to install a WordPress plugin.

`redis-cache` → The name of the Redis Object Cache plugin to install.

`-activate `→ Activates the plugin immediately after installation.

`--allow-root` → Allows WP-CLI to run as the root user. This is commonly needed inside Docker containers.

`--path=/var/www/html` → Tells WP-CLI where the WordPress installation is located

### wp config set WP_REDIS_HOST redis --type=constant --allow-root --path=/var/www/html

`wp` → WP-CLI.

`config set` → Adds or changes a configuration value in wp-config.php.

`WP_REDIS_HOST` → The configuration variable that specifies where the Redis server is located.

`redis` → The hostname of the Redis service/container on the Docker network.

`--type=constant` → Creates the value as a PHP constant:


### wp config set WP_REDIS_PORT 6379 --raw --type=constant --allow-root --path=/var/www/html

`wp` → WP-CLI.

`config set` → Adds or changes a configuration value in wp-config.php.

`WP_REDIS_PORT` → The configuration variable specifying the Redis server port.

`6379` → Redis's default TCP port.

`--raw` → Tells WP-CLI to treat 6379 as a raw PHP value rather than a string.

-`-type=constant` → Creates a PHP constant:

### exec php-fpm8.2 -F

`exec` tells the shell Replace yourself with this process

`exec php-fpm8.2`

This starts PHP-FPM 8.2.

PHP-FPM means: PHP FastCGI Process Manager

Its job is to run PHP scripts and communicate with NGINX through FastCGI.

`-F` means: Run PHP-FPM in the foreground.

Normally, PHP-FPM can run as a daemon, meaning it starts and then goes into the background.

### How to generate the certificate (public key and private key)

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/server.key \
    -out /etc/nginx/ssl/server.crt

`req` means certificate request

`-x509` This tells OpenSSL to Create an X.509 certificate directly (self-signed).

`-nodes` Do not encrypt the private key with a password
         Without -nodes, OpenSSL may ask for a password to protect the private key.
         That would be inconvenient for NGINX because NGINX would need the password when starting.

`-newkey rsa:2048` This tells OpenSSL to create a new RSA private key. 
                     rsa = RSA cryptographic algorithm.
                     2048 = key size in bits

`-keyout` path /etc/nginx/ssl/server.key to the private key          

`-out` path /etc/nginx/ssl/server.crt to the certificate

### COMMANDS