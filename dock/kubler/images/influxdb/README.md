## kubler/influxdb

Run this [InfluxDB][] image with:

    $ mkdir /var/lib/influxdb
    $ docker run -d --name influxdb-0 \
       -v /var/lib/influxdb:/var/opt/influxdb \
       -p 8083:8083 -p 8086:8086 -p 8090:8090 -p 8099:8099 kubler/influxdb

Web Interface (obsolete since 1.1.0):

    http://localhost:8083

REST API:

    http://localhost:8086

Default admin credentials:

    root/root

Write stuff via curl:

    $ curl -X POST -d '[{"name":"foo","columns":["val"],"points":[[23]]}]' 'http://localhost:8086/db/somedb/series?u=root&p=root'

[Last Build][packages]

[InfluxDB]: http://github.com/influxdb/influxdb/
[packages]: PACKAGES.md
