### kubler/nginx-php7:20180628

Built: Fri Jun 29 01:27:14 CEST 2018
Image Size: 113MB

#### Installed
Package | USE Flags
--------|----------
app-admin/eselect-1.4.12 | `-doc -emacs -vim-syntax`
app-admin/metalog-3-r2 | `unicode`
app-eselect/eselect-php-0.9.4-r5 | `fpm -apache2`
dev-lang/php-7.1.19 | `acl bcmath bzip2 calendar cli crypt ctype curl fileinfo filter fpm gd hash iconv json mhash mysql mysqli nls opcache pcntl pdo phar posix readline session simplexml soap sockets ssl threads tokenizer unicode webp xml xmlreader xmlrpc xmlwriter xpm xslt zip zlib -apache2 -berkdb -cdb -cgi -cjk -coverage -debug -embed -enchant -exif -firebird -flatfile -ftp -gdbm -gmp -imap -inifile -intl -iodbc -ipv6 -kerberos -ldap -ldap-sasl -libedit -libressl -mssql -oci8-instant-client -odbc -phpdbg -postgres -qdbm -recode (-selinux) -session-mm -sharedmem -snmp -spell -sqlite -systemd -sysvipc {-test} -tidy -truetype -wddx`
dev-libs/expat-2.2.5 | `unicode -examples -static-libs`
dev-libs/gmp-6.1.2 | `asm cxx -doc -pgo -static-libs`
dev-libs/libbsd-0.8.6 | `-static-libs`
dev-libs/libevent-2.1.8 | `ssl threads -debug -libressl -static-libs {-test}`
dev-libs/libgcrypt-1.8.3 | `-doc -o-flag-munging -static-libs`
dev-libs/libgpg-error-1.29 | `nls -common-lisp -static-libs`
dev-libs/libltdl-2.4.6 | `-static-libs`
dev-libs/libmcrypt-2.5.8-r4 | ``
dev-libs/libmemcached-1.0.18-r3 | `libevent -debug -hsieh -sasl -static-libs`
dev-libs/libpthread-stubs-0.4 | ``
dev-libs/libtasn1-4.13 | `-doc -static-libs -valgrind`
dev-libs/libunistring-0.9.7 | `-doc -static-libs`
dev-libs/libxml2-2.9.8 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
dev-libs/libxslt-1.1.32 | `crypt -debug -examples -python -static-libs`
dev-libs/nettle-3.4 | `gmp -doc (-neon) -static-libs {-test}`
dev-libs/oniguruma-6.8.2 | `-crnl-as-line-terminator -static-libs`
dev-php/pecl-apcu-5.1.8 | `lock`
dev-php/pecl-apcu_bc-1.0.3-r1 | ` `
dev-php/pecl-imagick-3.4.3 | `-examples {-test}`
dev-php/pecl-memcached-3.0.4 | `session -examples -igbinary -json -sasl`
dev-php/pecl-redis-3.1.6-r1 | `session -igbinary`
dev-php/xdebug-2.6.0 | ` `
dev-php/xdebug-client-2.6.0 | `-libedit`
mail-mta/nullmailer-2.0-r1 | `ssl`
media-gfx/imagemagick-7.0.7.28 | `bzip2 cxx jpeg jpeg2k png tiff webp zlib -`
media-libs/giflib-5.1.4 | `-doc -static-libs`
media-libs/lcms-2.9 | `jpeg threads tiff -doc -static-libs {-test}`
media-libs/libjpeg-turbo-1.5.1 | `-java -static-libs`
media-libs/libpng-1.6.34 | `-apng (-neon) -static-libs`
media-libs/libwebp-0.5.2 | `gif jpeg png tiff -experimental (-neon) -opengl -static-libs -swap-16bit-csp`
media-libs/openjpeg-2.3.0 | `-doc -static-libs {-test}`
media-libs/tiff-4.0.9-r3 | `cxx jpeg zlib -jbig -lzma -static-libs {-test}`
net-dns/libidn2-2.0.4 | `-static-libs`
net-libs/gnutls-3.5.18 | `cxx idn nls openssl seccomp tls-heartbeat zlib -dane -doc -examples -guile -openpgp -pkcs11 -sslv2 -sslv3 -static-libs {-test} (-test-full) -tools -valgrind`
net-libs/libnsl-1.2.0 | ``
net-libs/libtirpc-1.0.2-r1 | `-ipv6 -kerberos -static-libs`
net-misc/curl-7.60.0 | `ssl threads -adns -brotli -http2 -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
net-misc/memcached-1.5.2 | `-debug -sasl (-selinux) -slabs-reassign {-test}`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r2 | `nls -static-libs`
sys-apps/coreutils-8.28-r1 | `acl nls (xattr) -caps -gmp -hostname -kill -multicall (-selinux) -static {-test} -vanilla`
sys-apps/file-5.33-r2 | `zlib -python -static-libs`
sys-apps/sed-4.5 | `acl nls -forced-sandbox (-selinux) -static`
sys-apps/shadow-4.6 | `acl cracklib nls xattr -audit -pam (-selinux) -skey`
sys-apps/util-linux-2.30.2-r1 | `cramfs nls readline suid unicode -build -caps -fdformat -kill -ncurses -pam -python (-selinux) -slang -static-libs -systemd {-test} -tty-helpers -udev`
sys-devel/gettext-0.19.8.1 | `acl cxx nls openmp -cvs -doc -emacs -git -java -ncurses -static-libs`
sys-libs/cracklib-2.9.6-r1 | `nls zlib -python -static-libs`
sys-libs/ncurses-6.1-r2 | `cxx minimal threads unicode -ada -debug -doc -gpm (-profile) -static-libs {-test} -tinfo -trace`
sys-libs/readline-7.0_p3 | `-static-libs -utils`
x11-base/xorg-proto-2018.4 | ``
x11-libs/libICE-1.0.9-r2 | `-doc -ipv6 -static-libs`
x11-libs/libSM-1.2.2-r2 | `uuid -doc -ipv6 -static-libs`
x11-libs/libX11-1.6.5-r1 | `-doc -ipv6 -static-libs {-test}`
x11-libs/libXau-1.0.8-r1 | `-static-libs`
x11-libs/libxcb-1.13 | `-doc (-selinux) -static-libs {-test} -xkb`
x11-libs/libXdmcp-1.1.2-r2 | `-doc -static-libs`
x11-libs/libXext-1.3.3-r1 | `-doc -static-libs`
x11-libs/libXpm-3.5.12-r1 | `-static-libs`
x11-libs/libXt-1.1.5-r1 | `-static-libs {-test}`
x11-libs/xtrans-1.3.5 | `-doc`
#### Inherited
Package | USE Flags
--------|----------
**FROM kubler/nginx** |
app-arch/bzip2-1.0.6-r9 | `-static -static-libs`
dev-libs/libpcre-8.41-r1 | `bzip2 cxx recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -readline -static-libs`
www-servers/nginx-1.15.0-r2 | `http http-cache http2 pcre ssl threads -aio -debug -ipv6 -libatomic -libressl -luajit -pcre-jit -rtmp (-selinux) -vim-syntax`
**FROM kubler/openssl** |
app-misc/ca-certificates-20170717.3.36.1 | `-cacert -insecure`
app-misc/c_rehash-1.7-r1 | ``
dev-libs/openssl-1.0.2o-r3 | `asm sslv3 tls-heartbeat zlib -bindist -gmp -kerberos -rfc3779 -sctp -sslv2 -static-libs {-test} -vanilla`
sys-apps/debianutils-4.8.3 | `-static`
sys-libs/zlib-1.2.11-r1 | `-minizip -static-libs`
**FROM kubler/s6** |
app-admin/entr-4.1 | `{-test}`
dev-lang/execline-2.3.0.4 | `-static -static-libs`
dev-libs/skalibs-2.6.4.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.7.1.1 | `-static -static-libs`
**FROM kubler/glibc** |
sys-apps/gentoo-functions-0.12 | ``
sys-libs/glibc-2.26-r7 | `hardened -audit -caps -debug -doc -gd -headers-only (-multilib) -nscd (-profile) (-selinux) -suid -systemtap (-vanilla)`
sys-libs/timezone-data-2018d | `nls -leaps`
**FROM kubler/busybox** |
sys-apps/busybox-1.28.0 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
