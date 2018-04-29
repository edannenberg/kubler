### kubler/libressl-musl:20180428

Built: Sun Apr 29 00:03:48 CEST 2018
Image Size: 5.54MB

#### Installed
Package | USE Flags
--------|----------
app-misc/c_rehash-1.7-r1 | ``
app-misc/ca-certificates-20180409.3.36.1-r1 | `-cacert`
dev-libs/libressl-2.6.4 | `asm -static-libs {-test}`
sys-apps/debianutils-4.8.3 | `-static`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/musl** |
sys-libs/musl-1.1.19 | `-headers-only`
**FROM kubler/busybox** |
sys-apps/busybox-1.28.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
