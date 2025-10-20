FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

RUN apk add --no-cache nginx supervisor \
    && mkdir -p /run/nginx \
    && chown -R www-data:www-data /var/lib/nginx \
    && chown -R www-data:www-data /var/www/html

COPY server.php /var/www/html/index.php
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

EXPOSE 8080

CMD ["supervisord", "-c", "/etc/supervisord.conf"]
