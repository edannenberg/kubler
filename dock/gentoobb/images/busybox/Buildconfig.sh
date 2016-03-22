#
# build config
#
PACKAGES="sys-apps/busybox"
EMERGE_BIN="emerge-${BOB_BUSYBOX_CHOST}"
# fix digest of busybox ebuild in musl overlay after patching
EMERGE_OPT="--digest"

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    export CHOST=${BOB_BUSYBOX_CHOST}
    echo "sys-apps/busybox make-symlinks static" > /usr/${BOB_BUSYBOX_CHOST}/etc/portage/package.use/busybox
    # add missing busybox unzip regression patch to musl overlay and fix patch order in ebuild
    # https://bugs.gentoo.org/show_bug.cgi?id=567340
    cp /usr/portage/sys-apps/busybox/files/busybox-1.24.1-unzip-regression.patch /var/lib/layman/musl/sys-apps/busybox/files/
    cat << 'EOP' | patch -p1 --ignore-whitespace /var/lib/layman/musl/sys-apps/busybox/busybox-1.24.1-r99.ebuild
--- var/lib/layman/musl/sys-apps/busybox/busybox-1.24.1-r99.ebuild 2016-03-21 03:52:08.000000000 +0000
+++ usr/portage/sys-apps/busybox/busybox-1.24.1.ebuild 2015-12-31 05:51:48.000000000 +0000
@@ -67,7 +67,8 @@

    # patches go here!
    epatch "${FILESDIR}"/${PN}-1.19.0-bb.patch
-   epatch "${FILESDIR}"/${P}-*.patch
+   epatch "${FILESDIR}"/busybox-1.24.1-unzip.patch
+   epatch "${FILESDIR}"/busybox-1.24.1-unzip-regression.patch
    cp "${FILESDIR}"/ginit.c init/ || die

    # flag cleanup
EOP
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    # log dir, root home dir
    mkdir -p $EMERGE_ROOT/var/log $EMERGE_ROOT/root
    # busybox crond setup
    mkdir -p $EMERGE_ROOT/var/spool/cron/crontabs
    chmod 0600 $EMERGE_ROOT/var/spool/cron/crontabs
}
