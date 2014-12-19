Run this [Ruby][] image with:

    $ docker run -it --rm gentoobb/ruby

Comes with ruby 1.9 and 2.1. RUN eselect ruby set ruby19|ruby21 in your dockerbuild to switch between versions. Default is ruby 2.1.

If you need to compile native ruby extensions use gentoobb/ruby-gcc.

[Ruby]: http://ruby-lang.org/
