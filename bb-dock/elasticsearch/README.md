Run this [Elasticsearch][] image with:

    $ docker run -d --name elasticsearch-0 gentoobb/elasticsearch

Then [link][linking] to it from your client container:

    $ docker run --link elasticsearch-0:elasticsearch your-client

For example, we can use wget:

    $ docker run --link elasticsearch-0:elasticsearch -i -t gentoobb/bash /bin/bash
    d30608cbc8a1 / # HOST_PORT="${ELASTICSEARCH_PORT#[a-z]*://}"
    d30608cbc8a1 / # HOST="${HOST_PORT%:[0-9]*}"
    d30608cbc8a1 / # PORT="${HOST_PORT#[0-9.]*:}"
    d30608cbc8a1 / # wget --quiet -O - "http://${HOST}:${PORT}/"
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
