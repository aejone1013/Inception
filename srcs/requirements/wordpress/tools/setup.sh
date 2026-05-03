#!/bin/bash

# Do not use set -e, so we can echo failures properly.
cd /var/www/wordpress

# Download WordPress if not already present
if [ ! -f index.php ]; then
    echo "Downloading WordPress..."
    curl -O https://wordpress.org/latest.tar.gz || { echo "Failed to download WordPress"; exit 1; }
    tar -xzf latest.tar.gz
    mv wordpress/* .
    rm -rf wordpress latest.tar.gz
fi

# Create wp-config.php if not present
if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php..."
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --allow-root || { echo "Failed to create wp-config.php"; exit 1; }
    echo "wp-config.php created successfully!"
else
    echo "wp-config.php already exists."
fi

# Install WordPress if not already installed
if ! wp core is-installed --allow-root 2>&1; then
    echo "Installing WordPress..."
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root || { echo "Failed to install WordPress"; exit 1; }
    echo "WordPress installed successfully!"
else
    echo "WordPress is already installed."
fi

# add when after finish install WordPress
if ! wp user get "${WP_USER}" --allow-root 2>&1; then
    echo "Creating second user..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root || { echo "Failed to create user"; exit 1; }
    #wp option update comment_moderation 0 --allow-root
    #wp option update comment_previously_approved 0 -- allow-root
    echo "Second user created!"
fi

chown -R www-data:www-data /var/www/wordpress

echo "WordPress setup complete. Starting PHP-FPM..."
exec php-fpm8.2 -F
