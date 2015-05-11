### gentoobb/docker-registry:20150507
Built: Mon May 11 21:40:14 CEST 2015

Image Size: 50.56 MB
#### Installed
Package | USE Flags
--------|----------
*manual install*: docker-registry-2.0.0 | http://github.com/docker/distribution/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/openssl** |
app-misc/ca-certificates-20140927.3.17.2 | `cacert`
dev-libs/openssl-1.0.1l-r1 | `bindist tls-heartbeat zlib -gmp -kerberos -rfc3779 -static-libs {-test} -vanilla`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r1 | `nls -static-libs`
sys-apps/coreutils-8.21 | `acl nls (xattr) -caps -gmp (-selinux) -static -vanilla`
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
