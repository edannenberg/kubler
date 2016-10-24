### gentoobb/kibana:20161020
Built: Sun Oct 23 22:43:22 CEST 2016

Image Size: 139 MB
#### Installed
Package | USE Flags
--------|----------
www-apps/kibana-bin-4.6.1 | ``
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.22-r4 | `hardened -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2016e | `nls -leaps`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.24.2 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
