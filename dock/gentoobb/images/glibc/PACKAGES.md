### gentoobb/glibc:20150910
Built: Sat Sep 12 21:32:14 CEST 2015

Image Size: 10.42 MB
#### Installed
Package | USE Flags
--------|----------
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.20-r2 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2015e | `nls -leaps`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/busybox** |
sys-apps/busybox-1.23.1-r1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`

#### Purged
- [x] Headers
- [x] Static Libs
