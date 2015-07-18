### gentoobb/cadvisor:20150709
Built: Sat Jul 18 20:11:49 CEST 2015

Image Size: 28.35 MB
#### Installed
Package | USE Flags
--------|----------
*manual install*: cadvisor-0.16.0 | https://github.com/google/cadvisor/
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.8 | ``
sys-libs/glibc-2.20-r2 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2015b | `nls -right`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.23.1-r1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
