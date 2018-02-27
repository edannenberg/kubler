### kubler/s6:20180227

Built: Tue Feb 27 15:21:18 CET 2018
Image Size: 12.2MB

#### Installed
Package | USE Flags
--------|----------
dev-lang/execline-2.3.0.4 | `-static -static-libs`
dev-libs/skalibs-2.6.3.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.7.0.0 | `-static -static-libs`
*manual install*: entr-3.9 | http://entrproject.org/
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.25-r10 | `hardened rpc -audit -caps -debug -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2017c | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.28.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
