### kubler/jdk-icedtea:20180831

Built: Fri Aug 31 18:11:57 CEST 2018
Image Size: 320MB

#### Installed
Package | USE Flags
--------|----------
app-arch/bzip2-1.0.6-r10 | `-static -static-libs`
app-eselect/eselect-fontconfig-1.1 | ``
app-eselect/eselect-java-0.4.0 | ``
dev-java/icedtea-bin-3.8.0 | `headless-awt -alsa (-big-endian) -cups -doc -examples -gtk (-multilib) -nsplugin -pulseaudio (-selinux) -source -webstart`
dev-java/java-config-2.2.0-r4 | `{-test}`
dev-libs/expat-2.2.5 | `unicode -examples -static-libs`
dev-libs/glib-2.52.3 | `mime xattr -dbus -debug (-fam) (-selinux) -static-libs -systemtap {-test} -utils`
dev-libs/libffi-3.2.1 | `-debug -pax`
dev-libs/libpcre-8.41-r1 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-libs/libxml2-2.9.8 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
media-fonts/liberation-fonts-2.00.1-r3 | `-`
media-libs/fontconfig-2.13.0-r4 | `-doc -static-libs`
media-libs/freetype-2.9.1-r3 | `adobe-cff bindist bzip2 cleartype`
media-libs/lcms-2.9 | `threads -doc -jpeg -static-libs {-test} -tiff`
media-libs/libjpeg-turbo-1.5.3-r2 | `-java -static-libs`
sys-apps/baselayout-java-0.1.0 | ``
sys-apps/util-linux-2.32-r4 | `cramfs nls readline suid unicode -build -caps -fdformat -kill -ncurses -pam -python (-selinux) -slang -static-libs -systemd {-test} -tty-helpers -udev`
x11-misc/shared-mime-info-1.9 | `{-test}`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/gcc** |
dev-libs/gmp-6.1.2 | `asm cxx -doc -pgo -static-libs`
dev-libs/mpc-1.0.3 | `-static-libs`
dev-libs/mpfr-3.1.6 | `-static-libs`
sys-devel/binutils-2.30-r2 | `cxx nls -doc -multitarget -static-libs {-test}`
sys-devel/binutils-config-5-r4 | ``
sys-devel/gcc-7.3.0-r3 | `cxx hardened nls nptl openmp (pie) (ssp) vtv (-altivec) -cilk -debug -doc (-fixed-point) -fortran -go -graphite (-jit) (-libssp) -mpx (-multilib) -objc -objc`
sys-devel/gcc-config-1.8-r1 | ``
sys-devel/make-4.2.1-r3 | `nls -guile -static`
sys-kernel/linux-headers-4.13 | `-headers-only`
**FROM kubler/bash** |
app-admin/eselect-1.4.12 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.64 | `nls -static`
app-shells/bash-4.4_p12 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.61.0 | `ssl threads -adns -brotli -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.29-r1 | `acl nls split-usr (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static {-test} -vanilla`
sys-apps/file-5.33-r4 | `zlib -python -static-libs`
sys-apps/sed-4.5 | `acl nls -forced-sandbox (-selinux) -static`
sys-libs/ncurses-6.1-r2 | `cxx minimal threads unicode -ada -debug -doc -gpm (-profile) -static-libs {-test} -tinfo -trace`
sys-libs/readline-7.0_p3 | `-static-libs -utils`
**FROM kubler/openssl** |
app-misc/ca-certificates-20170717.3.36.1 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2o-r3 | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.8.3 | `-static`
sys-libs/zlib-1.2.11-r2 | `-minizip -static-libs`
**FROM kubler/s6** |
app-admin/entr-4.1 | `{-test}`
dev-lang/execline-2.3.0.4 | `-static -static-libs`
dev-libs/skalibs-2.6.4.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.7.1.1 | `-static -static-libs`
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.26-r7 | `hardened -audit -caps -debug -doc -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2018e | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.29.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs

#### Included
- [x] Headers from kubler/glibc
- [x] Static Libs from kubler/glibc
