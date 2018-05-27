### kubler/redis:20180527

Built: Sun May 27 17:27:41 CEST 2018
Image Size: 16.3MB

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
