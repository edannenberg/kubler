Run this [cadvisor][] image with:

    $ docker run \
    --volume=/:/rootfs:ro \
    --volume=/var/run:/var/run:rw \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:ro \
    --publish=8080:8080 \
    --detach=true \
    --name=cadvisor \
    kubler/cadvisor:latest

Web interface:

    http://localhost:8080

[cadvisor]: https://github.com/google/cadvisor
