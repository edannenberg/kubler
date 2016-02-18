### gentoobb/s6:20160211
Built: Thu Feb 18 02:58:26 CET 2016

Image Size: 11.79 MB
#### Installed
Package | USE Flags
--------|----------
dev-lang/execline-2.1.4.5 | `-static -static-libs`
dev-libs/skalibs-2.3.9.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.2.4.3 | `-static`
*manual install*: entr-3.4 | http://entrproject.org/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.21-r2 | `hardened -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2015g | `nls -leaps`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.24.1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
