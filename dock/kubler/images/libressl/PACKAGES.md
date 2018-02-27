### kubler/libressl:20180227

Built: Tue Feb 27 15:37:36 CET 2018
Image Size: 14.3MB

#### Installed
Package | USE Flags
--------|----------
app-misc/ca-certificates-20170717.3.35 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/libressl-2.6.0 | `asm -static-libs`
sys-apps/debianutils-4.8.3 | `-static`
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
