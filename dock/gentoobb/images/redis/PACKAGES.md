### gentoobb/redis:20160519
Built: Sun May 22 19:18:48 CEST 2016

Image Size: 13.74 MB
#### Installed
Package | USE Flags
--------|----------
dev-db/redis-3.0.4 | `jemalloc -tcmalloc {-test}`
dev-lang/lua-5.1.5-r3 | `deprecated -emacs -readline -static`
dev-libs/jemalloc-3.6.0 | `-debug -static-libs -stats`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/s6** |
dev-lang/execline-2.1.4.5 | `-static -static-libs`
dev-libs/skalibs-2.3.9.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.2.4.3 | `-static -static-libs`
*manual install*: entr-3.4 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.22-r4 | `hardened -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2016c | `nls -leaps`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.24.2 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
