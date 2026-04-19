FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy the initialization script
COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

# Copy custom MariaDB config
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Create run directory for mysqld socket
RUN mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

EXPOSE 3306

ENTRYPOINT ["init_db.sh"]
