# Docker CLI Dockerfile
# Based on Alpine Linux
FROM alpine:3.23

# Install required packages
RUN apk add --no-cache \
    ca-certificates \
    openssh-client \
    git \
    wget \
    curl \
    bash

# ensure that nsswitch.conf is set up for Go's "netgo" implementation
RUN [ -e /etc/nsswitch.conf ] && grep '^hosts: files dns' /etc/nsswitch.conf || echo "hosts: files dns" >> /etc/nsswitch.conf

# pre-add a "docker" group for socket usage
RUN set -eux; \
    addgroup -g 2375 -S docker

ENV DOCKER_VERSION=27.0.0

# Download and install Docker CLI
RUN set -eux; \
    \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
        'x86_64') \
            url='https://download.docker.com/linux/static/stable/x86_64/docker-27.0.0.tgz'; \
            ;; \
        'aarch64') \
            url='https://download.docker.com/linux/static/stable/aarch64/docker-27.0.0.tgz'; \
            ;; \
        'armv7') \
            url='https://download.docker.com/linux/static/stable/armhf/docker-27.0.0.tgz'; \
            ;; \
        'armv6') \
            url='https://download.docker.com/linux/static/stable/armel/docker-27.0.0.tgz'; \
            ;; \
        *) echo >&2 "error: unsupported architecture ($apkArch)"; exit 1 ;; \
    esac; \
    \
    wget -O 'docker.tgz' "$url"; \
    \
    tar --extract \
        --file docker.tgz \
        --strip-components 1 \
        --directory /usr/local/bin/ \
        --no-same-owner \
        'docker/docker' \
    ; \
    rm docker.tgz; \
    \
    docker --version

# Copy helper scripts
COPY modprobe.sh /usr/local/bin/modprobe
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/modprobe /usr/local/bin/docker-entrypoint.sh

# Setup TLS certificates directory
ENV DOCKER_TLS_CERTDIR=/certs
RUN mkdir -p /certs /certs/client && chmod 1777 /certs /certs/client

# Set working directory
WORKDIR /root

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sh"]
