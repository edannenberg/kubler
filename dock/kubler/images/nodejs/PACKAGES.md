### kubler/nodejs:20181130

Built: Fri Nov 30 18:53:10 CET 2018
Image Size: 91.6MB

#### Installed
Package | USE Flags
--------|----------
dev-libs/icu-60.2 | `-debug -doc -examples -static-libs`
dev-libs/libuv-1.20.0 | `-static-libs`
net-libs/http-parser-2.8.1 | `-static-libs`
net-libs/nghttp2-1.33.0 | `cxx threads -debug -hpack-tools -jemalloc -libressl -static-libs -test -utils -xml`
net-libs/nodejs-8.12.0 | `icu npm snapshot ssl -debug -doc -inspector -systemtap -test`
sys-apps/yarn-1.12.3 | ``
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/openssl** |
app-misc/ca-certificates-20170717.3.36.1 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2p-r1 | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs -test -vanilla`
sys-apps/debianutils-4.8.3 | `-static`
sys-libs/zlib-1.2.11-r2 | `-minizip -static-libs`
**FROM kubler/s6** |
app-admin/entr-4.1 | `-test`
dev-lang/execline-2.5.0.1 | `-static -static-libs`
dev-libs/skalibs-2.7.0.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.7.2.1 | `-static -static-libs`
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.27-r6 | `hardened multiarch -audit -caps (-compile-locales) -doc -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2018g | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.29.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
