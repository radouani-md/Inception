# User Documentation — Inception Stack

This document explains, in plain terms, how to use and manage this Docker-based infrastructure project (WordPress + MariaDB behind an Nginx reverse proxy, plus bonus services).

## 1. What services does this stack provide?

| Service      | Role                                                                 | Exposed on host |
|--------------|-----------------------------------------------------------------------|------------------|
| **nginx**    | Web entry point. Serves the site over HTTPS and forwards requests to WordPress. | `443` (HTTPS) |
| **wordpress**| The website (PHP-FPM). Runs WordPress, connects to the database. | Not exposed directly — only reachable through nginx |
| **mariadb**  | The database that stores WordPress content (posts, pages, users, settings). | Not exposed directly — internal only |
| **portfolio**| A standalone static portfolio website, independent of WordPress. | `80` (HTTP) |
| **adminer**  | A lightweight web UI to browse/manage the MariaDB database. | Not exposed directly — only reachable through nginx or the internal network |
| **redis**    | A cache service that speeds up WordPress (object caching). | Not exposed directly — internal only |
| **portainer**| A web dashboard to visually manage all Docker containers, images, volumes, and logs. | `9000` |

All internal-only services communicate over a private Docker network called `inception-network`, and are not reachable directly from your browser unless a port is mapped or nginx is configured to proxy them.

## 2. Starting and stopping the project


**Start everything (build images if needed, run in background):**
```bash
make 
```

**Stop everything (containers are removed, data volumes are kept):**
```bash
make down
```

**Restart a single service** (e.g. after a config change):
```bash
docker compose restart nginx
```

## 3. Accessing the website and the administration panel

- **Main website (WordPress):**
  Open `https://<WP_URL>` in your browser, where `<WP_URL>` is the domain configured in the `.env` file (the `WP_URL` variable). Since the certificate is typically self-signed, your browser will show a security warning — this is expected in a local/dev setup; click "advanced" / "proceed anyway".

- **WordPress admin panel:**
  Go to `https://<WP_URL>/wp-admin`
  Log in with the admin account defined by `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD` (see credentials section below). A second, non-admin user (`WP_AU_USER`) is also created automatically.

- **Portfolio (bonus static site):**
  Open `http://localhost` on port `80`.

- **Adminer (bonus database UI):**
  Not published on a host port by default — it is reachable only from inside `inception-network`, or through whatever path nginx is configured to proxy to it (check the nginx configuration for the exact URL, e.g. `https://<WP_URL>/adminer`). Log in using the MariaDB credentials below, with server/host set to `mariadb`.

- **Portainer (bonus Docker management UI):**
  Open `https://localhost:9000`. On first visit you'll be asked to create a Portainer admin account.

## 4. Locating and managing credentials

All secrets are defined as environment variables and loaded from a `.env` file at the project root. The compose file references these variables:

| Variable | Used for |
|---|---|
| `MYSQL_DATABASE` | Name of the WordPress database |
| `MYSQL_USER` / `MYSQL_PASSWORD` | database user (used by WordPress) |
| `MYSQL_ROOT_PASSWORD` | MariaDB root/administrator password |
| `WP_URL` | The domain name of the site |
| `WP_TITLE` | The site's title |
| `WP_ADMIN_USER` / `WP_ADMIN_PASSWORD` / `WP_ADMIN_EMAIL` | WordPress administrator account |
| `WP_AU_USER` / `WP_AU_EMAIL_USER` / `WP_AU_PASSWORD` | A second, regular WordPress user account |

**To view or change credentials:**
1. Open the `.env` file at the project root in a text editor.
2. Edit the relevant value(s).
3. Recreate the affected containers for the change to take effect:
   ```bash
   make
   ```
   Note: changing database credentials after the database volume already exists will not retroactively update MariaDB — you'd need to change the password manually inside the database, or reset the volume (`docker compose down -v`) if this is a fresh setup.

**Good practice:** keep `.env` out of Git , and never share it publicly, since it contains all passwords for the stack.

## 5. Checking that services are running correctly

**Quick overview of all containers and their status:**
```bash
make ps
```
Look for a `STATUS` of `Up` (or `running`) for each service. `Restarting` or `Exited` indicates a problem.

**View live logs for a specific service** (useful for diagnosing startup issues):
```bash
docker compose logs -f nginx
docker compose logs -f wordpress
docker compose logs -f mariadb
```

**Confirm the database is reachable:**
```bash
docker exec -it mariadb mariadb -u root -p
```
(enter `MYSQL_ROOT_PASSWORD` when prompted) — if you get a MariaDB prompt, the database is healthy.

**Visual check via Portainer:** open the Portainer dashboard (see section 3) to see all containers' status, CPU/memory usage, and logs in one place without using the command line.