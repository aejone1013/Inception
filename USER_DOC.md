# USER_DOC.md

## Overview

This project provides a small web infrastructure composed of three services:

- **NGINX** — Web server, the only entry point via HTTPS on port 443
- **WordPress** — Website with php-fpm
- **MariaDB** — Database that stores all WordPress data

All services run in separate Docker containers and communicate through a Docker network called `inception`.

---

## Services

| Service | Role | Port |
|---------|------|------|
| NGINX | Entry point, HTTPS reverse proxy | 443 (external) |
| WordPress | PHP application with php-fpm | 9000 (internal only) |
| MariaDB | Database | 3306 (internal only) |

Only port 443 is accessible from outside. WordPress and MariaDB are not directly reachable from the host.

---

## How to Start the Project

**Before starting**, make sure the `.env` file exists at `srcs/.env`. If not, create it from the example:

```bash
cp srcs/.env.example srcs/.env
vim srcs/.env
```

Then start all services:

```bash
make up
```

This will create the necessary data directories, build all Docker images, and start all containers.

---

## How to Stop the Project

```bash
make down
```

This stops and removes the containers. Data in volumes is preserved.

---

## Access the Website

Open your browser and go to:

```
https://jihyeki2.42.fr
```

A browser warning about the certificate may appear. This is expected because a self-signed certificate is used. Proceed past the warning to access the site.

If the domain does not resolve, add it to `/etc/hosts`:

```bash
echo "127.0.0.1 jihyeki2.42.fr" | sudo tee -a /etc/hosts
```

---

## WordPress Admin Panel

To access the administration dashboard:

1. Go to `https://jihyeki2.42.fr/wp-admin`
2. Log in with the admin credentials defined in `srcs/.env`

```
Username: value of WP_ADMIN_USER in .env
Password: value of WP_ADMIN_PASSWORD in .env
```

---

## Credentials

All credentials are stored in:

```
srcs/.env
```

This file is excluded from the Git repository. It must be created manually on each machine using `srcs/.env.example` as a reference.

| Variable | Purpose |
|----------|---------|
| `MYSQL_DATABASE` | WordPress database name |
| `MYSQL_USER` | Database user for WordPress |
| `MYSQL_PASSWORD` | Password for the database user |
| `MYSQL_ROOT_PASSWORD` | MariaDB root password |
| `WP_ADMIN_USER` | WordPress administrator username |
| `WP_ADMIN_PASSWORD` | WordPress administrator password |
| `WP_ADMIN_EMAIL` | WordPress administrator email |
| `WP_USER` | WordPress secondary user username |
| `WP_USER_PASSWORD` | WordPress secondary user password |
| `WP_USER_EMAIL` | WordPress secondary user email |

⚠️ Do not commit `.env` to Git. Do not share these credentials publicly.

---

## Check if Services Are Running

```bash
docker ps
```

Expected output — three containers should be running:

```
CONTAINER ID   IMAGE       STATUS
...            nginx       Up
...            wordpress   Up
...            mariadb     Up
```

---

## View Logs

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

---

## Quick Connection Test

```bash
# HTTPS should work (200 OK)
curl -kI https://jihyeki2.42.fr

# HTTP should not work (connection refused)
curl -I http://jihyeki2.42.fr
```

---

## Data Persistence

All data is stored on the host machine at:

```
/home/jihyeki2/data/mariadb    <- database files
/home/jihyeki2/data/wordpress  <- WordPress site files
```

Data is preserved when containers are stopped or the VM is rebooted. Simply run `make up` again to restore the full state.