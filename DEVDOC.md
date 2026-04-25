# Developer Documentation — Inception

## Prerequisites

- A Linux Virtual Machine (Debian 11/12 or Ubuntu recommended)
- Docker Engine (>= 20.10) and Docker Compose (>= 2.x) installed
- `make` installed
- `sudo` or root access on the VM

---

## Environment setup from scratch

### 1. Clone the repository

```bash
git clone <your-repo-url> inception
cd inception
```

### 2. Configure the domain

Add the following line to `/etc/hosts` on your VM (and on your host machine if you want browser access from outside the VM):

```
127.0.0.1   jaoh.42.fr
```

### 3. Create the secrets files

These files are gitignored and must be created manually:

```bash
mkdir -p secrets

echo "dbpass4242"         > secrets/db_password.txt
echo "rootpass4242"       > secrets/db_root_password.txt
echo "boss:bosspass4242"  > secrets/credentials.txt
echo "editorpass4242"     > secrets/wp_user_password.txt
```

> Use your own strong passwords in production. Never commit these files.

### 4. Review the `.env` file

`srcs/.env` contains non-sensitive configuration. Sensitive values (passwords) should be kept in `secrets/` only. Make sure `.env` is also in `.gitignore`.

Current variables in `srcs/.env`:

```
DOMAIN_NAME=jaoh.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=jaoh
WP_TITLE=Inception
WP_ADMIN_USER=boss
WP_ADMIN_EMAIL=boss@jaoh.42.fr
WP_USER=editor
WP_USER_EMAIL=editor@jaoh.42.fr
```

Passwords (`MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `WP_ADMIN_PASSWORD`, `WP_USER_PASSWORD`) should be read from secrets inside the container entrypoint scripts rather than set in `.env`.

### 5. Create host data directories

The Makefile does this automatically, but you can also run manually:

```bash
mkdir -p /home/jaoh/data/wordpress
mkdir -p /home/jaoh/data/mariadb
```

---

## Building and launching with Makefile

| Command | Effect |
|---------|--------|
| `make` | Creates data dirs, builds images, starts containers detached |
| `make down` | Stops and removes containers and the network |
| `make stop` | Stops containers without removing them |
| `make start` | Starts previously stopped containers |
| `make restart` | Restarts all containers |
| `make logs` | Follows logs of all services |
| `make clean` | Alias for `down` |
| `make fclean` | `down` + removes images + wipes volume data on host |
| `make re` | `fclean` then `make` (full rebuild from scratch) |

---

## Container and volume management

**List running containers:**
```bash
docker ps
```

**Inspect a container:**
```bash
docker inspect nginx
docker inspect wordpress
docker inspect mariadb
```

**Execute a command inside a container:**
```bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

**View Docker volumes:**
```bash
docker volume ls
```

**Remove a specific volume:**
```bash
docker volume rm srcs_wp_data
docker volume rm srcs_db_data
```

---

## Project structure

```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                        # gitignored - passwords
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── credentials.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                        # non-sensitive config
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile          # debian:bullseye, installs nginx + openssl
        │   ├── conf/nginx.conf     # TLS 1.2/1.3, fastcgi_pass wordpress:9000
        │   └── .dockerignore
        ├── wordpress/
        │   ├── Dockerfile          # debian:bullseye, installs php7.4-fpm + wp-cli
        │   ├── conf/www.conf       # php-fpm pool config, listen 0.0.0.0:9000
        │   ├── tools/setup_wp.sh   # waits for DB, downloads WP, creates users
        │   └── .dockerignore
        └── mariadb/
            ├── Dockerfile          # debian:bullseye, installs mariadb-server
            ├── conf/50-server.cnf  # bind 0.0.0.0:3306, utf8mb4
            ├── tools/init_db.sh    # initializes DB and users on first boot
            └── .dockerignore
```

---

## Data persistence

WordPress files and the database are stored on the host VM at:

```
/home/jaoh/data/wordpress/    ← mounted into wp_data volume → /var/www/html
/home/jaoh/data/mariadb/      ← mounted into db_data volume → /var/lib/mysql
```

These directories survive `make down` and `make clean`. Only `make fclean` wipes them.

This means: stopping and restarting the stack with `make down && make` does **not** lose any WordPress posts, uploads, or database content.

---

## How secrets are passed to containers

Docker secrets are defined in `docker-compose.yml` under the `secrets:` key, pointing to files in `secrets/`. At runtime, each secret is mounted as a read-only file inside the container at `/run/secrets/<secret_name>`.

The entrypoint scripts read passwords from these files:
```bash
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
```

This ensures passwords are never present as environment variables or baked into any image layer.