FROM dunglas/frankenphp:php8.5-trixie AS builder

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
    mbstring \
    iconv \
    && pecl install redis \
    && sh /root/clean.sh \
    && rm /root/clean.sh

# final stage
FROM ubuntu:26.04 AS ubuntu

ARG UBUNTU_RELEASE=26.04
ARG CHISEL_VERSION=v1.4.1

ARG TARGETARCH UBUNTU_RELEASE CHISEL_VERSION
SHELL ["/bin/bash", "-oeux", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive

# add chisel, a tool to create minimal root filesystems for different releases of ubuntu    
ADD "https://github.com/canonical/chisel/releases/download/${CHISEL_VERSION}/chisel_${CHISEL_VERSION}_linux_${TARGETARCH}.tar.gz" \
    chisel.tar.gz

RUN tar -xvf chisel.tar.gz -C /usr/bin/

# add the necessary packages to create a minimal root filesystem for the specified ubuntu release
RUN mkdir /staging-rootfs \
    && chisel cut --release "ubuntu-$UBUNTU_RELEASE" --root /staging-rootfs \
        base-files_base \
        base-files_release-info \
        base-files_chisel \
        ca-certificates_data \
        dash_bins \
        libc6_libs \
        libgcc-s1_libs

RUN install -m 0755 /usr/bin/uv /usr/bin/uvx /staging-rootfs/usr/bin/

RUN cp /etc/passwd /etc/group /staging-rootfs/etc \
    && install -o ubuntu -g ubuntu -d /staging-rootfs/home/ubuntu

FROM scratch as final
WORKDIR /app
COPY --from=ubuntu /etc/passwd /etc/group /etc/
COPY --from=ubuntu /etc/ssl/ /etc/ssl/
COPY --from=ubuntu /etc/localtime /etc/localtime
COPY --from=ubuntu /etc/os-release /etc/os-release
COPY --from=ubuntu /usr/share/zoneinfo/ /usr/share/zoneinfo/

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