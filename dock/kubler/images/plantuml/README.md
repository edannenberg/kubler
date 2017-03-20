## kubler/plantuml

Run this [PlantUML][] image with:

    $ docker run -d --name plantuml -p "8080:8080" kubler/plantuml

Webinterface: http://127.0.0.1:8080/

PlantUML currently does not support running with `/` context, the image redirects to `/plantuml` instead.

In conjunction with the [nginx-proxy][] container use:

    $ docker run -d --name plantuml -e VIRTUAL_HOST=plantuml.void -e VIRTUAL_PORT=8080 kubler/plantuml

[Last Build][packages]

[PlantUML]: https://plantuml.com
[nginx-proxy]: ../nginx-proxy
[packages]: PACKAGES.md
