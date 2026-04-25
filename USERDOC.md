# User Documentation — Inception

## What services does this stack provide?

This project runs three services together:

- **NGINX** — the web server and HTTPS entry point. All traffic goes through this container on port 443.
- **WordPress + php-fpm** — the content management system. Handles all dynamic PHP requests.
- **MariaDB** — the database server. Stores all WordPress content, users, and settings.

The website is accessible at `https://jaoh.42.fr`.

---

## Starting and stopping the project

**Start everything:**
```bash
make
```

**Stop containers (keeps data):**
```bash
make down
```

**Restart all containers:**
```bash
make restart
```

**Start previously stopped containers:**
```bash
make start
```

---

## Accessing the website

Open your browser and navigate to:

```
https://jaoh.42.fr
```

Since the TLS certificate is self-signed, your browser will show a security warning. This is expected — click "Advanced" and proceed to the site.

### WordPress Administration Panel

```
https://jaoh.42.fr/wp-admin
```

Log in with the administrator credentials stored in `secrets/credentials.txt`.

---

## Credentials

All credentials are stored in the `secrets/` directory at the root of the repository. **These files must never be committed to git.**

| File | Contents |
|------|----------|
| `secrets/db_password.txt` | MariaDB password for the WordPress user |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/credentials.txt` | WordPress admin username and password (format: `user:password`) |
| `secrets/wp_user_password.txt` | WordPress second user (editor) password |

WordPress users defined in `srcs/.env`:

| Role | Username | Email |
|------|----------|-------|
| Administrator | `boss` | `boss@jaoh.42.fr` |
| Editor | `editor` | `editor@jaoh.42.fr` |

---

## Checking that services are running

**View running containers:**
```bash
docker ps
```

You should see three containers running: `nginx`, `wordpress`, `mariadb`.

**Follow live logs:**
```bash
make logs
```

**Check a specific container:**
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

**Verify NGINX is reachable:**
```bash
curl -k https://jaoh.42.fr
```

**Verify MariaDB is up from inside WordPress container:**
```bash
docker exec -it wordpress mysqladmin ping -h mariadb -u jaoh -p
```