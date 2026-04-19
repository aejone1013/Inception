FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Generate self-signed TLS certificate
RUN mkdir -p /etc/nginx/ssl \
    && openssl req -x509 -nodes -days 365 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=KR/ST=Seoul/L=Seoul/O=42/OU=42Seoul/CN=jaoh.42.fr"

# Copy nginx configuration
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

# Remove default nginx config that may conflict
RUN rm -f /etc/nginx/sites-enabled/default

EXPOSE 443

# Run nginx in foreground (PID 1)
ENTRYPOINT ["nginx", "-g", "daemon off;"]
