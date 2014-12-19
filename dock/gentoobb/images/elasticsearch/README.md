Run this [Elasticsearch][] image with:

    $ docker run -d --name elasticsearch-0 gentoobb/elasticsearch

Then [link][linking] to it from your client container:

    $ docker run --link elasticsearch-0:elastic your-client

For example, we can use the busybox image and wget to query the elasticsearch container:

    $ docker run --link elasticsearch-0:es -it --rm gentoobb/busybox /bin/sh
    $ wget --quiet -O - "http://es:9200/"
    {
      "status" : 200,
      "name" : "Puff Adder",
      "version" : {
        "number" : "1.0.1",
        "build_hash" : "5c03844e1978e5cc924dab2a423dc63ce881c42b",
        "build_timestamp" : "2014-02-25T15:52:53Z",
        "build_snapshot" : false,
        "lucene_version" : "4.6"
      },
      "tagline" : "You Know, for Search"
    }

[Elasticsearch]: http://www.elasticsearch.org/
[linking]: http://docs.docker.io/en/latest/use/port_redirection/#linking-a-container
