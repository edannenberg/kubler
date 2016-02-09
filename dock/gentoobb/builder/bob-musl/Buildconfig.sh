#
# build config
#
PACKAGES=""
EMERGE_BIN="emerge"
CROSSDEV_MUSL="x86_64-pc-linux-musl"

configure_bob() {
    # setup crossdev
    mkdir -p /usr/local/portage-crossdev/profiles
    echo 'local-crossdev' > /usr/local/portage-crossdev/profiles/repo_name
    echo "[local-crossdev]
location=/usr/local/portage-crossdev
priority=9999
masters = gentoo
auto-sync = no" > /etc/portage/repos.conf/crossdev.conf

    crossdev -S --init-target --target ${CROSSDEV_MUSL}
    mkdir -p /usr/${CROSSDEV_MUSL}/etc/portage/package.{mask,unmask,use,keywords} /usr/${CROSSDEV_MUSL}/tmp/
    rm /usr/${CROSSDEV_MUSL}/etc/portage/make.profile
    ln -s /usr/portage/profiles/hardened/linux/musl/amd64 /usr/${CROSSDEV_MUSL}/etc/portage/make.profile

    # add musl portage overlay
    layman -a musl
    cp -rfp /etc/portage/repos.conf/ /usr/${CROSSDEV_MUSL}/etc/portage/

    head -n -3 /etc/portage/make.conf > /usr/${CROSSDEV_MUSL}/etc/portage/make.conf
    sed -i '7i CHOST=x86_64-pc-linux-musl \
CBUILD=x86_64-pc-linux-gnu \
HOSTCC=x86_64-pc-linux-gnu-gcc \
ROOT=/usr/${CHOST}/ \
ACCEPT_KEYWORDS="*" \
PORTAGE_TMPDIR=${ROOT}tmp/ \
ELIBC="musl" \
PKG_CONFIG_PATH="${ROOT}usr/lib/pkgconfig/" \
PKGDIR="/packages/${CHOST}"' /usr/${CROSSDEV_MUSL}/etc/portage/make.conf

    sed -i -e 's/^ACCEPT_KEYWORDS=" ~"/ACCEPT_KEYWORDS="amd64"/g' /usr/${CROSSDEV_MUSL}/etc/portage/make.conf

    # quick'n'dirty workaround as libsanitize currently breaks the tool chain build
    echo "cross-${CROSSDEV_MUSL}/gcc -sanitize" > /etc/portage/package.use/gcc

    # init portage env defaults..
    source /etc/profile
    # ..but unset CHOST as it overrides make.conf
    unset CHOST

    # fix regression in latest toolchain.eclass - see https://bugs.gentoo.org/show_bug.cgi?id=548782
    sed -i 's/\.\/\${dir}\/\*\.la || die/\.\/\${dir}\/\*\.la/g' /usr/portage/eclass/toolchain.eclass

    crossdev -S --target ${CROSSDEV_MUSL}

    rm /etc/portage/package.use/gcc
}
