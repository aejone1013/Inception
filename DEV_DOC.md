# DEV_DOC.md

## Project Architecture

This project runs three services in separate Docker containers, orchestrated with Docker Compose.

| Container | Role | Communication |
|-----------|------|---------------|
| nginx | Reverse proxy, HTTPS entry point | Receives external requests on port 443, forwards PHP to wordpress:9000 |
| wordpress | PHP-FPM application | Connects to mariadb:3306 for database |
| mariadb | Relational database | Accessed by wordpress only |

All containers are connected through a custom bridge network named `inception`.

---

## Directory Structure

```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── srcs/
│   ├── docker-compose.yml
│   ├── .env               <- not in git, create from .env.example
│   ├── .env.example       <- template committed to git
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── conf/
│       │   │   └── default.conf
│       │   └── tools/
│       │       └── start.sh
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   ├── conf/
│       │   │   └── www.conf
│       │   └── tools/
│       │       └── setup.sh
│       └── mariadb/
│           ├── Dockerfile
│           ├── conf/
│           │   └── my.cnf
│           └── tools/
│               └── init_db.sh
```

---

## Setup from Scratch

### 1. Requirements

- Docker
- Docker Compose
- Virtual Machine running Linux (Debian recommended)

### 2. Clone Repository

```bash
git clone <repo>
cd <repo>
```

### 3. Configure Environment Variables

Create the `.env` file from the provided example:

```bash
cp srcs/.env.example srcs/.env
vim srcs/.env
```

Fill in all values:

```env
DOMAIN_NAME=jihyeki2.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=<db_user>
MYSQL_PASSWORD=<db_password>
MYSQL_ROOT_PASSWORD=<root_password>

WP_ADMIN_USER=<admin_username>      # must NOT contain 'admin' or 'Admin'
WP_ADMIN_PASSWORD=<admin_password>
WP_ADMIN_EMAIL=<admin_email>
WP_USER=<user_username>
WP_USER_PASSWORD=<user_password>
WP_USER_EMAIL=<user_email>
```

### 4. Build and Run

```bash
make up
```

This command:
1. Creates `/home/jihyeki2/data/mariadb` and `/home/jihyeki2/data/wordpress` on the host
2. Builds all three Docker images from their respective Dockerfiles
3. Starts all containers in detached mode

---

## Makefile Usage

| Command | Description |
|---------|-------------|
| `make up` | Create data dirs, build images, start containers |
| `make down` | Stop and remove containers (data preserved) |
| `make logs` | Show last 50 lines of nginx logs |
| `make clean` | Stop containers and remove volumes |
| `make fclean` | Full cleanup: containers, volumes, images, host data |

---

## Container Communication

```
External (port 443)
        |
    [nginx]
        | FastCGI (wordpress:9000)
    [wordpress]
        | MySQL (mariadb:3306)
    [mariadb]
```

- nginx to wordpress: `fastcgi_pass wordpress:9000;` in `default.conf`
- wordpress to mariadb: `dbhost=mariadb:3306` set during `wp config create` in `setup.sh`

---

## Volumes and Data Persistence

Two named volumes are used:

| Volume name | Host path | Container path |
|-------------|-----------|----------------|
| `mariadb_data` | `/home/jihyeki2/data/mariadb` | `/var/lib/mysql` |
| `wordpress_data` | `/home/jihyeki2/data/wordpress` | `/var/www/wordpress` |

Volumes are defined as named volumes with `driver: local` and `driver_opts` to bind to the specified host paths. Data persists across container restarts and VM reboots.

---

## Useful Commands

### Check running containers

```bash
docker ps
docker compose -f srcs/docker-compose.yml ps
```

### View logs

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Access container shell

```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### Verify volumes

```bash
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

### Access database

```bash
# Connect as WordPress user
docker exec -it mariadb mysql -u <MYSQL_USER> -p<MYSQL_PASSWORD> <MYSQL_DATABASE>

# Connect as root
docker exec -it mariadb mysql -u root -p<MYSQL_ROOT_PASSWORD>

# Inside mysql, verify database is not empty
SHOW TABLES;
SELECT user_login, user_email FROM wp_users;
```

### Verify TLS

```bash
# TLSv1.2 must work
openssl s_client -connect jihyeki2.42.fr:443 -tls1_2

# TLSv1.3 must work
openssl s_client -connect jihyeki2.42.fr:443 -tls1_3

# TLSv1.1 must NOT work
openssl s_client -connect jihyeki2.42.fr:443 -tls1_1
```

### Verify ports

```bash
# Port 443 must respond
curl -kI https://jihyeki2.42.fr

# Port 80 must NOT respond
curl -I http://jihyeki2.42.fr
```

---

## Restart and Clean

```bash
# Stop only (data preserved)
make down

# Restart without losing data
make down
make up

# Stop and remove volumes (data lost)
make clean

# Full reset including host data
make fclean
make up
```

---

## Security Notes

- No passwords are stored in Dockerfiles
- All sensitive data is stored in `srcs/.env` which is excluded from Git via `.gitignore`
- `srcs/.env.example` with empty values is committed as a reference template
- Only port 443 is exposed externally
- WordPress and MariaDB ports are internal only (using `expose:` not `ports:`)
- Containers restart automatically on crash (`restart: always`)
- No usage of `latest` tag in any Dockerfile

---

## Compliance with Subject

| Requirement | Status |
|-------------|--------|
| Separate containers for nginx, wordpress, mariadb | ✅ |
| HTTPS with TLSv1.2 or TLSv1.3 only | ✅ |
| Only port 443 exposed externally | ✅ |
| Docker named volumes for persistence | ✅ |
| Data stored at /home/jihyeki2/data/ | ✅ |
| Custom Docker bridge network | ✅ |
| Environment variables via .env | ✅ |
| No passwords in Dockerfiles | ✅ |
| No latest tag | ✅ |
| Two WordPress users (admin not named admin) | ✅ |
| Containers restart on crash | ✅ |
| Built from debian:bookworm | ✅ |