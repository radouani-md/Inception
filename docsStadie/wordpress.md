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

---

# Defense Answer

> We install PHP-FPM because WordPress is written in PHP and NGINX needs PHP-FPM to execute PHP files. We install the MySQL extension so PHP can communicate with MariaDB, and the Redis extension so WordPress can communicate with Redis. We install the MariaDB client for database connections and administrative checks from the WordPress container. Finally, we install curl because our startup process uses it for downloading files and making HTTP requests.

## 3. SCRIPT

### exec mariadbd --user=mysql

This command starts the MariaDB server.

`mariadbd` is the main MariaDB server process. It runs the database server and accepts connections from other services, such as WordPress.
`--user=mysql` This tells MariaDB to run the server process as the Linux user `mysql` instead of `root`.
`exec` replaces the current Bash process with `mariadbd`.

`exec` replaces the shell script process with `mariadbd`, making MariaDB the main PID 1 process of the container. `--user=mysql` makes the MariaDB server run as the `mysql` Linux user instead of root.

### COMMANDS