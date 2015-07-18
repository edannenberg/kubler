### gentoobb/jdk-icedtea:20150709
Built: Sat Jul 18 20:34:56 CEST 2015

Image Size: 249.6 MB
#### Installed
Package | USE Flags
--------|----------
app-arch/bzip2-1.0.6-r6 | `-static -static-libs`
app-eselect/eselect-java-0.1.0 | ``
dev-java/icedtea-bin-7.2.5.5 | `-`
dev-java/java-config-2.2.0 | ` `
dev-java/java-config-wrapper-0.16 | ``
dev-lang/python-exec-2.0.1-r1 | ` `
dev-libs/elfutils-0.158 | `bzip2 nls utils zlib -lzma -static-libs {-test} (-threads)`
dev-libs/glib-2.42.2 | `mime xattr -dbus -debug (-fam) (-selinux) -static-libs -systemtap {-test} -utils`
dev-libs/gobject-introspection-1.42.0-r1 | `-cairo -doctool {-test}`
dev-libs/gobject-introspection-common-1.42.0 | ``
dev-libs/libffi-3.0.13-r1 | `pax`
dev-libs/libxml2-2.9.2-r1 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
dev-util/pkgconfig-0.28-r2 | `hardened -internal-glib`
gnome-base/gsettings-desktop-schemas-3.14.2 | `introspection`
media-libs/giflib-4.1.6-r3 | `-`
media-libs/lcms-2.6-r1 | `threads zlib -doc -jpeg -static-libs {-test} -tiff`
media-libs/libjpeg-turbo-1.3.1 | `-java -static-libs`
media-libs/libpng-1.6.16 | `-apng (-neon) -static-libs`
sys-apps/baselayout-java-0.1.0 | ``
x11-misc/shared-mime-info-1.4 | `{-test}`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/gcc** |
dev-libs/gmp-5.1.3-r1 | `cxx -doc -pgo -static-libs`
dev-libs/mpc-1.0.2-r1 | `-static-libs`
dev-libs/mpfr-3.1.2_p10 | `-static-libs`
sys-devel/binutils-2.24-r3 | `cxx nls zlib (-multislot) -multitarget -static-libs {-test} -vanilla`
sys-devel/binutils-config-4-r2 | ``
sys-devel/gcc-4.8.4 | `cxx hardened nls nptl openmp (-altivec) (-awt) -debug -doc (-fixed-point) -fortran -gcj -go -graphite (-libssp) -mudflap (-multilib) (-multislot) -nopie -nossp -objc -objc`
sys-devel/gcc-config-1.7.3 | ``
sys-devel/make-4.1-r1 | `nls -guile -static`
sys-kernel/linux-headers-3.18 | ``
**FROM gentoobb/bash** |
app-admin/eselect-1.4.4 | `-doc -emacs -vim-syntax`
app-portage/portage-utils-0.56 | `nls -static`
app-shells/bash-4.3_p33-r2 | `net nls (readline) -afs -bashlogger -examples -mem-scramble -plugins -vanilla`
dev-libs/iniparser-3.1-r1 | `-doc -examples -static-libs`
net-misc/curl-7.43.0 | `ssl threads -adns (-http2) -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/file-5.22 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-libs/ncurses-5.9-r3 | `cxx unicode -ada -debug -doc -gpm -minimal -profile -static-libs -tinfo -trace`
sys-libs/readline-6.3_p8-r2 | `-static-libs -utils`
**FROM gentoobb/openssl** |
app-misc/ca-certificates-20140927.3.17.2 | `cacert`
dev-libs/openssl-1.0.1p | `bindist tls-heartbeat zlib -gmp -kerberos -rfc3779 -static-libs {-test} -vanilla`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r1 | `nls -static-libs`
sys-apps/coreutils-8.23 | `acl nls (xattr) -caps -gmp -multicall (-selinux) -static -vanilla`
sys-apps/debianutils-4.4 | `-static`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
**FROM gentoobb/s6** |
dev-lang/execline-2.1.1.0 | `-static -static-libs`
dev-libs/skalibs-2.3.2.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.1.3.0 | `-static`
*manual install*: entr-3.2 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.8 | ``
sys-libs/glibc-2.20-r2 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2015b | `nls -right`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.23.1-r1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs

#### Included
- [x] Headers from gentoobb/glibc
- [x] Static Libs from gentoobb/glibc
