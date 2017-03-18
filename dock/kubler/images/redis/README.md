Run this [Redis][] image with:

    $ docker run -d --name redis-0 -p 6379:6379 kubler/redis

To test the server:

    $ docker run -it --rm --link redis-0:redis kubler/redis /usr/bin/redis-cli -h redis ping

[Redis]: http://redis.io/
