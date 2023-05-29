### Argbash parsers

We use the excellent [Argbash](https://github.com/matejak/argbash) project to handle all argument parsing.

Before changing a parser template in this directory you should:

1. [Install](http://argbash.readthedocs.io/en/latest/install.html) Argbash
2. Familiarize yourself with the [Argbash-Api](http://argbash.readthedocs.io/en/latest/guide.html#argbash-api)

After changing a template it is required to regenerate the code by running:

```
./cmd/argbash/argbash-refresh.sh
```
