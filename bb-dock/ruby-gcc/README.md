Run this [Ruby][] image with:

    $ docker run -it --rm gentoobb/ruby

Comes with ruby 1.9 and 2.0. RUN eselect ruby set 1|2 in your dockerbuild to switch between versions. Default is ruby 2.0.

If you don't need to compile native ruby extensions consider using gentoobb/ruby which saves you about 33% image size.

[Ruby]: http://ruby-lang.org/
