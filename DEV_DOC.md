# Developer Documentation — Inception Stack

This document explains how to set up, build, and manage the project as a developer.

## 1. Prerequisites

- A Linux host or VM (Debian/Alpine based, per project constraints) with **sudo** rights.
- **Docker Engine** and the **Docker Compose** installed 
- A domain name pointing to the machine for local testing. Typically this is done by adding a line to `/etc/hosts`:
  ```
  127.0.0.1   <user>.42.fr
  ```
  (replace `<user>` with the value you plan to use for `WP_URL`).

## 2. Project layout

```
.
├── Makefile
├── srcs/
│   ├── docker-compose.yml
│   ├── .env                     # secrets & config (not committed to Git)
│   └── requirements/
│       ├── nginx/
│       ├── wordpress/
│       ├── mariadb/
│       └── bonus/
│           ├── static_website/
│           ├── adminer/
│           ├── redis/
│           └── portainer/
```

## 3. Setting up the environment from scratch

### 3.1 Configuration file (`.env`)

Create a `srcs/.env` file (this file is read by `docker-compose.yml` and must **never** be committed to version control — add it to `.gitignore`). It must define:

```env
# Domain
WP_URL=<user>.42.fr
WP_TITLE=My Inception Site

# MariaDB
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=<password>
MYSQL_ROOT_PASSWORD=<password>

# WordPress admin account
WP_ADMIN_USER=<admin username, must NOT contain "admin" or "administrator">
WP_ADMIN_PASSWORD=<password>
WP_ADMIN_EMAIL=<user_admin>@example.com

# WordPress second (regular) user
WP_AU_USER=<second username>
WP_AU_EMAIL_USER=user@example.com
WP_AU_PASSWORD=<password>
```

Keep a `.env.example` (with placeholder values only) in the repo so other developers know which variables are required, without exposing real secrets.

### 3.2 Data directories

The Makefile creates the host directories used for persistent storage before starting the stack:

```bash
mkdir -p /home/mradouan/data/mariadb
mkdir -p /home/mradouan/data/wordpress
mkdir -p /home/mradouan/data/portainer
```

This happens automatically when you run `make` or `make all` — you don't need to create them by hand. Note the path is currently hardcoded to `/home/mradouan/data` in both the `Makefile` (`DATA_PATH`) and `docker-compose.yml` (volume `device:` paths) — if you clone this on a machine with a different username, update `DATA_PATH` in the `Makefile` **and** the matching `device:` paths in `docker-compose.yml` accordingly.

## 4. Building and launching the project

All commands are run from the project root (where the `Makefile` lives)

| Command | What it does |
|---|---|
| `make` or `make all` | Creates the required data directories, then builds and starts every service in detached mode. This is the normal "first run" command. |
| `make up` | Builds (if needed) and starts all services in detached mode, without recreating the data directories. |
| `make build` | Builds (or rebuilds) all Docker images without starting the containers. |
| `make down` | Stops and removes the containers (data volumes on disk are preserved). |
| `make ps` | Lists the status of all containers in the stack. |

## 5. Managing containers and volumes


```bash
# Follow logs for one or all services
docker compose logs -f
docker compose logs -f wordpress

# Rebuild a single service after editing its Dockerfile
docker compose build nginx
docker compose up -d nginx

# Open a shell inside a running container
docker exec -it wordpress bash
docker exec -it mariadb bash

# Restart a single service without touching the others
docker compose restart redis

# List Docker-managed volumes and inspect one
docker volume ls
docker volume inspect srcs_mariadb-data
```

### Makefile cleanup targets

| Command | What it does |
|---|---|
| `make clean` | Stops the stack, removes containers, **removes all images built for this project**, removes the named Docker volumes, and **deletes the host data directories** (`/home/mradouan/data`) with `sudo rm -rf`. This permanently erases the WordPress site and database content. |
| `make fclean` | Runs `clean`, then also runs `docker system prune -a --volumes -f`, wiping **all unused Docker images, containers, networks, and volumes on the machine** — not just this project's. Use with care on a shared machine. |
| `make re` | Runs `fclean` then `all` — a full teardown and rebuild from scratch. |

## 6. Where project data is stored and how it persists

Two named Docker volumes are declared in `docker-compose.yml`, both using the `local` driver with a **bind mount** to a fixed host path — meaning the data physically lives on the host filesystem, not inside Docker's internal storage, so it survives container recreation and even `docker compose down`:

| Volume | Host path | Mounted into | Contains |
|---|---|---|---|
| `mariadb-data` | `/home/mradouan/data/mariadb` | `mariadb:/var/lib/mysql` | All database files (WordPress posts, users, settings, etc.) |
| `wordpress-data` | `/home/mradouan/data/wordpress` | `wordpress:/var/www/html` and `nginx:/var/www/html` | WordPress core files, themes, plugins, and uploaded media. Shared between `wordpress` and `nginx` so nginx can serve static files directly. |

Additionally, **Portainer** persists its own state (users, settings) via a bind mount at `/home/mradouan/data/portainer`, mapped to `/data` inside the container — this is where it remembers the admin account you create on first login.

**Persistence behavior summary:**
- `docker compose down` (or `make down`) — containers are removed, but volumes/bind-mounted data on disk are **kept**. Running `make up` again restores the exact same site and database.
- `docker compose down --volumes` (or `make clean` / `make fclean`) — the bind-mounted host directories are deleted too, so the next `make all` starts from a completely empty WordPress install and database.