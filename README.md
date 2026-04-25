# Inception

*This project has been created as part of the 42 curriculum by jaoh.*

---

## Description

Inception is a system administration project from the 42 curriculum. The goal is to build a small web infrastructure using Docker and Docker Compose, running entirely inside a Virtual Machine. The stack consists of three services — NGINX, WordPress (with php-fpm), and MariaDB — each isolated in its own container, communicating over a private Docker network, and persisting data through named volumes.

### Design Overview

The infrastructure is structured so that NGINX is the sole entry point via port 443 (HTTPS/TLS), forwarding PHP requests to the WordPress+php-fpm container, which in turn connects to the MariaDB container for database operations.

```
Internet → :443 → [NGINX] → :9000 → [WordPress+php-fpm] → :3306 → [MariaDB]
                                ↕                                        ↕
                           wp_data volume                          db_data volume
```

### Key Design Choices

**Virtual Machines vs Docker**

A Virtual Machine emulates a full operating system with its own kernel, consuming significant resources. Docker containers share the host kernel and are isolated at the process level, making them far lighter and faster to start. This project uses Docker inside a VM to combine isolation at the OS level (VM) with lightweight service separation (containers).

**Secrets vs Environment Variables**

Environment variables (`.env`) are convenient for non-sensitive configuration like domain names or database names. However, they are visible in the process environment and can be leaked easily. Docker secrets mount sensitive values (passwords, keys) as files inside `/run/secrets/` and are never exposed as environment variables, making them significantly more secure for credentials.

**Docker Network vs Host Network**

`network: host` removes all network isolation — the container shares the host's network stack directly, which is a security risk and is explicitly forbidden by this project. A custom Docker bridge network (`inception`) allows containers to communicate using service names as hostnames (e.g. `mariadb`, `wordpress`) while remaining isolated from the host and from other Docker networks.

**Docker Volumes vs Bind Mounts**

Bind mounts directly link a host path to a container path, which creates tight coupling between the host filesystem layout and the container. Named volumes are managed by Docker and offer better portability and lifecycle management. This project uses named volumes configured to store data at `/home/jaoh/data` on the host, satisfying the subject requirement while keeping the compose configuration clean.

---

## Instructions

### Prerequisites

- A Linux Virtual Machine (Debian or Ubuntu recommended)
- Docker and Docker Compose installed
- `sudo` access to edit `/etc/hosts`

### Setup

1. Clone the repository inside your VM.

2. Add the domain to `/etc/hosts`:
   ```
   127.0.0.1   jaoh.42.fr
   ```

3. Create the required secret files (these must not be committed to git):
   ```
   secrets/db_password.txt
   secrets/db_root_password.txt
   secrets/credentials.txt        # format: admin_user:admin_password
   secrets/wp_user_password.txt
   ```

4. Create the host data directories:
   ```bash
   mkdir -p /home/jaoh/data/wordpress
   mkdir -p /home/jaoh/data/mariadb
   ```

5. Build and start everything:
   ```bash
   make
   ```

6. Open `https://jaoh.42.fr` in your browser (accept the self-signed certificate warning).

### Makefile targets

| Target   | Description                                      |
|----------|--------------------------------------------------|
| `make`   | Build images and start all containers            |
| `make down` | Stop and remove containers and networks       |
| `make re`   | Full clean rebuild                            |
| `make fclean` | Remove containers, images, and volume data  |
| `make logs`  | Follow logs of all containers               |

---

## Resources

### Documentation
- [Docker official docs](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [NGINX docs](https://nginx.org/en/docs/)
- [WordPress CLI (WP-CLI)](https://wp-cli.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [php-fpm configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [PID 1 and init in containers](https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling)

### AI Usage

AI (Claude) was used in this project for the following tasks:
- Drafting this README and the USER_DOC/DEV_DOC documentation files

All AI-generated content was reviewed, tested, and understood before being used. The logic of each script and configuration was verified manually.