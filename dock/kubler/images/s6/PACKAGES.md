### kubler/s6:20171030

Built: Mon Oct 30 14:13:29 CET 2017
Image Size: 11.9MB

#### Installed
Package | USE Flags
--------|----------
dev-lang/execline-2.3.0.2 | `-static -static-libs`
dev-libs/skalibs-2.6.0.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.6.1.0 | `-static -static-libs`
*manual install*: entr-3.9 | http://entrproject.org/
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.25-r8 | `hardened rpc -audit -caps -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2017a | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.25.1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
