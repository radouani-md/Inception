# MariaDB

## 1. CONFIG

### Why do we use it?

We use the MariaDB configuration file to change the address where MariaDB listens.

By default, MariaDB may listen only on:

127.0.0.1:3306

But our MariaDB is running inside a Docker container.

WordPress is in another container, so MariaDB must accept connections coming from outside its own container.

Therefore, we use:

bind-address = 0.0.0.0

This means MariaDB listens on all network interfaces inside the container.

### COMMANDS

Check the configuration:

    cat /etc/mysql/mariadb.conf.d/50-server.cnf

Check what MariaDB is listening on:

    ss -lntp | grep 3306


## 2. Dockerfile

## RUN

### apt-get update

Updates the local APT package lists from the Debian repositories.

We need it before installing MariaDB so APT knows which packages and versions are available.

### apt-get install -y mariadb-server

Installs the MariaDB server and its required dependencies.

We need `mariadb-server` because this container is responsible for running the MariaDB database service.

`-y` automatically confirms the installation so the Docker build can run without interaction.

### rm -rf /var/lib/apt/lists/*

Removes the APT package lists after installation.

They are no longer needed and removing them reduces the size of the final image.

### Complete command

    RUN apt-get update && \
        apt-get install -y mariadb-server && \
        rm -rf /var/lib/apt/lists/*

The `&&` operator ensures that each command is executed only if the previous command succeeds.

### chmod +x /usr/local/bin/mariadb_scr.sh

Make it executable 

## 3. SCRIPT

### exec mariadbd --user=mysql

This command starts the MariaDB server.

`mariadbd` is the main MariaDB server process. It runs the database server and accepts connections from other services, such as WordPress.
`--user=mysql` This tells MariaDB to run the server process as the Linux user `mysql` instead of `root`.
`exec` replaces the current Bash process with `mariadbd`.

`exec` replaces the shell script process with `mariadbd`, making MariaDB the main PID 1 process of the container. `--user=mysql` makes the MariaDB server run as the `mysql` Linux user instead of root.

### COMMANDS