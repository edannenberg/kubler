#
# build config
#
PACKAGES=""
CROSSDEV_UCLIBC="armv7a-hardfloat-linux-gnueabi"

configure_bob() {
    # setup crossdev
    mkdir -p /usr/local/portage-crossdev/profiles
    echo 'local-crossdev' > /usr/local/portage-crossdev/profiles/repo_name
    echo "[local-crossdev]
location=/usr/local/portage-crossdev
priority=9999
masters = gentoo
auto-sync = no" > /etc/portage/repos.conf/crossdev.conf

    USE="-fortran nossp" crossdev -S --init-target --target ${CROSSDEV_UCLIBC}
    mkdir -p /usr/${CROSSDEV_UCLIBC}/etc/portage/package.{mask,unmask,use,keywords} /usr/${CROSSDEV_UCLIBC}/tmp/
    rm /usr/${CROSSDEV_UCLIBC}/etc/portage/make.profile
    ln -s /usr/portage/profiles/arch/arm/armv7a /usr/${CROSSDEV_UCLIBC}/etc/portage/make.profile

    cp -rfp /etc/portage/repos.conf/ /usr/${CROSSDEV_UCLIBC}/etc/portage/

    head -n -3 /etc/portage/make.conf > /usr/${CROSSDEV_UCLIBC}/etc/portage/make.conf
    sed -i '7i CHOST=${CROSSDEV_UCLIB} \
CBUILD=x86_64-pc-linux-gnu \
HOSTCC=x86_64-pc-linux-gnu-gcc \
CFLAGS="-O2 -pipe -march=armv7-a -mfloat-abi=hard" \
ROOT=/usr/${CHOST}/ \
ACCEPT_KEYWORDS="*" \
PORTAGE_TMPDIR=${ROOT}tmp/ \
PKG_CONFIG_PATH="${ROOT}usr/lib/pkgconfig/" \
PKGDIR="/packages/${CHOST}"' /usr/${CROSSDEV_UCLIBC}/etc/portage/make.conf

    sed -i -e 's/^ACCEPT_KEYWORDS=" ~"/ACCEPT_KEYWORDS="arm"/g' /usr/${CROSSDEV_UCLIBC}/etc/portage/make.conf

    # quick'n'dirty workaround as libsanitize currently breaks the tool chain build
    echo "cross-${CROSSDEV_UCLIBC}/gcc -sanitize -fortran nossp" > /etc/portage/package.use/gcc

    # init portage env defaults..
    source /etc/profile
    # ..but unset CHOST as it overrides make.conf
    unset CHOST CFLAGS CXXFLAGS

    # fix regression in latest toolchain.eclass - see https://bugs.gentoo.org/show_bug.cgi?id=548782
    sed -i 's/\.\/\${dir}\/\*\.la || die/\.\/\${dir}\/\*\.la/g' /usr/portage/eclass/toolchain.eclass

    crossdev -S --target ${CROSSDEV_UCLIBC}

    rm /etc/portage/package.use/gcc
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    :
}
