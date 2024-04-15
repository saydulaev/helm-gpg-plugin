# Helm GPG (GnuPG) Plugin

**NOTE**
> This plugin was inspired by [helm-gpg](https://github.com/technosophos/helm-gpg) project.

Helm uses Go library [crypto/openpgp](https://github.com/golang/go/issues/29082) that does not support a new GnuPG keyring format `.kbx` [see GnuPG 2.1](https://gnupg.org/faq/whats-new-in-2.1.html).

This plugin allows to use the gpg keys as is without converting existing keyring .kbx to old format .gpg.

It offers two operations:

- sign: Sign a chart with a key, key passphrase and your keyring
- verify: Verify a signed chart with your key and keyring


Addition options have been added

`sign`:
- --passphrase or --passphrase-file
- --keyring 

`verify`:
- --keyring

The checksum have been increased to sha512.


## Installation

You must have GnuPG's command line client (`gpg`) installed and configured.

```console
$ helm plugin install https://github.com/saydulaev/helm-gpg-plugin
```


