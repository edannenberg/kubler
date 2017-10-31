### kubler/jdk-icedtea:20171030

Built: Mon Oct 30 14:31:12 CET 2017
Image Size: 304MB

#### Installed
Package | USE Flags
--------|----------
app-arch/bzip2-1.0.6-r8 | `-static -static-libs`
app-eselect/eselect-fontconfig-1.1 | ``
app-eselect/eselect-java-0.3.0 | ``
dev-java/icedtea-bin-3.5.1 | `headless-awt -alsa (-big-endian) -cups -doc -examples -gtk (-multilib) -nsplugin -pulseaudio (-selinux) -source -webstart`
dev-java/java-config-2.2.0-r3 | `{-test}`
dev-libs/expat-2.2.1 | `unicode -examples -static-libs`
dev-libs/glib-2.50.3-r1 | `mime xattr -dbus -debug (-fam) (-selinux) -static-libs -systemtap {-test} -utils`
dev-libs/libffi-3.2.1 | `-debug -pax`
dev-libs/libpcre-8.41 | `bzip2 cxx readline recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -static-libs`
dev-libs/libxml2-2.9.4-r3 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
media-fonts/liberation-fonts-2.00.1-r1 | `-`
media-libs/fontconfig-2.12.4 | `-doc -static-libs`
media-libs/freetype-2.8 | `adobe-cff bindist bzip2 cleartype`
media-libs/lcms-2.8-r1 | `threads zlib -doc -jpeg -static-libs {-test} -tiff`
media-libs/libjpeg-turbo-1.5.1 | `-java -static-libs`
sys-apps/baselayout-java-0.1.0 | ``
sys-apps/util-linux-2.28.2 | `cramfs nls readline suid unicode -build -caps -fdformat -kill -ncurses -pam -python (-selinux) -slang -static-libs -systemd {-test} -tty-helpers -udev`
x11-misc/shared-mime-info-1.8 | `{-test}`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/gcc** |
dev-libs/gmp-6.1.0 | `asm cxx -doc -pgo -static-libs`
dev-libs/mpc-1.0.2-r1 | `-static-libs`
dev-libs/mpfr-3.1.3_p4 | `-static-libs`
sys-devel/binutils-2.28.1 | `cxx nls -multitarget -static-libs {-test} -vanilla`
sys-devel/binutils-config-5-r3 | ``
sys-devel/gcc-5.4.0-r3 | `cxx hardened nls nptl openmp vtv (-altivec) (-awt) -cilk -debug -doc (-fixed-point) -fortran -gcj -go -graphite (-jit) (-libssp) -mpx (-multilib) -nopie -nossp -objc -objc`
sys-devel/gcc-config-1.8-r1 | ``
sys-devel/make-4.2.1 | `nls -guile -static`
sys-kernel/linux-headers-4.4 | ``
**FROM kubler/bash** |
app-admin/eselect-1.4.8 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.64 | `nls -static`
app-shells/bash-4.3_p48-r1 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.56.1 | `ssl threads -adns -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.26 | `acl nls (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static -vanilla`
sys-apps/file-5.32 | `zlib -python -static-libs`
sys-apps/sed-4.2.2 | `acl nls (-selinux) -static`
sys-libs/ncurses-6.0-r1 | `cxx minimal threads unicode -ada -debug -doc -gpm (-profile) -static-libs {-test} -tinfo -trace`
sys-libs/readline-6.3_p8-r3 | `-static-libs -utils`
**FROM kubler/openssl** |
app-misc/ca-certificates-20161130.3.30.2 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2l | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.7 | `-static`
sys-libs/zlib-1.2.11-r1 | `-minizip -static-libs`
**FROM kubler/s6** |
dev-lang/execline-2.3.0.2 | `-static -static-libs`
dev-libs/skalibs-2.6.0.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.6.1.0 | `-static -static-libs`
*manual install*: entr-3.9 | http://entrproject.org/
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.25-r8 | `hardened rpc -audit -caps -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2017a | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.25.1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs

#### Included
- [x] Headers from kubler/glibc
- [x] Static Libs from kubler/glibc
