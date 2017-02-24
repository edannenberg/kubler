FROM busybox:latest

LABEL maintainer ${MAINTAINER}

COPY ${BOB_CURRENT_PORTAGE_FILE} /

RUN set -x && \
    mkdir -p /var/sync && \
    xzcat /${BOB_CURRENT_PORTAGE_FILE} | tar -xf - -C /var/sync && \
    mkdir -p /var/sync/portage/metadata && \
    rm /${BOB_CURRENT_PORTAGE_FILE}

VOLUME /var/sync /var/lib/layman /var/cache/eix
