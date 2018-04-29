### kubler/pure-ftpd:20180428

Built: Sun Apr 29 03:12:20 CEST 2018
Image Size: 19.3MB

#### Installed
Package | USE Flags
--------|----------
app-emulation/syslog-stdout-1.1.1 | ``
dev-libs/libsodium-1.0.15 | `asm urandom -minimal -static-libs`
net-ftp/ftpbase-0.01-r2 | `-pam`
net-ftp/pure-ftpd-1.0.45-r2 | `ssl vchroot -anondel -anonperm -anonren -anonres -caps -charconv -implicittls -ldap -libressl -mysql -noiplog -pam -paranoidmsg -postgres -resolveids (-selinux) -sysquota -xinetd`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/openssl** |
app-misc/ca-certificates-20170717.3.36.1 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2o | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.8.3 | `-static`
sys-libs/zlib-1.2.11-r1 | `-minizip -static-libs`
**FROM kubler/s6** |
app-admin/entr-4.0 | `{-test}`
dev-lang/execline-2.3.0.4 | `-static -static-libs`
dev-libs/skalibs-2.6.3.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.7.0.0 | `-static -static-libs`
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.25-r11 | `hardened rpc -audit -caps -debug -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2017c | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.28.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
