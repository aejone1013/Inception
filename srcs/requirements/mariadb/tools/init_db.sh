#!/bin/bash
set -e

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[i] Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
    echo "[i] Data directory initialized."

    echo "[i] Starting temporary MariaDB to create users..."
    mysqld --user=mysql --skip-networking &
    TEMP_PID=$!

    while ! mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent 2>/dev/null; do
        sleep 1
    done
    echo "[i] Temporary server is up."

    mysql --socket=/run/mysqld/mysqld.sock << EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "[i] Users and database created."

    mysqladmin shutdown --socket=/run/mysqld/mysqld.sock
    wait $TEMP_PID
    echo "[i] Temporary server stopped."
else
    echo "[i] Already initialized, skipping."
fi

mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql /run/mysqld

echo "[i] Starting MariaDB (foreground)..."
exec mysqld --user=mysql