FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-curl \
    php7.4-gd \
    php7.4-intl \
    php7.4-mbstring \
    php7.4-xml \
    php7.4-zip \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Install wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Configure php-fpm to listen on port 9000 (instead of socket)
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Create necessary directories
RUN mkdir -p /var/www/html \
    && mkdir -p /run/php \
    && chown -R www-data:www-data /var/www/html

# Copy entrypoint script
COPY tools/setup_wp.sh /usr/local/bin/setup_wp.sh
RUN chmod +x /usr/local/bin/setup_wp.sh

EXPOSE 9000

ENTRYPOINT ["setup_wp.sh"]
