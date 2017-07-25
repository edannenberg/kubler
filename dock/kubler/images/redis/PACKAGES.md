### kubler/redis:20170723

Built: Sun Jul 23 16:49:54 CEST 2017
Image Size: 14.3MB

#### Installed
Package | USE Flags
--------|----------
dev-db/redis-3.2.8-r2 | `jemalloc -luajit -tcmalloc {-test}`
dev-lang/lua-5.1.5-r4 | `deprecated -emacs -readline -static`
dev-libs/jemalloc-3.6.0 | `-debug -static-libs -stats`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/s6** |
dev-lang/execline-2.3.0.1 | `-static -static-libs`
dev-libs/skalibs-2.5.1.1 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.5.1.0 | `-static -static-libs`
*manual install*: entr-3.6 | http://entrproject.org/
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.23-r4 | `hardened rpc -audit -caps -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2017a | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.25.1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
