### kubler/jdk-icedtea:20180227

Built: Tue Feb 27 15:33:02 CET 2018
Image Size: 317MB

#### Installed
Package | USE Flags
--------|----------
app-arch/bzip2-1.0.6-r8 | `-static -static-libs`
app-eselect/eselect-fontconfig-1.1 | ``
app-eselect/eselect-java-0.3.0 | ``
dev-java/icedtea-bin-3.6.0 | `headless-awt -alsa (-big-endian) -cups -doc -examples -gtk (-multilib) -nsplugin -pulseaudio (-selinux) -source -webstart`
dev-java/java-config-2.2.0-r3 | `{-test}`
dev-libs/expat-2.2.5 | `unicode -examples -static-libs`
dev-libs/glib-2.52.3 | `mime xattr -dbus -debug (-fam) (-selinux) -static-libs -systemtap {-test} -utils`
dev-libs/libffi-3.2.1 | `-debug -pax`
dev-libs/libpcre-8.41-r1 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-libs/libxml2-2.9.7 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
media-fonts/liberation-fonts-2.00.1-r1 | `-`
media-libs/fontconfig-2.12.6 | `-doc -static-libs`
media-libs/freetype-2.8 | `adobe-cff bindist bzip2 cleartype`
media-libs/lcms-2.9 | `threads -doc -jpeg -static-libs {-test} -tiff`
media-libs/libjpeg-turbo-1.5.1 | `-java -static-libs`
sys-apps/baselayout-java-0.1.0 | ``
sys-apps/util-linux-2.30.2 | `cramfs nls readline suid unicode -build -caps -fdformat -kill -ncurses -pam -python (-selinux) -slang -static-libs -systemd {-test} -tty-helpers -udev`
x11-misc/shared-mime-info-1.9 | `{-test}`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/gcc** |
dev-libs/gmp-6.1.2 | `asm cxx -doc -pgo -static-libs`
dev-libs/mpc-1.0.3 | `-static-libs`
dev-libs/mpfr-3.1.6 | `-static-libs`
sys-devel/binutils-2.29.1-r1 | `cxx nls -multitarget -static-libs {-test} -vanilla`
sys-devel/binutils-config-5-r4 | ``
sys-devel/gcc-6.4.0-r1 | `cxx hardened nls nptl openmp (pie) (ssp) vtv (-altivec) (-awt) -cilk -debug -doc (-fixed-point) -fortran (-gcj) -go -graphite (-jit) (-libssp) -mpx (-multilib) -objc -objc`
sys-devel/gcc-config-1.8-r1 | ``
sys-devel/make-4.2.1 | `nls -guile -static`
sys-kernel/linux-headers-4.13 | `-headers-only`
**FROM kubler/bash** |
app-admin/eselect-1.4.11 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.64 | `nls -static`
app-shells/bash-4.4_p12 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.58.0 | `ssl threads -adns -brotli -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.28-r1 | `acl nls (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static {-test} -vanilla`
sys-apps/file-5.32 | `zlib -python -static-libs`
sys-apps/sed-4.2.2 | `acl nls (-selinux) -static`
sys-libs/ncurses-6.0-r1 | `cxx minimal threads unicode -ada -debug -doc -gpm (-profile) -static-libs {-test} -tinfo -trace`
sys-libs/readline-7.0_p3 | `-static-libs -utils`
**FROM kubler/openssl** |
app-misc/ca-certificates-20161130.3.30.2 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2n | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.8.3 | `-static`
sys-libs/zlib-1.2.11-r1 | `-minizip -static-libs`
**FROM kubler/s6** |
dev-lang/execline-2.3.0.4 | `-static -static-libs`
dev-libs/skalibs-2.6.3.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.7.0.0 | `-static -static-libs`
*manual install*: entr-3.9 | http://entrproject.org/
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.25-r10 | `hardened rpc -audit -caps -debug -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2017c | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.28.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs

#### Included
- [x] Headers from kubler/glibc
- [x] Static Libs from kubler/glibc
