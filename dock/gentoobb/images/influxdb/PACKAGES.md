### gentoobb/influxdb:20151008
Built: Mon Oct 12 18:58:13 CEST 2015

Image Size: 67.08 MB
#### Installed
Package | USE Flags
--------|----------
*manual install*: influxdb-0.9.4.2 | https://github.com/influxdb/influxdb/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.10 | ``
sys-libs/glibc-2.20-r2 | `hardened -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2015f | `nls -leaps`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.23.1-r1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
