FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    wordpress \
    php8.2 \
    php8.2-fpm \
    php8.2-mysql \
    wget \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# wordpress download
RUN mkdir -p /var/www/wordpress

WORKDIR /var/www/wordpress

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY ./tools/setup.sh /setup.sh

RUN mkdir -p /run/php

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

RUN chmod +x /setup.sh

CMD ["/setup.sh"]