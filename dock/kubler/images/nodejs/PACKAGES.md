### kubler/nodejs:20171228

Built: Thu Dec 28 07:54:40 CET 2017
Image Size: 79.3MB

#### Installed
Package | USE Flags
--------|----------
dev-libs/icu-58.2-r1 | `-debug -doc -examples -static-libs`
dev-libs/libuv-1.10.2 | `-static-libs`
net-libs/http-parser-2.6.2 | `-static-libs`
net-libs/nodejs-6.11.5 | `icu npm snapshot ssl -debug -doc {-test}`
sys-apps/yarn-1.2.1 | ``
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/openssl** |
app-misc/ca-certificates-20161130.3.30.2 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2n | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.7 | `-static`
sys-libs/zlib-1.2.11-r1 | `-minizip -static-libs`
**FROM kubler/s6** |
dev-lang/execline-2.3.0.3 | `-static -static-libs`
dev-libs/skalibs-2.6.1.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.6.1.1 | `-static -static-libs`
*manual install*: entr-3.9 | http://entrproject.org/
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.25-r9 | `hardened rpc -audit -caps -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2017c | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.25.1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
