### kubler/libressl:20171030

Built: Mon Oct 30 14:35:05 CET 2017
Image Size: 14.1MB

#### Installed
Package | USE Flags
--------|----------
app-misc/ca-certificates-20170717.3.33 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/libressl-2.6.0 | `asm -static-libs`
sys-apps/debianutils-4.7 | `-static`
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
