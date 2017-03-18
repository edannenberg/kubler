Run this [OpenSMTPD][] image with:

    $ docker run -d -v /my.conf:/etc/opensmptd/smptd.conf -p 25:25 --name mail_relay kubler/opensmtpd

Basic install, primarily intended as mail relay for other containers.

[OpenSMTPD]: https://www.opensmtpd.org/
