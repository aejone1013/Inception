FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-server \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY ./tools/init_db.sh /init_db.sh

RUN chmod +x /init_db.sh

EXPOSE 3306

CMD ["/init_db.sh"]
