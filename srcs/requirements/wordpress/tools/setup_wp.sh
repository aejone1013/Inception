#!/bin/bash
set -e

# Read secrets from Docker secrets files
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password | cut -d':' -f2)
WP_ADMIN_USER=$(cat /run/secrets/wp_admin_password | cut -d':' -f1)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# Wait for MariaDB to be ready
echo "[i] Waiting for MariaDB..."
while ! mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    sleep 2
done
echo "[i] MariaDB is ready."

cd /var/www/html

if [ ! -f wp-config.php ]; then

    echo "[i] Downloading WordPress..."
    wp core download --allow-root --force

    echo "[i] Creating wp-config.php..."
    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306"

    echo "[i] Installing WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    echo "[i] Creating second user..."
    wp user create --allow-root \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WP_USER_PASSWORD}"

    chown -R www-data:www-data /var/www/html
    echo "[i] WordPress setup complete."
else
    echo "[i] WordPress already configured, skipping setup."
fi

echo "[i] Starting php-fpm..."
exec php-fpm7.4 -F