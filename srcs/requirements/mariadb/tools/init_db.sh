#!/bin/bash

set -e

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

#if [ ! -d "/var/lib/mysql/mysql" ]; then
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Initializing database..."

    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    mysqld_safe &

    until mysqladmin ping --silent; do
        echo "Waiting for MariaDB..."
        sleep 2
    done

    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown
    chown -R mysql:mysql /var/lib/mysql

fi

exec mysqld_safe
