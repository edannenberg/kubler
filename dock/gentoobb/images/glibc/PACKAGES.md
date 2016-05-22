### gentoobb/glibc:20160519
Built: Sun May 22 16:16:34 CEST 2016

Image Size: 10.7 MB
#### Installed
Package | USE Flags
--------|----------
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.22-r4 | `hardened -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2016c | `nls -leaps`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/busybox** |
sys-apps/busybox-1.24.2 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`

#### Purged
- [x] Headers
- [x] Static Libs
