### kubler/nodejs:20180428

Built: Sat Apr 28 22:42:42 CEST 2018
Image Size: 91.5MB

#### Installed
Package | USE Flags
--------|----------
dev-libs/icu-60.2 | `-debug -doc -examples -static-libs`
dev-libs/libuv-1.20.0 | `-static-libs`
net-libs/http-parser-2.8.1 | `-static-libs`
net-libs/nghttp2-1.31.1 | `cxx threads -debug -hpack-tools -jemalloc -libressl -static-libs {-test} -utils -xml`
net-libs/nodejs-8.11.1 | `icu npm snapshot ssl -debug -doc -inspector -systemtap {-test}`
sys-apps/yarn-1.5.1 | ``
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/openssl** |
app-misc/ca-certificates-20170717.3.36.1 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2o | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.8.3 | `-static`
sys-libs/zlib-1.2.11-r1 | `-minizip -static-libs`
**FROM kubler/s6** |
app-admin/entr-4.0 | `{-test}`
dev-lang/execline-2.3.0.4 | `-static -static-libs`
dev-libs/skalibs-2.6.3.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.7.0.0 | `-static -static-libs`
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.25-r11 | `hardened rpc -audit -caps -debug -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2017c | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.28.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
