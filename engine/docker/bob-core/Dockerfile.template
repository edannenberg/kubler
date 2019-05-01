FROM ${BOB_CURRENT_STAGE3_ID}
LABEL maintainer ${MAINTAINER}

RUN set -x && \
    echo 'GENTOO_MIRRORS="http://distfiles.gentoo.org/"' >> /etc/portage/make.conf && \
    mkdir -p /etc/portage/repos.conf /usr/portage && \
    sed -e 's|^sync-uri =.*|sync-uri = ${BOB_SYNC_URI}|' \
        -e 's|^sync-type =.*|sync-type = ${BOB_SYNC_TYPE}|' \
        /usr/share/portage/config/repos.conf > /etc/portage/repos.conf/gentoo.conf && \
    chown -R portage:portage /usr/portage && \
    mkdir -p /etc/portage/profile

# DEF_BUILDER_* is only active in configure_bob() hook, generally only differs when using crossdev
ENV DEF_CHOST="${BOB_CHOST}" \
    DEF_CFLAGS="${BOB_CFLAGS}" \
    DEF_CXXFLAGS="${BOB_CXXFLAGS}" \
    DEF_BUILDER_CHOST="${BOB_BUILDER_CHOST}" \
    DEF_BUILDER_CFLAGS="${BOB_BUILDER_CFLAGS}" \
    DEF_BUILDER_CXXFLAGS="${BOB_BUILDER_CXXFLAGS}" \
    PKGDIR="/packages/${BOB_CHOST}"

COPY etc/ /etc/

COPY build-root.sh /usr/local/bin/kubler-build-root

COPY sed-or-die.sh /usr/local/bin/sed-or-die

COPY bashrc.sh /root/.bashrc

COPY portage-git-sync.sh /usr/local/bin/portage-git-sync

CMD ["/bin/bash"]
