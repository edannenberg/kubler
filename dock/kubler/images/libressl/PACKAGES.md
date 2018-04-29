### kubler/libressl:20180428

Built: Sat Apr 28 23:50:42 CEST 2018
Image Size: 14.3MB

#### Installed
Package | USE Flags
--------|----------
app-misc/ca-certificates-20180409.3.36.1-r1 | `-cacert`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/libressl-2.6.4 | `asm -static-libs {-test}`
sys-apps/debianutils-4.8.3 | `-static`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.25-r11 | `hardened rpc -audit -caps -debug -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2017c | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.28.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
