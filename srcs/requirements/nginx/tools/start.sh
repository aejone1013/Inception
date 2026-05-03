#!/bin/bash

echo "Waiting for WordPress files..."
until [ -f /var/www/wordpress/index.php ]; do
    sleep 1
done

echo "Starting NGINX..."
nginx -g "daemon off;"