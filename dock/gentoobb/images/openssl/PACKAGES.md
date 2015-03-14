### gentoobb/openssl:20150312
Built: Sat Mar 14 23:35:48 CET 2015

Image Size: 19.58 MB
#### Installed
Package | USE Flags
--------|----------
app-misc/ca-certificates-20130906-r1 | ``
dev-libs/openssl-1.0.1k | `bindist tls-heartbeat zlib -gmp -kerberos -rfc3779 -static-libs {-test} -vanilla`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r1 | `nls -static-libs`
sys-apps/coreutils-8.21 | `acl nls (xattr) -caps -gmp (-selinux) -static -vanilla`
sys-apps/debianutils-4.4 | `-static`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/s6** |
dev-lang/execline-2.0.2.1 | `-static -static-libs`
dev-libs/skalibs-2.3.0.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.1.1.1 | `-static`
*manual install*: entr-2.9 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-libs/glibc-2.19-r1 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2014j | `nls -right`
#### Purged
- [x] Headers
- [x] Static Libs
