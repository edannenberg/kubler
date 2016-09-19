### gentoobb/webhook:20160915
Built: Mon Sep 19 02:15:15 CEST 2016

Image Size: 59.48 MB
#### Installed
Package | USE Flags
--------|----------
app-arch/bzip2-1.0.6-r7 | `-static -static-libs`
app-crypt/gnupg-2.0.28 | `bzip2 nls readline -doc -ldap -mta (-selinux) -smartcard -static -tools -usb`
app-crypt/pinentry-0.9.5 | `ncurses -caps -clipboard -emacs -gnome-keyring -gtk -qt4 -static`
app-eselect/eselect-lib-bin-symlink-0.1.1 | ``
app-eselect/eselect-pinentry-0.6 | ``
dev-libs/libassuan-2.2.1 | `-static-libs`
dev-libs/libgcrypt-1.7.3 | `-doc -static-libs`
dev-libs/libgpg-error-1.19 | `nls -common-lisp -static-libs`
dev-libs/libksba-1.3.5 | `-static-libs`
dev-libs/libpcre-8.38-r1 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-libs/pth-2.0.7-r3 | `-debug -static-libs`
dev-vcs/git-2.7.3-r1 | `blksha1 curl gpg iconv nls pcre threads -cgi -cvs -doc -emacs -gnome-keyring -gtk -highlight (-libressl) -mediawiki -mediawiki-experimental -perl (-ppcsha1) -python -subversion {-test} -tk -webdav -xinetd`
*manual install*: webhook-2.4.0 | https://github.com/adnanh/webhook/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/bash** |
app-admin/eselect-1.4.5 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.62 | `nls -static`
app-shells/bash-4.3_p42-r1 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins -vanilla`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.50.3 | `ssl threads -adns -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/file-5.25 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-libs/ncurses-5.9-r5 | `cxx unicode -ada -debug -doc -gpm -minimal (-profile) -static-libs -tinfo -trace`
sys-libs/ncurses-5.9-r99 | `cxx unicode -ada -gpm -static-libs -tinfo`
sys-libs/readline-6.3_p8-r2 | `-static-libs -utils`
**FROM gentoobb/openssl** |
app-misc/ca-certificates-20151214.3.21 | `cacert`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2h-r2 | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.7 | `-static`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
**FROM gentoobb/s6** |
dev-lang/execline-2.1.5.0 | `-static -static-libs`
dev-libs/skalibs-2.3.10.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.3.0.0 | `-static -static-libs`
*manual install*: entr-3.4 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.22-r4 | `hardened -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2016e | `nls -leaps`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.24.2 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
