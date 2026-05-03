# Getting a Linux OS : base image : [image name]:[version tag]
FROM debian:bookworm

# Package Installation: nginx (web server), openssl (certificate generation tool)
RUN apt-get update && apt-get install -y nginx openssl procps netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Make SSL
RUN openssl req -x509 -nodes -days 365 \
	-newkey rsa:2048 \
	-keyout /etc/ssl/private/server.key\
	-out /etc/ssl/certs/server.crt \
	-subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=jihyeki2.42.fr"

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY tools/start.sh /start.sh

RUN chmod +x /start.sh

# Port
EXPOSE 443

CMD ["/start.sh"]
