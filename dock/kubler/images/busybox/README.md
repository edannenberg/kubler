Run this [BusyBox][] image with:

    $ docker run -i -t --name busybox kubler/busybox

[BusyBox]: http://busybox.net/


Hello Kubler!

* Refactor project for name change gentoo-bb -> kubler
* `kubler.sh` now behaves like a regular CLI app that can be put into PATH
* Add support for external `--working-dir` that only contains namespaces(multi) or images(single)
* If `--working-dir` is not defined try to detect a proper working dir starting from PWD
* If PWD is inside a valid namespace dir the namespace part of image ids can be omitted, i.e. just build busybox
* Manually massage generated Argbash code to be release ready
* 2 subtle regression bugs fixed
* Lots of polish all over the place
* Prepare for monthly stack update, minor fixes and full rebuild

This should be RC quality
