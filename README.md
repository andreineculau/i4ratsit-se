# i4ratsit-se [![Build Status][2]][1]

Interface for Ratsit AB's www.ratsit.se

**DISCLAIMER** This is an unofficial experiment serving these purposes:

- provide a CLI
- provide an "API" (HTTP server)
  - enacting proper HTTP usage
  - creating/using some vendor media-types (targeting a future media-type registration)


## Install

`npm install i4ratsit-se`


## Usage

### CLI

```bash
i4ratsit-se anonymous --where Stockholm
```

### NodeJS

```js
i4ratsitSe = require 'i4ratsit-se'

i4ratsitSe.search {who: 'anonymous', where: 'Stockholm'}, (err, res) ->
  throw err  if err?
  if res.headers['Content-Type'] is 'application/vnd.hyperrest.persons-v1+json'
    console.log res.body.items
    consoel.log res.body.links
```

### HTTP API

"TODO"


## Ratsit, [WAT](http://is.gd/watjs)?

* application/json + ISO-8859-1 = ♥. NOT! Ref: https://tools.ietf.org/html/rfc4627
* nested JSON stringification
* PNG filename
* HTML tags


## License

[Apache 2.0](LICENSE)


  [1]: https://travis-ci.org/andreineculau/i4ratsit-se
  [2]: https://travis-ci.org/andreineculau/i4ratsit-se.png
