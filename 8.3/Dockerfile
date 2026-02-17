FROM dunglas/frankenphp:php8.3-trixie AS builder

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
FROM scratch
WORKDIR /app
COPY --from=builder /etc/passwd /etc/group /etc/
COPY --from=builder /etc/ssl/ /etc/ssl/
COPY --from=builder /etc/localtime /etc/localtime
COPY --from=builder /etc/os-release /etc/os-release
COPY --from=builder /usr/share/zoneinfo/ /usr/share/zoneinfo/

# get FrankenPHP and PHP  binary from builder image
COPY --from=builder --chown=frankenphp:frankenphp  /usr/local/bin/frankenphp /usr/local/bin/frankenphp
COPY --from=builder --chown=frankenphp:frankenphp /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=builder /tmp/libs /usr/lib
#
COPY --from=builder /lib/ld-linux-* /lib/
COPY --from=builder /lib64/ld-linux-* /lib64/
COPY --from=builder /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=builder /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
COPY --from=builder --chown=frankenphp:frankenphp /data/caddy /data/caddy
COPY --from=builder --chown=frankenphp:frankenphp /config/caddy /config/caddy

# switch to frankenphp user
USER frankenphp:frankenphp

# copy application files and Caddyfile
COPY --from=builder --chown=frankenphp:frankenphp /app /app
COPY --from=builder --chown=frankenphp:frankenphp /home/frankenphp/ /home/frankenphp/
COPY --chown=frankenphp:frankenphp Caddyfile /etc/caddy/Caddyfile
ENTRYPOINT [ "frankenphp", "run", "--config", "/etc/caddy/Caddyfile" ]