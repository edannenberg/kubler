#
# build config
#
PACKAGES="sys-apps/busybox"
TIMEZONE="${BOB_TIMEZONE:-UTC}"
GLIBC_LOCALES=("en_US ISO-8859-1" "en_US.UTF-8 UTF-8")

#
# this method runs in the bb builder container just before starting the build of the rootfs
# 
configure_rootfs_build()
{
    # -static to enable dns lookups
    mkdir -p /usr/x86_64-pc-linux-uclibc/etc/portage/package.use/
    echo "sys-apps/busybox make-symlinks static" > /usr/x86_64-pc-linux-uclibc/etc/portage/package.use/busybox
    # set locales
    mkdir -p $EMERGE_ROOT/etc
    #for LOCALE in "${GLIBC_LOCALES[@]}"; do
        #    echo "$LOCALE" >> /etc/locale.gen
    #done
    #cp /etc/locale.gen $EMERGE_ROOT/etc/
    # set timezone
    #echo $TIMEZONE > /etc/timezone
    #cp /etc/timezone $EMERGE_ROOT/etc/
    #cp /usr/share/zoneinfo/$TIMEZONE $EMERGE_ROOT/etc/localtime
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
# 
finish_rootfs_build()
{
    # fake portage install
    emerge -p sys-apps/portage | grep sys-apps/portage | grep -Eow "\[.*\] (.*) to" | awk '{print $(NF-1)}' >> ${ROOTFS_BACKUP}/package.installed
    # log dir, root home dir
    mkdir -p $EMERGE_ROOT/var/log $EMERGE_ROOT/root
    # busybox crond setup
    mkdir -p $EMERGE_ROOT/var/spool/cron/crontabs
    chmod 0600 $EMERGE_ROOT/var/spool/cron/crontabs
    # purge glibc locales/charmaps
    #for LOCALE in "${GLIBC_LOCALES[@]}"; do
        #    locale=($LOCALE)
        #locales_filter+=('!' '-name' "${locale[0]}")
        #charmaps_filter+=('!' '-name' "${locale[1]}.gz")
    #done
    #find $EMERGE_ROOT/usr/share/i18n/locales -type f "${locales_filter[@]}" -exec rm -f {} \;
    #find $EMERGE_ROOT/usr/share/i18n/charmaps -type f "${charmaps_filter[@]}" -exec rm -f {} \;
    # backup iconv encodings so other images can pull them in again via ICONV_FROM=busybox
    #tar -cpf /config/tmp/busybox-ICONV.tar $EMERGE_ROOT/usr/lib64/gconv/
    # purge iconv
    #rm -f $EMERGE_ROOT/usr/lib64/gconv/*
    # add entry to purged section in PACKAGES.md
    #write_checkbox_line "Glibc Iconv Encodings" "checked" "${DOC_FOOTER_PURGED}"
}
