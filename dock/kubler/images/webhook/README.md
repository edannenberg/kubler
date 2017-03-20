## kubler/webhook

Run this [Webhook][] image with:

    $ docker run -d --user nonrootuser --name webhook-0 \
       -v /some/path:/some/path
       -p 9000:9000 kubler/webhook -hooks hooks.json -verbose 

Image comes with git.

[Last Build][packages]

[Webhook]: https://github.com/adnanh/webhook
[packages]: PACKAGES.md
