#!/usr/bin/env bash
#
# build config
#
_packages="sys-libs/glibc"
_timezone="${BOB_TIMEZONE:-UTC}"
_glibc_locales=("en_US ISO-8859-1")
BOB_SKIP_LIB_CLEANUP=true

configure_bob()
{
    local locale
     # set locales
    for locale in "${_glibc_locales[@]}"; do
        echo "${locale}" >> /etc/locale.gen
    done
    locale-gen
    mkdir -p "${_EMERGE_ROOT}"/usr/lib64/locale
    cp /usr/lib64/locale/locale-archive "${_EMERGE_ROOT}"/usr/lib64/locale/
    # set timezone
    echo $_timezone > /etc/timezone
}

#
# this method runs in the bb builder container just before starting the build of the rootfs
#
configure_rootfs_build()
{
    # make sure lib symlink exists before gentoofunctions package creates a dir during install
    mkdir -p "${_EMERGE_ROOT}"/lib64
    ln -sr "${_EMERGE_ROOT}"/lib64 "${_EMERGE_ROOT}"/lib
    # as we broke the normal builder chain, recreate the docs for the busybox image
    init_docs 'kubler/busybox'
    update_use 'sys-apps/busybox' '+static +make-symlinks'
    generate_doc_package_installed 'sys-apps/busybox'
    # fake portage install
    provide_package sys-apps/portage

    # set locales
    mkdir -p "${_EMERGE_ROOT}"/etc
    cp /etc/locale.gen "${_EMERGE_ROOT}"/etc/
    # set timezone
    cp /etc/timezone "${_EMERGE_ROOT}"/etc/
    cp /usr/share/zoneinfo/"${_timezone}" "${_EMERGE_ROOT}"/etc/localtime
}

#
# this method runs in the bb builder container just before tar'ing the rootfs
#
finish_rootfs_build()
{
    # purge glibc locales/charmaps
    for locale in "${_glibc_locales[@]}"; do
        locale=($locale)
        locales_filter+=('!' '-name' "${locale[0]}")
        charmaps_filter+=('!' '-name' "${locale[1]}.gz")
    done
    find "${_EMERGE_ROOT}"/usr/share/i18n/locales -type f "${locales_filter[@]}" -delete
    find "${_EMERGE_ROOT}"/usr/share/i18n/charmaps -type f "${charmaps_filter[@]}" -delete
    # backup iconv encodings so other images can pull them in again via _iconv_from=glibc
    tar -cpf "${_ROOTFS_BACKUP}"/glibc-iconv.tar "${_EMERGE_ROOT}"/usr/lib64/gconv/
    # purge iconv
    rm -f "${_EMERGE_ROOT}"/usr/lib64/gconv/*
    # add entry to purged section in PACKAGES.md
    write_checkbox_line "Glibc Iconv Encodings" "checked" "${_DOC_FOOTER_PURGED}"
}
