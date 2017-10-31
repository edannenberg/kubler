### kubler/pure-ftpd:20171030

Built: Mon Oct 30 15:38:20 CET 2017
Image Size: 19.2MB

#### Installed
Package | USE Flags
--------|----------
dev-libs/libsodium-1.0.11 | `asm urandom -minimal -static-libs`
net-ftp/ftpbase-0.01-r2 | `-pam`
net-ftp/pure-ftpd-1.0.45-r1 | `ssl vchroot -anondel -anonperm -anonren -anonres -caps -charconv -implicittls -ldap (-libressl) -mysql -noiplog -pam -paranoidmsg -postgres -resolveids (-selinux) -sysquota -xinetd`
*manual install*: syslog-stdout-1.1.1 | https://github.com/timonier/syslog-stdout
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/openssl** |
app-misc/ca-certificates-20161130.3.30.2 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2l | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.7 | `-static`
sys-libs/zlib-1.2.11-r1 | `-minizip -static-libs`
**FROM kubler/s6** |
dev-lang/execline-2.3.0.2 | `-static -static-libs`
dev-libs/skalibs-2.6.0.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.6.1.0 | `-static -static-libs`
*manual install*: entr-3.9 | http://entrproject.org/
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.25-r8 | `hardened rpc -audit -caps -debug -gd (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2017a | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.25.1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
