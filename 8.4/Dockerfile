FROM dunglas/frankenphp:php8.4-trixie AS builder

COPY clean.sh /root/clean.sh
# create frankenphp user and create caddy config directories for frankenphp startup
RUN adduser --disabled-password frankenphp \
&& mkdir -p /home/frankenphp/.config/caddy && mkdir -p /home/frankenphp/.local/share/caddy/locks \
&& install-php-extensions \
    dom \
    ctype \
    exif \
    gd \
    intl \
    opcache \
    pdo \
    pdo_mysql \
    session \
    xml \
    gmp \
    bcmath \
    fileinfo \
    simplexml \
    sockets \
    zip \
    && pecl install redis \
    && sh /root/clean.sh \
    && rm /root/clean.sh

# final stage
FROM gcr.io/distroless/static-debian13

WORKDIR /app
COPY --from=builder /etc/passwd /etc/group /etc/
COPY --from=builder /etc/ssl/ /etc/ssl/
COPY --from=builder /etc/localtime /etc/localtime
COPY --from=builder /etc/os-release /etc/os-release
COPY --from=builder /usr/share/zoneinfo/ /usr/share/zoneinfo/

# get FrankenPHP and PHP  binary from builder image
COPY --from=builder --chown=www-data:www-data  /usr/local/bin/frankenphp /usr/local/bin/frankenphp
COPY --from=builder --chown=www-data:www-data /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /tmp/libs /usr/lib

# add linux libraries for php and caddy
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=builder /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
COPY --from=builder --chown=www-data:www-data /data/caddy /data/caddy
COPY --from=builder --chown=www-data:www-data /config/caddy /config/caddy
COPY --from=builder --chown=www-data:www-data /var/www /var/www

# switch to frankenphp user
USER www-data:www-data

# copy application files and Caddyfile
COPY --from=builder --chown=www-data:www-data /app /app
COPY --from=builder --chown=www-data:www-data /home/frankenphp/ /home/frankenphp/
COPY --chown=www-data:www-data Caddyfile /etc/caddy/Caddyfile
ENTRYPOINT [ "frankenphp", "run", "--config", "/etc/caddy/Caddyfile" ]