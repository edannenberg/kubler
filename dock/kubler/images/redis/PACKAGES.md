### kubler/redis:20171030

Built: Mon Oct 30 15:42:22 CET 2017
Image Size: 16MB

#### Installed
Package | USE Flags
--------|----------
dev-db/redis-4.0.2-r1 | `jemalloc -luajit -tcmalloc {-test}`
dev-lang/lua-5.1.5-r4 | `deprecated -emacs -readline -static`
dev-libs/jemalloc-3.6.0 | `-debug -static-libs -stats`
#### Inherited
Package | USE Flags
--------|----------
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
