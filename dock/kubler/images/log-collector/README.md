## kubler/log-collector

This image collects logs from all running containers on the host and forwards them to an elasticsearch instance.
[Fluentd][] is configured dynamically by using [docker-gen][].

All credits go to Jason Wilder for his [blog article][jwilder] and @bprodoehl for the [implementation][bprodoehl].

Run this [Fluentd][] image with:

    $ docker run -d -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/containers:/var/lib/docker/containers \
        --link log_elasticsearch:es1 \
        --name log_collector kubler/log-collector

[Last Build][packages]

[Fluentd]: http://www.fluentd.org/
[docker-gen]: https://github.com/jwilder/docker-gen
[jwilder]: http://jasonwilder.com/blog/2014/03/17/docker-log-management-using-fluentd/
[bprodoehl]: https://github.com/bprodoehl/docker-log-collector
[packages]: PACKAGES.md
