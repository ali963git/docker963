#
# NOTE: THIS IS THE PRIMARY DOCKERFILE FOR THE CLI IMAGE
# Built from alpine:3.23 with Docker CLI, Buildx, and Compose
#

FROM alpine:3.23

RUN apk add --no-cache \
	ca-certificates \
	openssh-client \
	git

# ensure that nsswitch.conf is set up for Go's "netgo" implementation
RUN [ -e /etc/nsswitch.conf ] && grep '^hosts: files dns' /etc/nsswitch.conf || echo "hosts: files dns" >> /etc/nsswitch.conf

# pre-add a "docker" group for socket usage
RUN set -eux; \
	addgroup -g 2375 -S docker

ENV DOCKER_VERSION 29.4.3

RUN set -eux; \
	\
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		'x86_64') \
			url='https://download.docker.com/linux/static/stable/x86_64/docker-29.4.3.tgz'; \
			;; \
		'armhf') \
			url='https://download.docker.com/linux/static/stable/armel/docker-29.4.3.tgz'; \
			;; \
		'armv7') \
			url='https://download.docker.com/linux/static/stable/armhf/docker-29.4.3.tgz'; \
			;; \
		'aarch64') \
			url='https://download.docker.com/linux/static/stable/aarch64/docker-29.4.3.tgz'; \
			;; \
		'ppc64le') \
			url='https://download.docker.com/linux/static/stable/ppc64le/docker-29.4.3.tgz'; \
			;; \
		's390x') \
			url='https://download.docker.com/linux/static/stable/s390x/docker-29.4.3.tgz'; \
			;; \
		*) echo >&2 "error: unsupported 'docker.tgz' architecture ($apkArch)"; exit 1 ;; \
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

ENV DOCKER_BUILDX_VERSION 0.34.0
RUN set -eux; \
	\
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		'x86_64') \
			url='https://github.com/docker/buildx/releases/download/v0.34.0/buildx-v0.34.0.linux-amd64'; \
			sha256='0144479d5a1cd710be3464ae898628cfa68033e16b225aef52f81930c45ac9b5'; \
			;; \
		'armhf') \
			url='https://github.com/docker/buildx/releases/download/v0.34.0/buildx-v0.34.0.linux-arm-v6'; \
			sha256='1f34337385921c5da43d63452282726b062aa887fda975f96dd3d6e869648bc6'; \
			;; \
		'armv7') \
			url='https://github.com/docker/buildx/releases/download/v0.34.0/buildx-v0.34.0.linux-arm-v7'; \
			sha256='3560b5b6fd3485f4d0bd160e7edf56cc1f08f0cb5852c9af28bf3fab9973c7c2'; \
			;; \
		'aarch64') \
			url='https://github.com/docker/buildx/releases/download/v0.34.0/buildx-v0.34.0.linux-arm64'; \
			sha256='565605fe0bb393ed5d11771e5b52fc7ef05c701868861fa85609747c9d74a440'; \
			;; \
		*) echo >&2 "warning: unsupported 'docker-buildx' architecture ($apkArch); skipping"; exit 0 ;; \
	esac; \
	\
	wget -O 'docker-buildx' "$url"; \
	echo "$sha256 *"'docker-buildx' | sha256sum -c -; \
	\
	plugin='/usr/local/libexec/docker/cli-plugins/docker-buildx'; \
	mkdir -p "$(dirname "$plugin")"; \
	mv -vT 'docker-buildx' "$plugin"; \
	chmod +x "$plugin"; \
	\
	docker buildx version

ENV DOCKER_COMPOSE_VERSION 5.1.3
RUN set -eux; \
	\
	apkArch="$(apk --print-arch)"; \
	case "$apkArch" in \
		'x86_64') \
			url='https://github.com/docker/compose/releases/download/v5.1.3/docker-compose-linux-x86_64'; \
			sha256='a0298760c9772d2c06888fc8703a487c94c3c3b0134adeef830742a2fc7647b4'; \
			;; \
		'armhf') \
			url='https://github.com/docker/compose/releases/download/v5.1.3/docker-compose-linux-armv6'; \
			sha256='514fc01481017bf4ae55a3b1fe7d598ca49a930e346803648bd88dba9d4ae3da'; \
			;; \
		'armv7') \
			url='https://github.com/docker/compose/releases/download/v5.1.3/docker-compose-linux-armv7'; \
			sha256='4c1ce6ad43c184934a1f76cd55d7231192492c487acbd13e96258ed10fd9e468'; \
			;; \
		'aarch64') \
			url='https://github.com/docker/compose/releases/download/v5.1.3/docker-compose-linux-aarch64'; \
			sha256='e8105a3e687ea7e0b0f81abe4bf9269c8a2801fb72c2b498b5ff2472bc54145f'; \
			;; \
		'ppc64le') \
			url='https://github.com/docker/compose/releases/download/v5.1.3/docker-compose-linux-ppc64le'; \
			sha256='ceaa1a9f24ef471e6f9fc34b30d11dcb6d8021a9a283c5e7261521ef12951432'; \
			;; \
		's390x') \
			url='https://github.com/docker/compose/releases/download/v5.1.3/docker-compose-linux-s390x'; \
			sha256='552d11a594aa3d81b4b69a2abd2a5c2e699378038a8efaa8200c0b556be3451f'; \
			;; \
		*) echo >&2 "warning: unsupported 'docker-compose' architecture ($apkArch); skipping"; exit 0 ;; \
	esac; \
	\
	wget -O 'docker-compose' "$url"; \
	echo "$sha256 *"'docker-compose' | sha256sum -c -; \
	\
	plugin='/usr/local/libexec/docker/cli-plugins/docker-compose'; \
	mkdir -p "$(dirname "$plugin")"; \
	mv -vT 'docker-compose' "$plugin"; \
	chmod +x "$plugin"; \
	\
	ln -sv "$plugin" /usr/local/bin/; \
	docker-compose --version; \
	docker compose version

COPY modprobe.sh /usr/local/bin/modprobe
COPY docker-entrypoint.sh /usr/local/bin/

ENV DOCKER_TLS_CERTDIR=/certs
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sh"]
