### gentoobb/nginx-php5.5:20150709
Built: Sat Jul 18 21:12:05 CEST 2015

Image Size: 97.81 MB
#### Installed
Package | USE Flags
--------|----------
app-admin/eselect-1.4.4 | `-doc -emacs -vim-syntax`
app-admin/metalog-3-r1 | `unicode`
app-eselect/eselect-php-0.7.1-r4 | `fpm -apache2`
dev-lang/php-5.5.26 | `bcmath berkdb bzip2 calendar cli crypt ctype curl fileinfo filter fpm gd hash iconv json mhash mysql mysqli nls opcache pdo phar posix readline session simplexml soap sockets ssl threads tokenizer unicode xml xmlreader xmlrpc xmlwriter xpm zip zlib -apache2 -cdb -cgi -cjk -debug -embed -enchant -exif (-firebird) -flatfile (-frontbase) -ftp -gdbm -gmp -imap -inifile -intl -iodbc -ipv6 -kerberos -ldap -ldap-sasl -libedit -libmysqlclient -mssql -oci8-instant-client -odbc -pcntl -postgres -qdbm -recode (-selinux) -sharedmem -snmp -spell -sqlite (-sybase-ct) -systemd -sysvipc -tidy -truetype -vpx -wddx -xslt`
dev-libs/expat-2.1.0-r4 | `unicode -examples -static-libs`
dev-libs/gmp-5.1.3-r1 | `cxx -doc -pgo -static-libs`
dev-libs/libltdl-2.4.6 | `-static-libs`
dev-libs/libmcrypt-2.5.8-r2 | ``
dev-libs/libpthread-stubs-0.3-r1 | `-static-libs`
dev-libs/libtasn1-4.5 | `-doc -static-libs`
dev-libs/libxml2-2.9.2-r1 | `readline -debug -examples -icu -ipv6 -lzma -python -static-libs {-test}`
dev-libs/nettle-2.7.1-r4 | `gmp -doc (-neon) -static-libs {-test}`
dev-libs/oniguruma-5.9.5 | `-combination-explosion-check -crnl-as-line-terminator -static-libs`
dev-php/pecl-apcu-4.0.7 | `lock`
dev-php/pecl-imagick-3.1.2 | `-examples`
dev-php/pecl-memcache-3.0.8-r1 | `session`
dev-php/pecl-redis-2.2.3 | `-igbinary`
dev-php/xdebug-2.2.6 | ` `
dev-php/xdebug-client-2.2.6 | `-libedit`
mail-mta/nullmailer-1.13-r5 | `ssl`
media-gfx/imagemagick-6.9.0.3 | `bzip2 cxx openmp zlib -`
media-libs/libjpeg-turbo-1.3.1 | `-java -static-libs`
media-libs/libpng-1.6.16 | `-apng (-neon) -static-libs`
net-dns/libidn-1.30 | `nls -doc -emacs -java -mono -static-libs`
net-libs/gnutls-3.3.15 | `crywrap cxx nls openssl zlib -dane -doc -examples -guile -pkcs11 -static-libs {-test}`
net-misc/curl-7.43.0 | `ssl threads -adns (-http2) -idn -ipv6 -kerberos -ldap -metalink -rtmp -samba -ssh -static-libs {-test}`
sys-apps/file-5.22 | `zlib -python -static-libs`
sys-apps/sed-4.2.1-r1 | `acl nls (-selinux) -static`
sys-apps/shadow-4.1.5.1-r1 | `acl cracklib nls xattr -audit -pam (-selinux) -skey`
sys-apps/util-linux-2.25.2-r2 | `cramfs nls suid unicode -caps -fdformat -ncurses -pam -python (-selinux) -slang -static-libs -systemd {-test} -tty-helpers -udev`
sys-devel/gettext-0.19.4 | `acl cxx nls openmp -cvs -doc -emacs -git -java -ncurses -static-libs`
sys-libs/cracklib-2.9.1-r1 | `nls zlib -python -static-libs {-test}`
sys-libs/db-4.8.30-r2 | `cxx -doc -examples -java -tcl {-test}`
sys-libs/ncurses-5.9-r3 | `cxx unicode -ada -debug -doc -gpm -minimal -profile -static-libs -tinfo -trace`
sys-libs/readline-6.3_p8-r2 | `-static-libs -utils`
x11-libs/libICE-1.0.9 | `-doc -ipv6 -static-libs`
x11-libs/libSM-1.2.2-r1 | `uuid -doc -ipv6 -static-libs`
x11-libs/libX11-1.6.2 | `-doc -ipv6 -static-libs {-test}`
x11-libs/libXau-1.0.8 | `-static-libs`
x11-libs/libXdmcp-1.1.1-r1 | `-doc -static-libs`
x11-libs/libXext-1.3.3 | `-doc -static-libs`
x11-libs/libXpm-3.5.11 | `-static-libs`
x11-libs/libXt-1.1.4 | `-static-libs`
x11-libs/libxcb-1.11-r1 | `-doc (-selinux) -static-libs {-test} -xkb`
x11-libs/xtrans-1.3.5 | `-doc`
x11-proto/inputproto-2.3.1 | ``
x11-proto/kbproto-1.0.6-r1 | ``
x11-proto/xextproto-7.3.0 | `-doc`
x11-proto/xf86bigfontproto-1.2.0-r1 | ``
x11-proto/xproto-7.0.27 | `-doc`
#### Inherited
Package | USE Flags
--------|----------
**FROM gentoobb/nginx** |
app-arch/bzip2-1.0.6-r6 | `-static -static-libs`
dev-libs/libpcre-8.36 | `bzip2 cxx recursion-limit (unicode) zlib -jit -libedit -pcre16 -pcre32 -readline -static-libs`
www-servers/nginx-1.7.6 | `http http-cache pcre ssl -aio -debug -ipv6 -libatomic -luajit -pcre-jit -rtmp (-selinux) -vim-syntax`
**FROM gentoobb/openssl** |
app-misc/ca-certificates-20140927.3.17.2 | `cacert`
dev-libs/openssl-1.0.1p | `bindist tls-heartbeat zlib -gmp -kerberos -rfc3779 -static-libs {-test} -vanilla`
sys-apps/acl-2.2.52-r1 | `nls -static-libs`
sys-apps/attr-2.4.47-r1 | `nls -static-libs`
sys-apps/coreutils-8.23 | `acl nls (xattr) -caps -gmp -multicall (-selinux) -static -vanilla`
sys-apps/debianutils-4.4 | `-static`
sys-libs/zlib-1.2.8-r1 | `-minizip -static-libs`
**FROM gentoobb/s6** |
dev-lang/execline-2.1.1.0 | `-static -static-libs`
dev-libs/skalibs-2.3.2.0 | `-doc -ipv6 -static-libs`
sys-apps/s6-2.1.3.0 | `-static`
*manual install*: entr-3.2 | http://entrproject.org/
**FROM gentoobb/glibc** |
sys-apps/gentoo-functions-0.8 | ``
sys-libs/glibc-2.20-r2 | `hardened -debug -gd (-multilib) -nscd -profile (-selinux) -suid -systemtap -vanilla`
sys-libs/timezone-data-2015b | `nls -right`
**FROM gentoobb/busybox** |
sys-apps/busybox-1.23.1-r1 | `make-symlinks static -debug -ipv6 -livecd -math -mdev -pam -savedconfig (-selinux) -sep-usr -syslog -systemd`
#### Purged
- [x] Headers
- [x] Static Libs
