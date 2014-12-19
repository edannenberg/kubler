#
# build config
#
PACKAGES=""
CROSSDEV_UCLIBC="x86_64-pc-linux-uclibc"

configure_bob() {
    # setup crossdev
    echo PORTDIR_OVERLAY="/usr/local/portage $PORTDIR_OVERLAY" >> /etc/portage/make.conf
    mkdir -p /usr/local/portage
    crossdev --init-target --target ${CROSSDEV_UCLIBC}
    mkdir -p /usr/${CROSSDEV_UCLIBC}/etc/portage/package.{mask,unmask,use,keywords} /usr/${CROSSDEV_UCLIBC}/tmp/
    rm /usr/${CROSSDEV_UCLIBC}/etc/portage/make.profile
    ln -s /usr/portage/profiles/uclibc/amd64/ /usr/${CROSSDEV_UCLIBC}/etc/portage/make.profile

    head -n -3 /etc/portage/make.conf > /usr/${CROSSDEV_UCLIBC}/etc/portage/make.conf
    sed -i '10i CBUILD=x86_64-pc-linux-gnu \
HOSTCC=x86_64-pc-linux-gnu-gcc \
ROOT=/usr/${CHOST}/ \
ACCEPT_KEYWORDS="*" \
PORTAGE_TMPDIR=${ROOT}tmp/ \
ELIBC="uclibc" \
PKG_CONFIG_PATH="${ROOT}usr/lib/pkgconfig/"' /usr/${CROSSDEV_UCLIBC}/etc/portage/make.conf

    sed -i -e 's/^CHOST="x86_64-pc-linux-gnu"/CHOST="x86_64-pc-linux-uclibc"/g' \
           -e 's/^ACCEPT_KEYWORDS=" ~"/ACCEPT_KEYWORDS="*"/g' \
        /usr/${CROSSDEV_UCLIBC}/etc/portage/make.conf

    # quick'n'dirty workaround as libsanitize currently breaks the tool chain build
    echo "cross-x86_64-pc-linux-uclibc/gcc -sanitize" > /etc/portage/package.use/gcc

    crossdev --target ${CROSSDEV_UCLIBC}

    rm /etc/portage/package.use/gcc
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
