### kubler/glibc:20180729

Built: Sun Jul 29 21:14:24 CEST 2018
Image Size: 10.6MB

#### Installed
Package | USE Flags
--------|----------
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.26-r7 | `hardened -audit -caps -debug -doc -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2018d | `nls -leaps`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/busybox** |
sys-apps/busybox-1.28.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`

#### Purged
- [x] Headers
- [x] Static Libs
